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
- ~~New data sources accept the same symbol without per-source mapping tables.~~ **No longer true — see below.**

## Per-source mapping now exists — the rule survives it

**Amended 2026-08-27.** The third bullet above claimed no per-source mapping tables would be needed.
That claim did not hold: the BMV wants `WALMEX*` where Yahoo says `WALMEX.MX`, so a per-provider
override was built.

- **`assets.provider_symbols`** — a `jsonb` column, default `{}`, `NOT NULL` (`db/schema.rb:109`).
  Keys are provider names as `Integration#provider_name` spells them; values are that provider's
  symbol for the instrument.
- **`Administration::UseCases::Assets::MapProviderSymbol`** writes it, and only after the provider
  has actually answered to the candidate — an unconfirmed mapping is rejected, because a wrong one
  is worse than none: the sync then fails on a name the owner believes is right. The provider must
  also already be in the asset's chain per `DataSourceRegistry`.

**What did not change.** `Asset.symbol` still holds the provider's canonical form verbatim and is
still the identity of the instrument. `provider_symbols` is an override consulted per source, not a
second identity and not a rename — the rule this document states is intact. This is the shape the
"When to revisit" section below asked for: *document the mapping rather than munging at write time.*

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

- ~~If a new data provider uses a different suffix (e.g., `MX:` prefix, `:MEX`), document the mapping rather than munging at write time.~~ **Fired and answered** by `assets.provider_symbols` — see the amendment above.
- If we ever need to display multiple symbols for the same instrument across providers, introduce a separate `Asset::Identifier` table — do not break this rule on `Asset.symbol`. (`provider_symbols` is a per-source override, not the display case; that trigger has not fired.)
