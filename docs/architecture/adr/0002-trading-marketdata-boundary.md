# ADR-002 — Trading reads from MarketData via a formalized read API; cross-context writes flow through events

- **Status:** Accepted
- **Date:** 2026-05-15
- **Author:** Adrian Castillo (with synthesis from the documented expert panel — C2 Hiroto, C6 Esther, C1 Lucía)
- **Supersedes:** —
- **Related:** [`docs/research/code-audit-2026-05/diagnosis.md`](../../research/code-audit-2026-05/diagnosis.md), [Issue #33](https://github.com/rodacato/stockerly/issues/33), [Issue #59](https://github.com/rodacato/stockerly/issues/59), [Sprint 1 retro](../../sprints/2026-S01-reset/retro.md)

---

## Context

The 2026-05 code audit identified a Trading↔MarketData boundary violation centered in `Trading::UseCases::AssembleDashboard`. The use case reads `NewsArticle`, `Asset`, `MarketIndex`, `FearGreedReading` directly as ActiveRecord models, and invokes `MarketData::Domain::MarketSentiment.for_user(user)`. CLAUDE.md's "contexts communicate only via domain events" rule, taken literally, would forbid all of that.

After Sprint 3 closed (2026-05-15), the picture changed:

1. **The inverse leak disappeared.** `MarketData::UseCases::GeneratePortfolioInsight` invoked `Trading::Domain::ConcentrationAnalyzer`. Sprint 3 deleted the entire Phase 22 LLM layer (issue #30), so MarketData no longer reads from Trading anywhere.
2. **The remaining leak is unidirectional.** Trading reads from MarketData (dashboard composition, FX rate lookups). MarketData has no dependency on Trading.
3. **A precedent already exists.** Sprint 2 introduced `MarketData::UseCases::SearchTickers` as the documented way for Administration to read MarketData (`administration/use_cases/assets/search_ticker.rb:30`). The use-case-as-read-API pattern is in the codebase.
4. **`Trading::Domain::FxRateResolver` self-documents the leak.** `fx_rate_resolver.rb:20` reads: *"Cross-context call to MarketData::Gateways::FxRatesGateway is a known leak."* That comment is the symptom: the rule exists, the codebase violates it, and the violator knows it. Either the rule is wrong, or the codebase needs aggressive refactoring.

The literal "events only" reading of CLAUDE.md is the wrong rule. Events model **state changes**; dashboards model **current state**. Forbidding cross-context reads forces every read into either (a) a duplicated read-model fed by events, or (b) a merge of the contexts. Both are heavy. Both also misread the DDD pattern: bounded contexts are about **invariants and language**, not about banning all reads.

The right framing is the DDD **customer/supplier** pattern (sometimes called "supporting subdomain"): Trading is the customer; MarketData is the supplier; the supplier exposes a stable API; the customer depends on that API, not on the supplier's internals.

### Additional factors considered

1. **Single-engineer reality.** Adrian is one developer in a 6-BC monolith. The ceremony cost of "every cross-context read needs a new use case wrapped around a 3-line ActiveRecord query" must be proportional to the team size and the actual coupling risk. Hiroto's pragmatism rule applies: *the domain defines the architecture, not the other way around.*
2. **The dashboard is a read-side composition.** It mixes user state (positions, portfolio summary) with external state (news, indices, market sentiment, fear & greed). That mix is the whole point of the dashboard; eliminating it would mean not having a dashboard.
3. **Read APIs are easier to evolve than read models.** A use case `MarketData::UseCases::RecentNews` can be swapped (e.g., add caching, change source) without touching Trading. A materialized view (option C) would require coordinated migrations.
4. **Performance is not currently a constraint.** Adrian's portfolio is ~5-15 positions; the dashboard renders in <200ms with the current `portfolio.convert` cache (Sprint 3 retro). A read model is premature optimization.
5. **The audit also flagged Administration as a non-BC** and Notifications as a library. Those are separate ADRs (ADR-004, ADR-007). This ADR is **scoped strictly to Trading↔MarketData**.

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
- **FxRate access** (currently a top-level AR model) stays as a tolerable shared-model dependency until the FX-storage ADR lands. The `FxRateResolver` direct gateway call is wrapped under this ADR (see Implementation).

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
3. **Update `FxRateResolver`** to call a new `MarketData::UseCases::RefreshFxRate` (wraps the gateway invocation). Remove the "known leak" self-documenting comment.
4. **Remove direct `MarketData::*` references** from `app/contexts/trading/` outside of the new read API. Verify with `grep -rn "MarketData::" app/contexts/trading/`.
5. **Update CLAUDE.md** "Cross-Context Communication" section to reflect this ADR's nuance.

### Deferred (separate issues if useful)

- `Identity::UseCases::GlobalSearch` reads `NewsArticle` directly — same pattern as above; out of #33 scope.
- `Administration::UseCases::Assets::*` publishes `MarketData::Events::Asset*` — different problem (foreign-event publishing), waits for ADR-005.
- Top-level `Asset` and `FxRate` models — future ADR on shared kernel layout.
- Splitting `MarketData::Domain::MarketSentiment` into `Domain::*` (internal) vs `ReadApi::*` (public surface) — premature; do when the public surface grows past 5 entries.

### Pattern reference for future BC boundaries

This ADR codifies the customer/supplier pattern for **Trading → MarketData** specifically. Other BC pairs may need similar ADRs:

- **Alerts → Trading?** Alerts already reads Trading state via events (price updates trigger evaluation). May need a read API for current portfolio state when alert rules reference position-level facts (future).
- **Trading → Identity?** Currently uses associations (`user.portfolio`). The User<->Portfolio relationship is too entangled to ADR-002-ify without bigger surgery.
- **Administration → everything?** Pending ADR-007 — Administration may not be a real BC.

The pattern itself (read via supplier's public API, write via events) is reusable; each adopter pair gets its own ADR if non-trivial.

---

## Notes

- This ADR can be revisited if the read API surface bloats past ~10 entries (signal: maybe a real "Composition" BC is justified) or if performance forces a materialized read model.
- The decision is explicitly **pragmatic, not purist**. A strict DDD reading would object to grandfathering `MarketSentiment.for_user` as read API; a pragmatic reading recognizes that the call already works, doesn't violate any invariant, and rewriting it as a use case adds zero value.
- This ADR closes the architectural question for #33 (which can now move from `blocked` to `ready` for S05).
