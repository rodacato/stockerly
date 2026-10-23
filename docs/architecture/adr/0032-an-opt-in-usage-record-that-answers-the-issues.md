# ADR-032 — An opt-in usage record, kept to the questions the issues ask

- **Status:** Accepted
- **Date:** 2026-10-23
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-019](./0019-self-contained-by-default.md), [ADR-020](./0020-internal-error-tracker.md), [ADR-022](./0022-github-as-the-system-of-record.md)

---

## Context

Every issue promoted from the board passes four filters, and the third one is a **usage metric**:
#893, #895, #897 and #899 each name one. Today none of them can be measured, except the assistant's,
which lives in `assistant_messages`. The question that matters most is a chain: a call to action
was offered, and did the action follow? For example, a rule suggestion and then the rule created,
or the `?` popover and then a question asked. No table records the first half.

The owner, 2026-10-23:

> *"sigo interesado en algo in house como teníamos antes pero más acotado como el error tracker,
> detrás de settings e independiente … incluso un toggle de si se quiere usar o no"*

**Two counters already exist, and both are always on.** `AppOpen` (`app/models/app_open.rb`) keeps
one row per day and path, with a count: Hoy's opens, and each `?` as `help:<figure>`. They answer
success criterion 1 and JTBD #8's supporting signal. `MarketData::Discover::VisitLog` keeps the weeks
Descubrir was seen, for D31's kill clause. Both show on `/admin/settings`. Neither holds an event's
detail or any identity, and neither can see a call to action.

**This has been tried.** `user_activity` (#172) recorded page views and three domain events, and
it was deleted in the 2.0 cleanup (`f57d3108`) with the reason *"nothing reads it"*. That table had
no reader and no question to answer. This ADR is about avoiding that, more than about storage.

## Decision

**A small usage record in the instance's own database: off by default, limited to a closed list of
events, read on one screen, and deletable as a unit.**

1. **The switch gates capture, not only the screen.** This inverts ADR-020 §4 on purpose. An error
   is needed after the fact, so its capture is always on. Usage is not: nobody needs what happened
   before they chose to measure it. A self-hoster's behaviour is not recorded until they turn the
   switch on. It is a `SiteConfig` flag, `usage_tracking`, set in Ajustes beside `developer_mode`.
2. **A closed list of events.** Each one is declared once, with its properties and the metric it
   answers (the issue number). An undeclared name or property is not recorded, the way the
   assistant's registry refuses an unlisted read (ADR-031 §2).
3. **Nothing personal.** A row is the event's name, the screen it came from, its declared
   properties and the time. There is no IP, no user agent, no session id, and no free text. The
   assistant's questions stay in `assistant_messages` and are never copied here.
4. **Funnels are declared in code.** A funnel is a pair of events, the call to action and the action
   it leads to, each with the window it allows. The screen shows each funnel per week. This is the
   reader `user_activity` never had.
5. **Recording never raises, and retention is bounded from the first release.** Both are ADR-020
   §3 and §7. A purge in `config/recurring.yml` keeps 90 days.
6. **A call to action carries its origin to the action.** The offer is recorded when it is
   rendered, for example `rule_suggestion.shown`. The link or form that accepts it carries a `via`
   parameter, so the action records where it came from, for example `rule.created via:
   rule_suggestion`. The funnel is these two counts. Nothing is stored on the domain row: an
   `AlertRule` does not learn that it was suggested.
7. **The day counters move into the context and keep their rule.** `AppOpen` and the Descubrir
   visit log become part of `Usage::`, on the same screen. They stay always on: they hold a count
   per day and nothing else, and D31 and success criterion 1 depend on history from before anyone
   turned a switch on. The switch gates the event rows only.
8. **It is contained.** The code is its own context, `Usage::`. Outside the context there is one
   call, `Usage.record(:name, **props)`, at each declared point. A check, like `assistant-isolation`,
   holds this. Deleting the context and the call sites leaves the product whole.
9. **The kill condition is written now.** If the screen has not been opened in the 30 days after
   the switch was turned on, the context is deleted, as `user_activity` was.

## Alternatives

- **Ahoy.** It is a gem, not a service, and it writes to the same Postgres. It was rejected on fit,
  not size. What it adds (visits, browser JS, device and geo data) is exactly what point 3 turns
  off. What is left, a table of named events with properties, is what this ADR writes, without the
  dependency or a vocabulary that is not ours.
- **PostHog, Plausible, Umami.** Each is a separate service. Plausible and Umami see page views and
  cannot see the chain from a call to action to an action. PostHog is far out of proportion for one
  user. All of them fail ADR-019's question of whether the self-hoster has to run something else.
- **Ad-hoc SQL over the tables that already exist.** It works where the action leaves a row (a
  rule, a trade, an assistant message). It cannot see a call to action that was offered and not
  taken, which is half of every funnel.
- **Always on, like the error tracker.** Rejected by point 1 for events. The day counters keep it
  (point 7), because they carry no detail.
- **A third table beside `AppOpen`.** Rejected: two usage records with two rules is the drift this
  ADR is meant to stop.

## Consequences

- An issue's usage metric becomes something a screen shows, when the event it names is declared.
  A metric with no declared event is still unmeasured, and the screen says so instead of reading
  zero.
- A new call to action that should be measured adds one declaration and one `Usage.record` call
  in the same PR.
- With the switch off the cost is one boolean check per declared point, and no rows.
