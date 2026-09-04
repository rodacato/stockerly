# ADR-002 — Trading reads from MarketData via a formalized read API; cross-context writes flow through events

- **Status:** Accepted
- **Date:** 2026-05-15
- **Author:** Adrian Castillo (with synthesis from the documented expert panel — C2 Hiroto, C6 Esther, C1 Lucía)
- **Supersedes:** —
- **Related:** [Issue #33](https://github.com/rodacato/stockerly/issues/33), [Issue #59](https://github.com/rodacato/stockerly/issues/59), [1.0 retrospective](../../1.0-retrospective.md)

---

## Context

The 2026-05 code audit identified a Trading↔MarketData boundary violation centered in `Trading::UseCases::AssembleDashboard`. The use case reads `NewsArticle`, `Asset`, `MarketIndex`, `FearGreedReading` directly as ActiveRecord models, and invokes `MarketData::Domain::MarketSentiment.for_user(user)`. CLAUDE.md's "contexts communicate only via domain events" rule, taken literally, would forbid all of that.

After Sprint 3 closed (2026-05-15), the picture changed:

1. **The inverse leak disappeared.** `MarketData::UseCases::GeneratePortfolioInsight` invoked `Trading::Domain::ConcentrationAnalyzer`. Sprint 3 deleted the entire Phase 22 LLM layer (issue #30), so MarketData no longer reads from Trading anywhere.
2. **The remaining leak is unidirectional.** Trading reads from MarketData (dashboard composition, FX rate lookups). MarketData has no dependency on Trading.
3. **A precedent already exists.** Sprint 2 introduced `MarketData::UseCases::SearchTickers` as the documented way for Administration to read MarketData (`administration/use_cases/assets/search_ticker.rb:30`). The use-case-as-read-API pattern is in the codebase.
4. **The Trading-side FX resolver self-documented the leak.** (It was replaced by `Trading::Domain::ExecutionRate` in 2026-08-29's amendment to ADR-009; the boundary argument below is unchanged.) `fx_rate_resolver.rb:20` reads: *"Cross-context call to MarketData::Gateways::FxRatesGateway is a known leak."* That comment is the symptom: the rule exists, the codebase violates it, and the violator knows it. Either the rule is wrong, or the codebase needs aggressive refactoring.

The literal "events only" reading of CLAUDE.md is the wrong rule. Events model **state changes**; dashboards model **current state**. Forbidding cross-context reads forces every read into either (a) a duplicated read-model fed by events, or (b) a merge of the contexts. Both are heavy. Both also misread the DDD pattern: bounded contexts are about **invariants and language**, not about banning all reads.

The right framing is the DDD **customer/supplier** pattern (sometimes called "supporting subdomain"): Trading is the customer; MarketData is the supplier; the supplier exposes a stable API; the customer depends on that API, not on the supplier's internals.

### Additional factors considered

1. **Single-engineer reality.** Adrian is one developer in a 6-BC monolith. The ceremony cost of "every cross-context read needs a new use case wrapped around a 3-line ActiveRecord query" must be proportional to the team size and the actual coupling risk. Hiroto's pragmatism rule applies: *the domain defines the architecture, not the other way around.*
2. **The dashboard is a read-side composition.** It mixes user state (positions, portfolio summary) with external state (news, indices, market sentiment, fear & greed). That mix is the whole point of the dashboard; eliminating it would mean not having a dashboard.
3. **Read APIs are easier to evolve than read models.** A use case `MarketData::UseCases::RecentNews` can be swapped (e.g., add caching, change source) without touching Trading. A materialized view (option C) would require coordinated migrations.
4. **Performance is not currently a constraint.** Adrian's portfolio is ~5-15 positions; the dashboard renders in <200ms with the current `portfolio.convert` cache (Sprint 3 retro). A read model is premature optimization.
5. **The audit also flagged Administration as a non-BC** and Notifications as a library. Those are separate ADRs (ADR-004, ADR-007).[^phantom] This ADR is **scoped strictly to Trading↔MarketData**.

[^phantom]: **ADR-004 and ADR-005 were never written, and ADR-007 became something else.** See the [amendment of 2026-08-27](#amendment-2026-08-27--the-adr-numbers-this-document-reserved) at the end of this file. The three citations in this document — here, and at "waits for ADR-005", and at "Pending ADR-007" — point at nothing.

---

## Decision

**Trading may read from MarketData via a formalized read API (use cases and query objects exposed by MarketData). MarketData may not read from Trading. Cross-context writes — in either direction — flow exclusively through domain events.**

This is the DDD **customer/supplier (supporting subdomain)** pattern, applied to a single direction: Trading is the customer; MarketData is the supplier.

### Operational rules

#### ✅ Allowed

- **Trading use cases / handlers / domain services may call** `MarketData::UseCases::*` and `MarketData::Queries::*` (a `Queries::` submodule may be introduced when a read-only ActiveRecord wrapper is more honest than a full use case).
- **Trading may call** `MarketData::Domain::*` services that are **explicitly marked as part of the read API** (a YARD `@api public` tag or a comment block stating "Cross-context read API — Trading may call this"). The current `MarketSentiment.for_user` is grandfathered as read API.
- **MarketData publishes events** that Trading subscribes to (already in place: `MarketData::Events::AssetPriceUpdated`, etc.).
- **Trading publishes events** that MarketData subscribes to **only if needed** — at present, no MarketData handler depends on a Trading event, and that should remain the default.
- **FX access** stays a tolerable shared-model dependency. The FX-storage ADR this clause waited for is [ADR-009](0009-fx-history-strategy.md), and it did not move the models out of the top level — so `FxRate` and `FxRateHistory` remain shared, read directly by `Trading::Domain::ExecutionRate`. See the amendment at the foot of this ADR for why the wrapper that used to sit in front of them is gone.
- **Read-through cache pattern** — Trading may call a MarketData read API whose internal implementation refreshes its own cached AR model from a gateway. This is **not** a cross-context write: Trading reads; MarketData internally decides whether to refresh its own data before responding. The "events only for writes" rule applies to writes whose **intent crosses the boundary** (BC A asking BC B to mutate B's state for A's benefit), not to internal cache refreshes that happen as a side-effect of a read. The pattern stands; **FX is no longer an instance of it** (see the amendment).

#### ❌ Forbidden

- **Trading reading MarketData ActiveRecord models directly** (`NewsArticle.recent`, `MarketIndex.major`, `FearGreedReading.latest_*`, `Asset.where(...)` for read-side aggregation in Trading). These must route through a MarketData use case or query object.
- **MarketData reading Trading ActiveRecord models or domain services.** No `Portfolio.find`, no `Trading::Domain::*` call from `app/contexts/market_data/`.
- **MarketData reading Trading via events that carry user-specific Trading state.** Events are facts ("AssetPriceUpdated"), not state pulls.
- **Bypassing the read API by reaching into `MarketData::Gateways`** from Trading use cases. Gateways are an internal of MarketData; their stability is not guaranteed.

#### ⚠️ Gray zone (case-by-case review)

- **Trading reading top-level AR models that are conceptually MarketData's** (e.g., the current `Asset` access in `AssembleDashboard` for `trending`). At present `Asset` is autoloaded at the top level, not under `MarketData::`. Treat top-level models as the **shared kernel** — they're allowed reads but each new such case should be questioned. The right fix may be a future move of `Asset` into `MarketData::Models::Asset` (out of scope for this ADR).
- **Jobs in `app/jobs/`** call `MarketData::Gateways::*` and `MarketData::UseCases::*` directly. Jobs are top-level orchestration glue, not part of a BC; this access is OK and not subject to ADR-002.
- **`Identity::UseCases::GlobalSearch` reads `NewsArticle`.** Identity → MarketData leak. Out of ADR-002 scope; should be cleaned up under a future ADR or as part of #33's implementation if convenient.

### Rule when in doubt

> *Trading reads MarketData; MarketData does not read Trading. Both reads use the supplier's public API (use cases / queries / explicitly marked domain services), never AR models or gateways.*

---

## Consequences

### Positive

- **The leak becomes a sanctioned dependency.** The "known leak" self-documenting comments disappear; the dependency is now intentional and documented.
- **Read API stabilizes the MarketData boundary.** When MarketData evolves (e.g., adds caching, replaces a gateway, reshapes a model), Trading sees a stable interface.
- **No new BC, no merge.** Lowest ceremony option that preserves DDD intent.
- **Closes #33 path.** The implementation of #33 becomes mechanical: extract `MarketData::UseCases::RecentNews`, `TrendingAssets`, `MajorIndices`, `CurrentFearGreed` (or `Queries::`-namespaced equivalents); refactor `AssembleDashboard` to call them.
- **Compatible with the existing precedent** (`MarketData::UseCases::SearchTickers`).

### Negative

- **CLAUDE.md needs an amendment.** The "contexts communicate only via domain events" line is too absolute; it must be qualified.
- **Discipline cost.** New code in Trading that wants MarketData data must check whether a read API exists, and create one if not. This is a small but persistent overhead.
- **The "supplier API" surface grows over time.** As more Trading use cases need MarketData reads, more use cases / queries get exposed. Without curation, this surface bloats. Mitigation: every new MarketData read API requires an entry in a MarketData public-API index (deferred — open as separate issue if/when the count grows past 8-10).

### Mitigations

- **Periodic boundary audit.** The `audit-entropy.sh` script can be extended to count direct AR model reads from Trading into MarketData. Establish a baseline at #33 close and watch for regressions.
- **Reviewer checklist.** PR review for Trading should ask: *"is this reading MarketData? if so, is it going through a use case or query, not an AR model?"*
- **The shared kernel (top-level `Asset`, `FxRate`, etc.) is explicitly out of scope.** A future ADR (TBD) can decide whether to migrate those into MarketData properly.

---

## Implementation

### Required for #33 (S05)

1. **Extract read-side use cases or queries in MarketData** (decide per case; queries when 1-line AR wrappers, use cases when there's logic):
   - `MarketData::Queries::RecentNews` — wraps `NewsArticle.recent`
   - `MarketData::Queries::TrendingAssets(limit:)` — wraps the `Asset.where(...).order(...).limit(...)` block in `AssembleDashboard:16-21`
   - `MarketData::Queries::MajorIndices` — wraps `MarketIndex.major.includes(:market_index_histories)`
   - `MarketData::Queries::CurrentFearGreed` — wraps the 4-key hash currently built in `AssembleDashboard:27-32`
2. **Refactor `Trading::UseCases::AssembleDashboard`** to call those queries. `MarketSentiment.for_user(user)` stays as-is (grandfathered as read API; add YARD comment marking it).
3. ⚠️ **Undone 2026-08-29 — see the amendment at the foot of this ADR.** Both classes named in this step are deleted; FX is read from the dated series and refreshed on a schedule instead. Kept as the record of what was decided in 2026-06. **Wrap the gateway call in the Trading-side resolver** using a new `MarketData::UseCases::EnsureFreshFxRate` (read-through cache pattern: reads the current `FxRate`, refreshes from the gateway only when stale, returns the rate). The internal write to the `FxRate` AR model is a cache update within MarketData's own ownership — **not** a cross-context write from Trading. Trading sees a read API; MarketData decides when to refresh internally. Remove the "known leak" self-documenting comment in `fx_rate_resolver.rb:20`. (This pattern is also the answer to "doesn't this violate the events-only-for-writes rule?": no, because Trading is not commanding MarketData to mutate state — it's asking MarketData for a fresh value, and MarketData internally decides how to provide it.)
4. **Remove direct `MarketData::*` references** from `app/contexts/trading/` outside of the new read API. Verify with `grep -rn "MarketData::" app/contexts/trading/`.
5. **Update CLAUDE.md** "Cross-Context Communication" section to reflect this ADR's nuance.

### Deferred (separate issues if useful)

- `Identity::UseCases::GlobalSearch` reads `NewsArticle` directly — same pattern as above; out of #33 scope.
- `Administration::UseCases::Assets::*` publishes `MarketData::Events::Asset*` — different problem (foreign-event publishing), waits for ADR-005.[^phantom]
- Top-level `Asset` and `FxRate` models — future ADR on shared kernel layout.
- Splitting `MarketData::Domain::MarketSentiment` into `Domain::*` (internal) vs `ReadApi::*` (public surface) — premature; do when the public surface grows past 5 entries.

### Pattern reference for future BC boundaries

This ADR codifies the customer/supplier pattern for **Trading → MarketData** specifically. Other BC pairs may need similar ADRs:

- **Alerts → Trading?** Alerts already reads Trading state via events (price updates trigger evaluation). May need a read API for current portfolio state when alert rules reference position-level facts (future).
- **Trading → Identity?** Currently uses associations (`user.portfolio`). The User<->Portfolio relationship is too entangled to ADR-002-ify without bigger surgery.
- **Administration → everything?** Pending ADR-007 — Administration may not be a real BC.[^phantom]

The pattern itself (read via supplier's public API, write via events) is reusable; each adopter pair gets its own ADR if non-trivial.

---

## Notes

- This ADR can be revisited if the read API surface bloats past ~10 entries (signal: maybe a real "Composition" BC is justified) or if performance forces a materialized read model.
- The decision is explicitly **pragmatic, not purist**. A strict DDD reading would object to grandfathering `MarketSentiment.for_user` as read API; a pragmatic reading recognizes that the call already works, doesn't violate any invariant, and rewriting it as a use case adds zero value.
- This ADR closes the architectural question for #33 (which can now move from `blocked` to `ready` for S05).

---

## Amendment, 2026-08-27 — the ADR numbers this document reserved

This ADR cites **ADR-004**, **ADR-005** and **ADR-007** for work it deferred. Verified against the
full repository history on 2026-08-27: **no file numbered 0003, 0004 or 0005 was ever added, on any
branch.** Those two decisions — Administration as a non-BC, and foreign-event publishing — were
never written down anywhere.

Worse than absent: **ADR-007 was later allocated to an unrelated topic**, the I18n deferral
(subsequently superseded by ADR-011). So the sentence *"Pending ADR-007 — Administration may not be
a real BC"* now points at a document about Spanish copy. Nothing was renumbered and nothing was
lost; the number was simply taken by whoever wrote next, because a reservation held in prose is not
a reservation.

**The lesson, recorded in [`../README.md`](../README.md#the-00030005-numbering-gap): cite an ADR
number only once the file exists.** Deferred work is named as deferred work or gets an issue. 0003,
0004 and 0005 are burned — never allocate them to anything, so that this document's citations stay
readable as the mistake they were rather than resolving to a stranger.

The **deferrals themselves are still open and still unwritten** as of 2026-08-27. Administration
remains a context in `app/contexts/`; `Administration::UseCases::Assets::*` still publishes
`MarketData::Events::Asset*`. Neither has been decided — only un-numbered.

One consequence this ADR listed *was* eventually honoured, though it took until 2026-08-27 to land
everywhere: the "CLAUDE.md needs an amendment" item under **Negative**. `CLAUDE.md` and
`conventions.md` were qualified; `docs/architecture/README.md` kept the absolute *"contexts
communicate only via Domain Events"* line for three months after this ADR was accepted.

---

## Amendment, 2026-08-29 — FX stops being the read-through-cache example

`EnsureFreshFxRate`, the supplier-side wrapper this ADR's Implementation section introduced, is
deleted. Nothing called it.

**How it emptied out.** ADR-009 gave FX a dated series, `FxRateHistory`, and the Trading-side
resolver read that series *first*, falling through to `EnsureFreshFxRate` only on a miss. The
[2026-08-29 amendment to ADR-009](0009-fx-history-strategy.md) then removed the fallthrough on
purpose: for a rate that is supposed to be the FIX of a specific day, refreshing a gateway and
answering with *today's* number is not a fallback, it is the bug the dated series exists to prevent.
`FxRateHistory.rate_on` already walks back to the most recent published FIX on or before the date,
which is the honest answer when a day has none. With the fallthrough gone the wrapper had no callers,
and the resolver in front of it was deleted in the same change.

**What this does to the boundary.** Trading reads `FxRateHistory` directly, as it already did through
the resolver. That is the shared-model tolerance in the Decision above, not a new leak — and the two
things this ADR actually forbids are both still true: Trading instantiates no MarketData gateway, and
it writes nothing MarketData owns. Keeping the series fresh is MarketData's own job, in
`RefreshFxRatesJob` and `SyncFxHistoryJob`, which is where a refresh belongs — on a schedule, rather
than as a side effect of somebody asking what a trade was worth.

**The pattern is not retired**, it simply has no live instance right now. A supplier read that
genuinely needs a refresh-on-miss should still be written this way. What FX demonstrated is the
narrower lesson: refresh-on-miss and *historical* accuracy pull in opposite directions, so a read that
must be dated should not have a live-refresh fallback behind it.

The live examples of the read contract are the `MarketData::Queries::*` objects — `CurrentFearGreed`,
`NotableObservations`, `PriceSeries`, `UpcomingDividends` and the rest.

---

## Amendment, 2026-09-04 — the shared kernel gets its decision, and one phantom citation resolves

Two of this ADR's deferrals were written down on 2026-09-04 as
[ADR-024](0024-asset-ownership-by-column.md):

- *"Top-level `Asset` and `FxRate` models — future ADR on shared kernel layout."* `Asset` is
  resolved there by column: Administration owns identity and lifecycle, MarketData owns the
  observed data. `FxRate` / `FxRateHistory` turned out not to need resolving — they have one
  writer, MarketData, and this ADR's §Allowed already tolerates Trading's read.
- *"`Administration::UseCases::Assets::*` publishes `MarketData::Events::Asset*` — waits for
  ADR-005."* ADR-005 is burned and was never going to arrive. ADR-024 answers it in the opposite
  direction from the one the audit assumed: the events are catalogue lifecycle facts, so they moved
  to `Administration::Events::` to join their publisher, rather than the publisher moving to join
  them.

**This ADR's Gray-zone clause is not retired.** ADR-024 governs *writes* only. Reading `Asset` from
any context stays sanctioned exactly as written above; the guess in that clause — *"the right fix
may be a future move of `Asset` into `MarketData::Models::Asset`"* — is the option ADR-024 measured
at ~35–40 files and rejected.
