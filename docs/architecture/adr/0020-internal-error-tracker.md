# ADR-020 — An internal error tracker, because a self-hoster's 500 is lost today

- **Status:** Accepted
- **Date:** 2026-08-28
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-019](./0019-self-contained-by-default.md)

---

## Context

**The trigger, 2026-08-28.** A page returned a 500 and there was no way to find out why without
shelling into the box. Sentry is wired, and the answer was still out of reach in the product.

**What the instance has today.** Three surfaces, none of which answers "why did that request
fail?":

- `SystemLog` + `/admin/logs` — written by eight `Log*` handlers in MarketData and Administration.
  Every row is the outcome of a *scheduled task*: `task_name` and `module_name` are `NOT NULL`,
  `duration_seconds` is the interesting column, and `error_message` is text with no backtrace. An
  unhandled exception in a controller has no task name and no duration. It does not fit, and
  widening the table to make it fit produces two models sharing one set of columns.
- `AuditLog` — user actions, by design.
- Mission Control at `/admin/jobs` — Solid Queue's own view of failed jobs, and nothing about
  requests.

**Sentry** is configured in [`config/initializers/sentry.rb`](../../../config/initializers/sentry.rb):
no DSN means no reporting, and `enabled_environments` is production and staging. That is a
well-behaved optional vendor and it satisfies the letter of ADR-019 clause 2.

**It fails the intent.** ADR-019 gives reviewers one question — *would a self-hoster have to sign up
for something to get this?* For "find out why my instance threw a 500", the answer today is yes.
The capability does not degrade when Sentry is absent; it is absent with it. Clause 2's model is
market data, where a missing key visibly removes one provider among several and the screen says so.
Here the missing key removes the only diagnostic path there is, silently, and the owner discovers
it at the moment they need it.

That is the gap this ADR closes. It is not an argument about vendor count in the abstract — Sentry
costs an operator who wants it nothing, and this ADR does not touch it.

## Decision

**Ship a minimal internal error tracker: unhandled exceptions are persisted in the instance's own
database and readable from an admin screen, with no external service involved.**

The capture point is the framework's, not a bespoke middleware. `ActiveSupport::ExecutionWrapper`
already reports every unhandled exception through `Rails.error` with `handled: false`
(`activesupport-8.1.3.1/lib/active_support/execution_wrapper.rb:93`), and the executor wraps both
requests and jobs — so one `Rails.error.subscribe` covers both.

Seven boundaries, stated so they are not re-litigated per PR:

1. **A new `ErrorEvent` model, not a wider `SystemLog`.** The two answer different questions:
   `SystemLog` is "did the scheduled work run", `ErrorEvent` is "what blew up and where". They may
   share a screen; they do not share a table.
2. **Occurrences are deduplicated by fingerprint** — exception class plus the first application
   line of the backtrace. The same error forty times is one row with a count, not forty rows. A
   list that floods is a list nobody reads.
3. **The subscriber never raises.** It rescues everything and gives up silently. A reporter that
   fails turns one broken request into two, and the second one is unreportable by construction.
4. **Capture is always on; the surface is what the toggle gates.** `developer_mode`, a `SiteConfig`
   flag alongside `maintenance_mode`, controls whether `/admin/errors` opens and whether the hub
   offers its row. It must not gate *capture*: an owner who has to enable recording before an error
   is recorded has to reproduce the failure on purpose, which is exactly today's problem with extra
   steps. Turning the switch on after a failure still shows what already happened.
5. **`developer_mode` never touches `consider_all_requests_local`, and never renders a backtrace
   outside the admin session.** A public error page shows at most a short reference id. A
   database-backed switch that turns on backtraces in HTTP responses is a vulnerability with a
   toggle.
6. **Request parameters are persisted through `Rails.application.config.filter_parameters`**, which
   already covers `passw`, `token`, `secret`, `otp` and `email`. Nothing is stored raw.
7. **Retention is bounded from the first release** — a recurring purge job in `config/recurring.yml`,
   default 30 days. Nobody runs maintenance on their own self-hosted box; an unbounded table is a
   defect shipped on a delay.

**Out of scope, named so the scope stays closed:** performance monitoring, error-rate charts,
email or push alerting per exception, source maps, release tracking, and anything else that
re-implements a hosted tracker. The job is *"I see a 500, I want the class, the line and the
request that caused it"*. Everything past that needs its own trigger.

**Sentry was to be left alone by this ADR — and was retired the same day.** The original text
deferred it: retiring it changes `deploy.yml`, the Actions release step, `.kamal/secrets` and two
gems, and the call belonged with evidence about whether the maintainer ever opens it. Adrian
answered it directly on 2026-08-28, once the replacement existed: *"podríamos quitar la lógica del
error tracker de vendor"*. That is the evidence — the owner is the only reader Sentry had, and he
does not want it. So the removal ships with the tracker rather than behind it:

- `sentry-ruby` and `sentry-rails` leave the `Gemfile`; `config/initializers/sentry.rb` is deleted.
- `ApplicationController#set_sentry_context` goes with them.
- `CheckSyncHealthJob` loses its `Sentry.capture_message` limb and keeps the two channels that
  already reached the owner — the `health` row in Registros and the in-app notification. Its specs
  now assert against those rows instead of against a mock, which makes them test the alert rather
  than the reporting call.
- `SENTRY_*` leaves `config/deploy.yml`, `.kamal/secrets`, the deploy workflow (including the
  release step), `.env.example` and the runbook — all three of the places a Kamal secret lives, so
  none is left resolving to an empty string.

**There is no double write.** Shipping both would have meant a window where an instance reports
twice and the runbook has to explain which one to read.

## Consequences

- **The capability stops depending on a signup.** After this, ADR-019's reviewer question is
  answered by the product for the diagnostic path.
- **The failure page still shows nothing, deliberately.** The original plan surfaced a reference id
  on the 500 page, which needs an `exceptions_app` and an `ErrorsController` where only static
  `public/500.html` exists. Costed during implementation it came to duplicating 133 lines of
  self-contained HTML and CSS, plus a rendering path that can itself fail and leave a blank page,
  to display a UUID whose only use is disambiguating simultaneous errors — on a list already sorted
  by last seen, for one user. Dropped as unpaid ceremony. The request id **is** captured and
  searchable, so the screen half of the feature exists; what would reopen this is a real occasion
  where the newest entry was ambiguous.
- **A hole that is documented rather than fixed:** if PostgreSQL is unreachable, nothing is
  recorded, because the store is PostgreSQL. `kamal logs` remains the fallback for that class of
  failure and `docs/ops/deploy.md` says so. Pretending otherwise would be worse than the gap.
- **`developer_mode` starts with exactly one consumer.** Adding another is incremental and needs no
  ADR — unless it exposes instance internals outside the admin session, which boundary 5 forbids.
- **One reader, not two.** Retiring Sentry in the same change means the runbook, `.env.example` and
  the deploy workflow describe a single error path. The cost is that a self-hoster who *wants* a
  hosted tracker now adds it back themselves, which is the right default under ADR-019: the vendor
  is opt-in from zero rather than opt-out from wired-in.
- **`SystemLog` keeps its meaning.** The pressure to make it the one log table goes away, which is
  the second-order win: the eight `Log*` handlers stay about scheduled work.
