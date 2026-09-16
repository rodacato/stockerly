# Rewrite or evolve — the code audit behind the 2.0 (2026-08)

> **Snapshot as of 2026-08-22; annotated 2026-09-16.** This is the evidence that closed the
> rewrite-versus-evolve question in favour of evolving in place, recorded as the 2026-08-22
> addendum to [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md).
> The body is the audit as it was run; the figures in it (gateway counts, spec counts) are as of
> that day. What happened to each finding since:
>
> | Finding | Outcome |
> |---|---|
> | Multi-user surface is FK-clean to delete | **Done** — ADR-0010's 2026-08-27 addendum |
> | `api_key_pool` is rework, not delete | **Done** — [ADR-015](../architecture/adr/0015-one-api-key-per-provider.md): one key per provider, `ApiKeyResolver` |
> | Sync jobs hardcode gateway routing | **Done** — `SyncSingleAssetJob#gateway_for` asks `GatewayChain.for_capability` (#319) |
> | Alerts read MarketData's models directly | **Declared** — ADR-002's 2026-09-04 amendment and [ADR-025](../architecture/adr/0025-alerts-reads-trading.md) |
> | FX captured at resolution, not at the trade's date | **Done** — `ExecuteTrade` passes `executed_at` to `ExecutionRate.capture` |
> | Earnings and maturities bypass the notification broadcast | **Done** — no `Notification.create!` remains in `app/` |
> | Rule conditions are parallel `case` switches | **Still open** — `case rule.condition` in four files under `app/contexts/alerts/` |
> | Append-only events table | **Not built, on purpose** — the panel's live fork below leaned `dhh`, and nothing has needed event-level history since |
> | `AssetPriceUpdated` carries no currency | **Still open** |
> | Net-new evaluators (TWR, concentration, goals, budget) | TWR **shipped** in Consolidado; the rest have no discovery card |
>
> Not re-verified: whether the suite pins behaviour rather than implementation (`mancuso`'s
> pre-step below). Nobody ran the characterization pass it asked for.

Method: five parallel audits of the codebase against the target architecture — sources, evaluators,
alerts and notifications, event infrastructure, identity and administration — read-only and cited by
`file:line`. Each was asked the same question: how far from the target, what salvages, what fights
it, how hard is migration, and does it argue for a rewrite or for evolving.

The target was a pipeline where sources of truth (ingestion) are decoupled from evaluators
(indicators, signals) and from alerts and notifications, each pluggable. The test for a rewrite was
a **named, concrete coupling** that is cheaper to escape by rewriting than to refactor away.

## Verdict: EVOLVE — 5 of 5 stages agree

No stage argues for a rewrite. The recurring finding: **the target architecture's abstractions
already exist — they are under-wired, not absent.** The registries, the event bus, the projection
habit, the clean read-API boundary and a currency-correct money engine are in the repo and tested
(~2,725 specs). Migration is a scoped refactor plus an aggressive delete, not a redesign. A rewrite
would discard working, tested code to re-derive the same shape.

## One line per stage

| Stage | Verdict | Difficulty | The gap (what is actually missing) |
|---|---|---|---|
| **Sources** (Market Data) | Evolve | Med | 11 working gateways + registry + circuit breaker exist, but sync jobs **hardcode** gateway routing (`SyncSingleAssetJob#gateway_for`), bypassing the registry. |
| **Evaluators** (Trading) | Evolve | Low–Med | The currency P0 is **fixed and tested**; RSI/SMA/Bollinger + OHLC series exist. Missing: net-new evaluators (TWR, concentration, goals/budget/comparatives) and signal emission. |
| **Alerts / Notifications** | Evolve | Low–Med | The signal → evaluate → trigger → notify → broadcast pipeline **is** the target shape. Rules are three parallel `case` switches that want a rule-type registry. |
| **Event infra / persistence** | Evolve | Low–Med | EventBus + ~70 subscriptions + projections exist; the stack already **is** Postgres + Solid Queue. Only missing: an append-only events table and a persist step in `publish`. |
| **Identity / Administration** | Evolve | Low–Med | The multi-user surface is peripheral (all FKs outbound → FK-clean delete). A single-user bootstrap already exists (`setup_controller`). |

## The cross-cutting story

1. **Registries exist but are bypassed.** Open/closed is violated not by missing abstractions but by
   hardcoded `case` statements next to the registry that should route: `SyncSingleAssetJob` (and the
   bulk, retry and backfill jobs) for sources; the two alert evaluators and a message builder for
   rules. The fix is "make the registry the only path", not "invent a plugin framework".
2. **Events are ephemeral.** `EventBus.publish` dispatches in memory and persists nothing; the
   "N rows synced" events are notifications, not facts. The one additive change the target
   persistence would need is an append-only events table with a persist-then-dispatch step. The
   projection habit — handlers writing read models — already exists.
3. **The money engine is done and correct.** FX-at-execution capture, FX-weighted cost basis, honest
   gain (market today − cost at historical FX), currency-coherent snapshots, fail-loud on a missing
   rate — all tested in `multi_currency_audit_spec.rb`.
4. **Multi-user is peripheral.** Every doomed FK is outbound; nothing points *into* the multi-user
   tables. Detaching them across contexts is ~15 line-deletes in one initializer — the payoff of the
   hexagonal boundaries the no-rewrite decision bet on.

## Corrections to the project's own record

The audit found three places where what the project believed about itself was wrong.

| What was believed | Reality (evidence) | Action |
|---|---|---|
| The currency P0 is **open** — `execute_trade.rb` hardcodes `"USD"` (vision docs, ADR-0009, the maintainer's notes) | **Fixed.** `execute_trade.rb:14` reads `attrs[:currency] \|\| asset.currency`; FX capture, its migrations and `multi_currency_audit_spec.rb` exist | Update vision and ADR-0009. Residual: FX at *resolution* time rather than at the trade's date — a refinement, not a foundation bug |
| `api_key_pool` is a **multi-user model to delete** | **Miscategorized.** It is MarketData plumbing — `KeyRotation.next_key_for` feeds **7 gateways**, Banxico among them. Deleting it as-is takes all external sourcing dark | Reclassify as **rework**: collapse the pool to one key per provider |
| `CLAUDE.md`: `FearGreedUpdated → EvaluateSentimentAlerts` | The handler **does not exist** and is not subscribed | Remove the claim, or build it as a rule type |
| ADR-002: only Trading reads MarketData, and cleanly | Trading **is** clean, but the Alerts evaluators read MarketData models directly; `Identity::GlobalSearch` reads `NewsArticle`; `Notifications::ListRecent` reads `EarningsEvent` | Route through `MarketData::Queries::*`; two of the three die with the multi-user delete |

## What EVOLVE entails — the work list

- **A · Wire the pluggability that is ~80% there** (Med): make `DataSourceRegistry.for_capability`
  the only gateway-resolution path; collapse the three parallel `case rule.condition` switches into
  a rule-type registry, one file per rule type.
- **B · Add event durability** (Low–Med): an append-only events table; `publish` persists, then
  dispatches; a round-trippable serializer in place of the shallow `serialize`.
- **C · Delete the multi-user surface** (Low, plus one Med surgery): drop `invite_code`,
  `email_event`, `user_activity`, register / verify / invites / user admin; excise `RememberToken`
  from `ApplicationController` and the profile UI (~40 LOC); repurpose `setup_controller` /
  `CreateFirstAdmin` as the single-user bootstrap.
- **D · Rework, not delete** (Med): `api_key_pool` → one key per provider; rewrite `KeyRotation` and
  its 7 gateway call sites.
- **E · Net-new evaluators — the actual product work** (additive): flow-adjusted TWR,
  concentration, goals / budget / comparatives, indicator subscriptions, signals from portfolio math.
  Where the effort *should* go once A–D land, and each behind its own 4-filter card.
- **F · Cheap fixes in flight**: two `Notification.create!` calls that bypass the broadcast
  (earnings and maturities never arrive live); dead `AlertPreference` flags; `AssetPriceUpdated`
  without a currency; FX defaulting to resolution time instead of the trade's date.

## Panel consultation

The panel ([`experts.md`](../vision/experts.md)) was given the single-user direction and this audit.

- **`dhh`:** The rewrite instinct was escape. It is already Postgres + Solid Queue + a working event
  bus with 2,725 tests; you do not rewrite a correct money engine to add one table. *Suggestion:*
  wire the registry that exists — do not invent a framework.
- **`mancuso`:** A strangler fig, not a rewrite; the blast radius is line-deletes plus one bounded
  auth-core surgery. *Suggestion:* sequence it behind the tests — events table behind the existing
  bus with no behaviour change, then the FK-clean delete, then the registries, then new evaluators.
- **`fowler`:** Name the patterns — strangler fig for the delete, **branch by abstraction** for
  gateway routing. *Suggestion:* `api_key_pool` is an **expand–contract** (add the single-key path,
  migrate seven gateways, drop the pool), not delete-then-rebuild.
- **`vernon`:** The bounded contexts held, which is *why* the delete is peripheral. The gap: "rule
  condition" and "data source" are enums and switches, not domain concepts. *Suggestion:* model
  `RuleType` and `Source` as real domain objects, so pluggability is a domain fact.
- **`kleppmann`:** Events are ephemeral today. *Suggestion:* before a log becomes a source of truth,
  harden the serialization and decide replay idempotency — persist the log, but do not event-source
  anything on day one. Draw the double-emit failure first.
- **`esther`:** The audit killed the rewrite with evidence; now the risk flips to gold-plating
  evaluators before shipping a screen. *Suggestion:* delete + wire + the first cockpit, and every new
  evaluator gets a 4-filter card.
- **`el-usuario`:** Still no app — this is all backend. Evolve is right *because* it reaches a phone
  screen months sooner. *Suggestion:* spend those months on the one screen and on data entry.

**Synthesis.** Recommended: **EVOLVE**, on 5/5 stages and a unanimous panel. Key risks: evolve
turning into a rewrite by a thousand refactors (guard: `mancuso`'s sequencing, tests green at every
step); gold-plating evaluators instead of shipping the cockpit (guard: the 4-filter); a lossy
serializer corrupting an event log before it is trusted (guard: `kleppmann`'s harden-first).
Fallback: if one module proves worse than the audit suggests, strangler-fig that module alone —
never escalate one bad module into a full rewrite.

### The independent run

The same panel was re-run as independent agents, each told not to rubber-stamp. All seven still
landed on EVOLVE, and the run surfaced what the in-persona synthesis missed:

- **`mancuso` — the net may be fake.** The specs might pin implementation rather than behaviour: a
  test that breaks when a `case` moves into a registry was testing the wrong thing. Pre-step: add
  characterization tests on the two seams before trusting the net.
- **`el-usuario` — the veto.** *"Beautiful plumbing for a house I still can't live in."* Start with
  the screen and painless trade entry, not the events table. `dhh`, `esther` and `mancuso` converged:
  build a seam only as far as the first cockpit block needs.
- **`vernon` — cure the anemia, do not move it.** Promote `RuleType`, `Source`, `Fact` and `Signal`
  to domain objects that own their behaviour, or fixing the `case` only relocates it. A canonical
  import CSV is an anti-corruption layer, not an "intake API".
- **`dhh` ⟷ `kleppmann` — the one live fork.** Both reject event sourcing, CQRS and a dedicated
  engine. `dhh`: persist nothing, snapshots already give history. `kleppmann`: persist, as one atomic
  append-and-project transaction with a round-trip-tested serializer, replay deferred. Lean: `dhh`.
- **Convergence on the seam:** a PORO per rule type or source, wired by Zeitwerk convention —
  `vernon`'s first-class object and `dhh`'s no-framework PORO are the same thing. A dependency
  container was ruled out.
