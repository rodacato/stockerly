# Bitácora 2.0

> Running highlights for a future blog post — raw material, not the post itself. Written in English
> (repo convention) with Adrian's verbatim intentions kept in Spanish. Tell me to switch the whole
> thing to Spanish if you'd rather draft the post directly here.

## The thesis (the blog-post angle)

> *"Un blogpost sobre el slop de AI: cómo a pesar de no llegar a donde quería, una buena arquitectura
> me ayudó a hacer el pivot a un nuevo lugar."*

Stockerly was built over many evening/weekend sessions with heavy AI assistance. A lot of it was
**AI slop** — features and engineering theater built for personas that didn't exist, a closed beta
that failed on UX. The original destination (a multi-audience fintech platform) was never reached.

But the part that *wasn't* slop — the architectural discipline (hexagonal + DDD + event-driven,
clean bounded contexts, a real test suite) — is exactly what made the pivot **cheap**. When the
audience collapsed to a single self-hosted user, a 5-stage code audit + a 7-expert panel reached one
verdict: **EVOLVE, not rewrite.** The boundaries had isolated the damage. The pivot is a cleanup,
not a rebuild. That's the story: *good architecture is what lets you be wrong cheaply.*

## Highlights log

### 2026-08-22 — The gate: rewrite vs evolve

- Pivoted to a **self-hosted single-user tracker** (ADR-0010) after the closed beta failed on UX
  (empty first-run, unreadable indicators, data-entry chore).
- The seductive question resurfaced: *"¿empezamos de cero?"* — diagnosed (again) as emotional escape.
- Ran a **5-stage parallel code audit** against the target architecture. Verdict: **5/5 EVOLVE.** The
  abstractions the target wants (registries, event bus, projections, clean read boundary) already
  exist — *under-wired, not absent.* The multi-user surface is peripheral (every FK outbound →
  FK-clean delete). This is the hexagonal boundaries paying rent.
- **Slop moment worth the post:** we *believed* the multi-currency P0 bug was still open (it's cited
  as "the foundation fix" across memory, vision, and an ADR). It was **already fixed and tested**
  months ago. The context had rotted; the docs lied. The audit caught it. Lesson: AI-maintained
  context drifts, and the code is the only source of truth.
- Ran a **7-expert panel** as independent agents (not ventriloquized) — told explicitly not to
  rubber-stamp. Unanimous EVOLVE, but each pushed back: `dhh` (don't build a plugin framework you
  don't need), `mancuso` (verify the test suite is a real safety net first), `vernon` (cure the
  anemia, don't move it), `kleppmann` (harden serialization before trusting a log), `esther`/
  `el-usuario` (ship a screen, don't gold-plate the backend).
- Decision: **EVOLVE.** Started the cleanup phase — branch `evolve_2_0_pre`, tag `pre-2.0-evolve`
  marking the baseline.
- **Green baseline: 2762 examples, 0 failures, 94% line coverage.** The safety net is real —
  which is what makes deleting half the app a low-risk cleanup instead of a gamble.
- Cleanup began with the two most isolated pieces of beta scar tissue: `email_event` (Resend
  delivery tracking) and `user_activity` (usage-audit telemetry, #172). Both were **write-only** —
  built to answer "did the beta amigos use it?", read by nothing in the product. ~57 specs deleted
  with them; the suite stayed green at every step. The blog-post beat: *the AI-built features that
  measured a fantasy audience were the first things to go, and the architecture let them go cleanly.*
- **Deleted the whole multi-user registration surface** — invite codes, `/register`, the admin
  invites UI, and ~1,500 lines — in one commit. The setup that made it safe: the single-user
  bootstrap (`CreateFirstAdmin` → `FirstAdminCreated`) already existed and already created the
  portfolio, so "removing registration" was mostly re-pointing two event handlers, not a rewrite.
  The event-driven boundaries did the heavy lifting — deleting a whole user-journey was a
  subtraction, not surgery. One honest scar: a stale admin-sidebar link to the deleted invites route
  500'd every admin page until caught — the kind of dangling reference a monolith surfaces loudly
  (87 red specs) and a test suite catches instantly. *Blog beat: the architecture makes deletion
  cheap; the tests make it safe.*
- **The entire multi-user surface is gone** — six deletions in sequence (email tracking, usage
  telemetry, registration + invites, email verification, "remember me" + sessions, user
  management), each its own commit, the suite green at every step (2762 → 2503 examples). Roughly
  half the "app" was scaffolding for an audience that never existed. What's left is a single-user
  tracker that boots, logs in, and runs — smaller, and honestly the shape it should have been.
  *Blog beat: the hardest part of the pivot wasn't writing new code; it was having the discipline
  to delete, and an architecture clean enough that deleting didn't hurt.*
- **A real bug surfaced by the cleanup, not the features:** two notification paths (earnings,
  bond maturities) used a direct `Notification.create!` that bypassed the broadcast event — so
  those reminders only appeared on page reload, never live. Routed them through the same funnel
  the alert path already used, with a regression test that fails if anyone reverts it. *Blog beat:
  the tests you write during a cleanup catch bugs the original tests never could.*
- **Asked "what else is dead?" and let an agent sweep the whole codebase** instead of guessing.
  It found dead use-cases, orphaned helpers/partials, two events published to zero subscribers,
  four unused gems, and a set of write-only DB columns — a clean map of residue. Deleting the
  obviously-dead first (zero-reference, no migration) keeps each step green and low-risk; the
  entangled stuff (a working key-pool subsystem, dead columns needing a migration) is named and
  deferred, not force-fit into a tired session. *Blog beat: "delete everything unused" is a
  search problem, not a memory problem — measure the residue, don't recall it.*
- **Dogfooded the fresh-clone experience:** reset the dev DB to empty and walked the single-user
  first-boot — no seed, straight into the setup wizard, account created, platform bootstrapped,
  empty portfolio. The thing a stranger cloning the repo would actually see. First real UX polish
  from that: the provider-connect step now says *what each data source is for* and *where to get
  its key* — the "runs it without a manual" packaging promise, made concrete.
- **The dead-code sweep was right about most things and dangerously wrong about two.** It flagged
  four "unused" gems; verifying each before deleting caught that `thruster` is the production
  Docker `CMD` and `faraday-retry` powers the retry middleware in ~11 gateways — removing either
  would have broken the deploy or all data sourcing. Only `money-rails` and `image_processing`
  were actually dead. *Blog beat: an AI audit is a lead, not a verdict — the cost of trusting it
  blind is a broken prod; the cost of verifying is five minutes. The verification is the work.*
- **Cut over production to the 2.0 — live, and it worked.** Merged to master, deployed to
  andys-room, and instead of wiping the whole DB we did the smarter thing (Adrian's call): delete
  only the user-dependent rows (`User.destroy_all` + the two audit tables with dangling FKs) and
  **keep every non-user table** — the accumulated price history, symbols, fundamentals, news, and
  the configured integrations + API keys. The fresh single-user instance booted straight into
  `/setup` with months of market history already there. *Blog beat: the cleanest reset isn't
  `DROP DATABASE` — it's knowing exactly which rows are yours to throw away and which are the
  expensive history worth keeping. The pivot deleted an audience, not the data.*
- **First honest reaction from prod:** it works, but the assets / sync / how-it's-shown feels
  confusing — the same "can't read the indicators" failure the beta had, still unsolved because
  this phase was cleanup, not redesign. That's the whole point of the next phase.
