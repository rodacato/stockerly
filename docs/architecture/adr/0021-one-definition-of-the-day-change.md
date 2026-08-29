# ADR-021 — One definition of the day change, computed from our own closes

- **Status:** Accepted
- **Date:** 2026-08-29
- **Author:** Adrian Castillo
- **Related:** [ADR-016](./0016-canonical-market-data-observations.md), [ADR-002](./0002-trading-marketdata-boundary.md), `design/V2_REMAINING.md` X13, X15

---

## Context

`assets.change_percent_24h` is written by whichever gateway answered the sync, and the four that
write it do not agree on what they are measuring:

| Provider | What it writes there |
|---|---|
| Alpaca | `(close − open) / open` — the session's move |
| CoinGecko | `price_change_percentage_24h` — a rolling 24 hours |
| Finnhub | `dp` — previous close to current |
| DataBursatil | the venue's own `c` field |

One column, named for 24 hours, carrying at least three measures. `DataSourceRegistry`'s fallback
chain makes it worse than a fixed mislabelling: when a provider fails and the next one answers, the
same asset changes measure between one sync and the next, and nothing records that it happened. A
reader comparing two rows on the Radar may be comparing a session move against a rolling window.

Every screen that renders a change rendered this — the Activos rows, the watchlist rows, the asset
detail's price block and the sentence under it — and the Panorama's radar *ordered* its rows by it.

Two shapes were considered.

| | Shape |
|---|---|
| Normalise at the gateway boundary | every gateway converts its own field to one agreed measure |
| **Compute it ourselves** | ignore the providers' field for display; derive the figure from data we already store |

Normalising is the more obvious fix and is not free. Alpaca cannot supply a previous-close
comparison without a second call, so honouring the contract would cost a request per asset per sync
against a rate-limited provider — and the guarantee would still be only as good as the newest
gateway's compliance. A tenth provider added in a year is a tenth chance to reintroduce the defect
silently, and there is no test that can catch it from inside the app: the payloads all look alike.

Computing has a property normalising cannot buy: it does not depend on who answered. The inputs are
`asset_price_histories` rows we already write, and `RecordPriceHistory` updates today's row on every
price update, so today's close *is* the current price. The figure stays live during the session
instead of freezing at the close.

## Decision

**The day change every screen renders is `(current close − previous close) / previous close`,
computed by `MarketData::Domain::DayChange` from two rows of `asset_price_histories`.**

- It is the standard day change in finance, so the number means what a reader expects.
- It is provider-independent by construction: the fallback chain cannot change its meaning.
- **"Previous" is the previous row, never yesterday's date.** Equities do not trade every day and
  crypto does; filtering on `Date.current - 1` would blank every Monday.
- **No previous close is not zero.** An asset with fewer than two daily rows has no day change.
  `DayChange` returns `nil`, and the rows draw an em dash in the neutral colour rather than `+0.0%`,
  which would report a newly tracked asset as flat. The asset detail says `sin dato del día`.
- **The list orders on the figure it shows.** The Radar sorts by `|day change|` and the watchlist
  falls back to it; both read the same computed value the row renders. Ordering a list by one number
  while displaying another is the class of defect X13 belongs to.
- Batch reads go through `MarketData::Queries::PriceSeries.recent_closes`, the one statement the
  sparklines already issue. The day change costs **zero additional queries** on `/assets` and
  `/dashboard` (measured: 21 / 24 before and after, flat from 3 to 10 rows).
- Handler order is load-bearing and now explicit: `RecordPriceHistory` is subscribed before
  `BroadcastPriceUpdate`, so the broadcast redraws a block whose day change already includes the
  update that triggered it.

## What is explicitly not changed

- **The `change_percent_24h` column stays, and the gateways keep writing it.** It is the provider's
  own reading of its own data. Dropping it is a separate decision with its own migration; this ADR
  only stops the screens from treating it as an app-wide promise.
- **`Alerts::Domain::AlertEvaluator`'s `day_change_percent` condition is untouched** — and worth
  stating plainly, because it never read the column at all. It compares the incoming `new_price`
  against `asset.current_price`, which is the move between two consecutive syncs: a fourth measure,
  under a name that claims to be a day. Correcting it changes when a user's alerts fire, so it needs
  its own card rather than riding along with a rendering change.
- **`MarketIndex#change_percent` is still the provider's field.** The divergence sentence on the
  asset detail now quotes the computed asset change against the index's provider-supplied one. That
  is an improvement (the sentence and the price block above it can no longer disagree) and an
  incomplete one; the index side has one provider today, so it has no fallback to drift across.

## Consequences

- An asset in its first day of tracking shows an em dash instead of a number, and is left out of the
  Radar, which reports what moved today. Unknown is not activity. It enters once it has two closes.
- The figure is only as good as `asset_price_histories`. A gap in the history moves the comparison to
  the last row we hold rather than inventing one — visible as an unusually large day change after an
  outage, which is honest and legible, where the provider's field would have hidden it.
- Two definitions of "the day" remain on the Panorama: a row's asset day change and the strip's
  portfolio `day_gain`, which is measured against the previous snapshot. They answer different
  questions at different scopes; X13's first draft proposed reconciling them and was rewritten
  because relabelling would have fixed nothing.
