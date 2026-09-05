# ADR-024 — `Asset` is owned by column: Administration lists it, MarketData measures it

- **Status:** Accepted
- **Date:** 2026-09-04
- **Author:** Adrian Castillo
- **Related:** [ADR-002](./0002-trading-marketdata-boundary.md) (this ADR writes the shared-kernel decision ADR-002 deferred), [ADR-006](./0006-simple-use-case-criterion.md), [Issue #534](https://github.com/rodacato/stockerly/issues/534), `AUDIT-2026-08-30` BND-08, BND-12, BND-13, BND-14

---

## Context

ADR-002 drew the Trading↔MarketData boundary and left one thing explicitly undecided: who owns
the top-level models both contexts touch. Its Gray-zone clause called them "the shared kernel",
allowed the reads, and deferred the question — *"the right fix may be a future move of `Asset` into
`MarketData::Models::Asset` (out of scope for this ADR)"*. That future ADR was never written, so
for fifteen months the codebase has had an undeclared kernel: eight models with no owner and no
rule, of which `Asset` is by far the most touched — **63 files under `app/`**.

The audit re-raised it as one finding. Measured on `master` on 2026-09-04, it is three findings
wearing one label, and the measurement is what decides the shape of this ADR.

### What the writes actually do

Reads of `Asset` are everywhere — Trading 12 sites, Administration 12, MarketData 9, Alerts 3,
Identity 1. **The writes are not.** There are 13 write sites in the whole tree, and they partition
cleanly — not by context, by **column**:

| Writer | Columns written |
|---|---|
| `Administration::UseCases::Assets::*` (7 sites) + `Onboarding::SeedAssets` | `symbol` `name` `asset_type` `currency` `country` `exchange` `sector` `logo_url` `sync_status` `provider_symbols` `former_symbols` |
| `app/jobs/sync_*` (5 sites) + `MarketData::UseCases::StoreFundamentals` | `current_price` `price_updated_at` `volume` `market_cap` `data_source` `last_synced_at` `last_sync_error` `fundamentals_synced_at` |

Two contexts, two disjoint column sets, thirteen write sites, and **exactly one file crossing the
line**: `MarketData::UseCases::SyncCetes` wrote `name`, `asset_type`, `exchange`, `country` and
`sync_status` in the same `update!` as `yield_rate` and `current_price`.

One violator out of thirteen is not a boundary that needs to be built. It is a boundary that
already exists and has never been written down.

### Why not move `Asset` into MarketData

The obvious DDD answer — one aggregate, one owner, move the catalogue use cases into MarketData —
was measured and rejected. It costs **~35–40 files**: 9 files moved between contexts, 7 spec files
moved, 10 call sites renamed across 5 files, and **~16 read sites in Trading, Alerts and Identity
promoted from sanctioned shared-kernel reads to violations**, each needing a `Queries::*` wrapper
or a written carve-out. Those sixteen would be carved out one at a time over months, during which
the ADR describes an intention rather than the code.

It is also the wrong model. Ownership follows the **invariant**, and `Asset`'s invariants are
uniqueness of symbol and validity of type — catalogue rules, already enforced in
`Administration::Domain::AssetCatalog` and `Administration::Contracts::Assets::CreateContract`.
MarketData protects no invariant on this table; it writes three lines of it. The price writes it
would nominally own live in `app/jobs/`, which ADR-002 exempts from context rules entirely.

The measured cost of writing down what the code does instead is **~16 files**.

## Decision

**`Asset` is jointly modelled and separately owned: Administration owns the catalogue, MarketData
owns the market data, and ownership is defined by column, not by table.**

1. **Administration is the sole writer of identity and lifecycle** — `symbol`, `name`,
   `asset_type`, `currency`, `country`, `exchange`, `sector`, `logo_url`, `sync_status`,
   `provider_symbols`, `former_symbols` — and is therefore the publisher of
   `Administration::Events::AssetCreated` and `AssetDeleted`, which move out of
   `MarketData::Events::`.
2. **MarketData, and the sync jobs acting on its behalf, is the sole writer of observed data** —
   `current_price`, `price_updated_at`, `volume`, `market_cap`, `data_source`, `last_synced_at`,
   `last_sync_error`, `fundamentals_synced_at`, `yield_rate`, `face_value`, `maturity_date` — and
   remains the publisher of `AssetPriceUpdated` and `AssetFundamentalsUpdated`. `div_yield`,
   `pe_ratio` and `shares_outstanding` have no live writer — the fundamentals live in
   `asset_fundamentals` — and fall to MarketData if one ever appears.
3. **A context that needs a write on the other side of the seam calls the owning context's use
   case.** It does not write the column, and it does not publish the other context's event. This
   is a narrow, named exception to "cross-context writes flow through events": a sync needs the row
   to *exist* before it can write its own columns, and an event is asynchronous and hands back no
   row. The one instance is `Administration::UseCases::Assets::EnsureListed`, called by `SyncCetes`.
4. **This ADR governs writes only.** Reading `Asset` from any context stays permitted and
   unchanged, exactly as ADR-002 §Gray-zone already has it. Splitting write ownership by column
   does not make reading the row a crossing. If reads ever need governing, that is a later decision
   with its own evidence.

### The other seven models are not the same problem

The audit listed eight models as one undeclared kernel. They are three different things, and
conflating them is what made this look like a large decision:

| Model | Classification | Rule |
|---|---|---|
| `Asset` | **Shared kernel, co-owned** | This ADR. Ownership by column. |
| `DividendPayment` | **Single-owner (Trading)** | ⚠️ **Amended 2026-09-04** — see the amendment at the foot. This ADR called it the kernel's second co-owned entry; the code says Trading owns every column of it. `sync_dividends_job.rb:91` writes it on Trading's behalf, the shape clause 2 already names. |
| `SystemLog` | **Infrastructure** | ~15 writers across MarketData, Administration, `app/shared/` and `app/jobs/`. Not an aggregate and not a kernel — a cross-cutting log, like the Rails logger. Any context may write it. Declared, not resolved. |
| `AuditLog` | **Infrastructure** | 10 writers across Identity, Administration and Trading, every one an event handler doing the same thing. Same as above. Any context may write it. |
| `User` | **Single-owner (Identity)** | Written only by Identity. Read everywhere through associations, which is what made it look shared. No change. |
| `FxRate` / `FxRateHistory` | **Single-owner (MarketData)** | Written by `FxRatesGateway` and `FxRateHistory.record_rate`, plus `Identity::UseCases::CreateFirstAdmin` at first boot (BND-02, a real leak, tracked separately). Trading's direct read is tolerated by ADR-002 §Allowed. |
| `Integration` | **Single-owner (Administration)** | Written by Administration, plus the same first-boot leak and `sync_integration_job.rb` flipping connection status — a job acting for Administration, same shape as clause 2 above. |
| `Notification` | **Single-owner (Notifications)** | Already had exactly one writer, `Notifications::UseCases::CreateNotification`, correctly called from three contexts. Its gap was a missing *read* API, not ownership. |

**The kernel is closed at two entries.** `Asset` and `DividendPayment` are the only models resolved
by co-ownership. (⚠️ **Amended 2026-09-04: it closes at one.** `DividendPayment` turned out to have
a single owner — see the amendment at the foot.) "Declare it shared" is not available as an answer
to the next model that looks contested — the alternative to writing a query object is writing a
query object.

## Consequences

### What changes now

- `SyncCetes` writes only the columns it owns and asks `Administration::UseCases::Assets::EnsureListed`
  for the row. Two behaviour changes fall out of that, both improvements: the sync no longer renames
  a listing on every run, and **it no longer re-enables a CETES asset the reader disabled** from
  `/tracked` — `sync_status` was in its `update!`, so disabling one was undone by the next Banxico run.
- `AssetCreated` / `AssetDeleted` become `Administration::Events::*`. 13 files, one of them
  `config/initializers/event_subscriptions.rb`. Nothing is serialized by event class name —
  `ProcessEventJob` carries the *handler* name and the attribute hash — so no in-flight job breaks
  across the rename.
- `MarketData::Queries::MarketCalendar` and `Notifications::Queries::AlreadySent` land with it.
  Neither depended on this decision (they resolve identically under every model that was
  considered); they were held behind it by a blocking claim the measurement did not support.

### What this does not fix, and should be read as a limit

- **Almost all of MarketData's half is enforced in a layer no rule governs.** Every
  `AssetPriceUpdated` publish and every price write lives in `app/jobs/`, which ADR-002 §Gray-zone
  explicitly exempts from context rules. Clause 2 says the jobs act on MarketData's behalf, which
  makes the column list meaningful, but it is a convention with no boundary behind it: nothing stops
  a job writing `name` tomorrow.
- **Nothing mechanically enforces a column.** `bin/checks boundaries` — which replaced
  `audit-entropy.sh` on 2026-09-04 — matches constant names: it sees a foreign
  constant, never a foreign column. A regression here is caught by review or not at all. That is the
  honest price of choosing the ~16-file answer over the ~35–40-file one, and it is the trade this
  ADR makes deliberately: a rule that is true today and unenforced beats a rule that is enforced and
  aspirational for three months.
- **`DividendPayment` is named, not moved.** BND-08 stays open. (⚠️ **Closed 2026-09-04** by the
  amendment at the foot: nothing moved because nothing had to.)
- **BND-13's other half stays open.** Alerts reading `Asset` and `MarketHoliday` is an
  Alerts→MarketData dependency with no ADR of its own. The `MarketHoliday` read now goes through a
  query object; the *pair* still needs its own one-paragraph ADR, which no ownership model here
  supplies. (⚠️ **Closed 2026-09-04** by the
  [amendment to ADR-002](./0002-trading-marketdata-boundary.md#amendment-2026-09-04--the-two-alerts-pairs-measured-and-declared):
  the pair is declared, and Alerts→Trading turned out not to exist.)
- **A pre-existing symbol divergence surfaced and was left alone.** `AssetCatalog` seeds `CETE28D`;
  `SyncCetes` creates `CETES_28D`. Both are live and a fresh instance gets both rows. Unifying them
  is a data change on symbols that positions and trades reference, so it is its own issue, not a
  side effect of a boundary ADR.

---

## Amendment, 2026-09-04 — `DividendPayment` has one owner, and the kernel closes at one

The Decision above made `DividendPayment` the kernel's second co-owned entry and deferred the move
to BND-08 ([#560](https://github.com/rodacato/stockerly/issues/560)). Re-measured on `master`, there
is no move to make: the code answers the ownership question in four places and every one of them
says Trading.

| Evidence | What it says |
|---|---|
| `app/models/dividend_payment.rb:2` | `belongs_to :portfolio` — the row hangs off a Trading aggregate |
| `app/models/portfolio.rb:7` | `has_many :dividend_payments, dependent: :destroy` — Portfolio's lifecycle destroys it |
| `app/contexts/trading/use_cases/reset_portfolio_data.rb:11` | `TABLES` wipes it on a re-import, beside trades, positions and snapshots |
| `app/contexts/trading/use_cases/assemble_historial.rb:22` | the only reader in the tree, and it is Trading's own screen |

**The row is not the dividend.** `Dividend` — the announcement, its dates and its amount per share —
is MarketData's fact and stays MarketData's. `DividendPayment` is *"my portfolio held N shares on
that ex-date and received this much"*: `shares_held` and `total_amount`, both derived from a
position. No file under `app/contexts/market_data/` reads or writes one.

**What made it look ownerless is where its writer sits.** `app/jobs/sync_dividends_job.rb:91` is the
only writer, and it runs inside a market-data sync. That is clause 2's shape seen from the other
side: a job writes for a context, and the owner is the context whose columns it writes, not the
job's neighbourhood. The same sentence is what lets the `sync_*` jobs write MarketData's price
columns on `Asset`. Ownership is a claim about columns; the file that happens to execute the
`INSERT` is not the claim.

Consequently **no code moves.** `script/checks/boundaries.rb` moves it out of `SHARED` and into
`OWNERS["trading"]`, which is the only place the claim can be checked at all — and which now fails
a PR that reads `DividendPayment` from `app/contexts/market_data/`.

**The kernel closes at one.** `Asset` is the single co-owned model, and its reasoning is the bar the
next candidate has to clear: a model is co-owned only when two contexts each protect an invariant
over disjoint columns of it. `DividendPayment` never met that bar — one context protects all of them.
