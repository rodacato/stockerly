# ADR-016 — Canonical market-data observations, with multi-source kept reachable

- **Status:** Accepted
- **Date:** 2026-08-26
- **Author:** Adrian Castillo
- **Related:** [ADR-002](./0002-trading-marketdata-boundary.md), [ADR-009](./0009-fx-history-strategy.md), [ADR-015](./0015-one-api-key-per-provider.md), [market-data-providers-2026-08.md](../../research/market-data-providers-2026-08.md)

---

## Context

Market data arrives from thirteen gateways and lands in tables that record **what** the value was and
nothing about **where it came from or what kind of reading it is**.

`GatewayChain` already computes the winning provider per fetch — `value[:data_source] =
gateway.class.name` — and the value is **discarded on persist**, because `asset_price_histories` and
`market_index_histories` have no `source` column. Neither has an `interval` either: the unique index
`[asset_id, date]` encodes "one row per day" into the schema. Provenance exists inconsistently
elsewhere — `fx_rate_histories`, `cetes_rate_histories`, `asset_fundamentals`, `fear_greed_readings`
and `financial_statements` all carry a `source` — which is worse than its absence, because it invites
the belief that origin can be audited.

Meanwhile the 2.0 design asks for distinctions the schema cannot express: a **confirmed** daily close
drawn as a solid series beside a **provisional** delayed one drawn dotted, and Descubrir's
**disposable** cache-with-TTL whose stated rule is that *stale data beats an empty screen*.

Two shapes were considered:

| | Shape |
|---|---|
| **Canonical** | one row per `(asset, date, interval)`; `source` records **who won** |
| Multi-source | one row per `(asset, date, interval, source)`; every provider's opinion retained |

Multi-source enables cross-provider comparison and divergence detection, at the cost of a resolution
policy on every read and a table that grows by the number of sources. That is the right trade when
data quality *is* the product. For a single-user tracker whose job is valuing positions, it is not.

## Decision

**Canonical rows with recorded provenance — built so that multi-source remains a migration rather
than a rewrite.**

Four orthogonal dimensions are modelled, on the **existing typed tables** rather than in one generic
`metric/value` table:

| Dimension | Values |
|---|---|
| `interval` | `1d`, `15m`, … |
| `status` | `confirmed` · `provisional` · `disposable` |
| `source` | which provider produced the row |
| `as_of` vs `fetched_at` | the moment described vs when it was retrieved |

`status` is **not** `source`: a Yahoo close and an Alpaca close are both confirmed, and a delayed
quote is provisional whoever served it. Modelling "dotted = provider X" would hardcode a vendor into
the UI, which is the coupling this work exists to remove.

Typed tables are kept deliberately. Collapsing OHLCV into generic rows would lose the
`decimal(15,4)` constraints, the atomicity of a candle — open/high/low/close are one observation,
not four rows that can end up partial — and the safe upsert index, and would turn every chart query
into a pivot. The design proves the point independently: **CETES rows carry days-to-maturity and an
annual rate and have no OHLCV at all.** One generic price table would have to pretend otherwise.
`technical_observations` already shows where a generic JSONB payload *is* right — readings whose
shape genuinely varies.

**Three rules preserve the multi-source option.** They bind the migration that introduces these
columns:

1. **`source` is `NOT NULL` on every row from the first migration.** Rows with a null source cannot
   be interpreted later: there is no way to tell *"this one won"* from *"this was the only one we
   had"*. This is the single rule whose breach turns the future migration into a rewrite.
2. **`as_of` and `fetched_at` are separate columns from the start.** Multi-source needs to know when
   each provider's opinion was captured; with one timestamp, two sources disagreeing is
   indistinguishable from one source being stale.
3. **Reads go through a query object, not scattered `find_by`s.** Multi-source introduces a
   resolution policy. If fifteen call sites assume one row per `(asset, date, interval)`, those
   fifteen sites *are* the migration; if there is one, it is a class.

Plus a rule of conduct: **when a different source overwrites an existing row, it is not silent.**
Even while only the winner is stored, knowing that a replacement occurred is the evidence that tells
us whether multi-source is worth having.

## Consequences

- The future migration is: drop the unique index on `(asset_id, date, interval)`, create it on
  `(asset_id, date, interval, source)`, and give reads a resolution policy. Bounded, if the rules hold.
- **This is not a fact-log.** The open architecture question on persisting an events table leans
  toward deferral; normalized observations with provenance are read models with extra columns, not an
  append-only event store. Conflating the two would defeat this on reasoning that does not apply.
- Provenance stops being inconsistent: the two tables that lack `source` gain it, and the value
  `GatewayChain` already computes stops being thrown away.
- `status` unblocks the design's solid/dotted distinction without committing to build it — the
  column can exist and carry only `confirmed` until a provisional series is actually drawn.
