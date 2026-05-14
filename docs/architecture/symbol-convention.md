# Asset Symbol Convention

> **Rule:** Stockerly stores the data provider's canonical symbol verbatim. No personal conventions, no stripping, no munging.

Decided 2026-05-14 during Sprint 2 (`2026-S02-truth-foundation`). Formalized in #45.

## What we use

| Market / Asset class | Convention | Examples |
|---|---|---|
| US stocks & ETFs (NASDAQ/NYSE) | Plain ticker | `AAPL`, `TSLA`, `SPY`, `VOO` |
| BMV (Mexican stocks/ETFs) | `.MX` suffix (Yahoo Finance / Alpha Vantage convention) | `WALMEX.MX`, `GENIUSSACV.MX`, `IVVPESO.MX` |
| Crypto | Standard ticker (no exchange suffix — crypto is global) | `BTC`, `ETH`, `SOL` |
| Fixed income (CETES) | Synthetic, term-based | `CETE28D`, `CETE91D`, `CETE182D`, `CETE364D` |
| Indices | Provider's symbol | `IPC` (BMV), `VIX` (CBOE), `SPX`, `NDX`, `DJI` |

## Why `.MX` and not plain

The `.MX` suffix is **not a Stockerly invention** — it's the industry-standard disambiguation used by Yahoo Finance, Alpha Vantage, IEX, and Bloomberg whenever multiple exchanges list overlapping tickers. Storing the provider's canonical form means:

- Lookups against the provider don't require translation.
- Side-by-side coexistence with a hypothetical US ticker of the same name (e.g., a future `WALMEX` US ETF) is automatic.
- New data sources accept the same symbol without per-source mapping tables.

## What the convention is **not**

- ❌ A formatting choice (e.g., always uppercase, always trimmed) — that's enforced separately by validation regex in `Administration::Contracts::Assets::CreateContract`.
- ❌ A user-visible label — UI may show "WALMEX (BMV)" or "WALMEX.MX" depending on context; the convention only constrains the **stored** symbol.

## Where the rule applies

- **Admin ticker search** (`Administration::UseCases::Assets::SearchTicker`) — symbol propagated verbatim from the provider response into `Asset.symbol`.
- **Manual admin asset creation** — admin types the canonical symbol; the contract rejects malformed inputs (regex `^[A-Z0-9.\-\/]{1,20}$`).
- **Seeds** (`db/seeds.rb`) — existing entries already comply (`GENIUSSACV.MX`, `IVVPESO.MX`).
- **Trade entry** — references existing assets by symbol; no separate symbol storage.

## Validating

```bash
grep -rn 'symbol:' db/seeds.rb              # all current seeds
grep -rn 'Asset.find_or_create_by!' db/     # any creators outside the admin flow
```

## When to revisit

- If a new data provider uses a different suffix (e.g., `MX:` prefix, `:MEX`), document the mapping rather than munging at write time.
- If we ever need to display multiple symbols for the same instrument across providers, introduce a separate `Asset::Identifier` table — do not break this rule on `Asset.symbol`.
