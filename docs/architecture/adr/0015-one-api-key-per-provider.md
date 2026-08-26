# ADR-015 — One API key per provider; retire multi-key rotation

- **Status:** Accepted
- **Date:** 2026-08-26
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), `design/DECISIONS.md` (D18), [market-data-providers-2026-08.md](../../research/market-data-providers-2026-08.md)

---

## Context

`ApiKeyPool` and `KeyRotation` hold several API keys for the **same** provider and rotate between
them so that a free tier's daily allowance can be spent more than once. Design decision **D18**
endorsed the mechanism and the Integraciones artboard renders it — Alpha Vantage appears with
"2 llaves", under copy that explains the practice to the user:

> *"Varias llaves de la misma fuente se rotan para estirar el límite gratuito."*

The provider audit of 2026-08 read the terms of every configured source. **Four providers — Alpaca,
Massive (ex-Polygon), Finnhub and CoinGecko — explicitly prohibit using multiple accounts or
credentials to exceed the limits of a free tier.** The practice was adopted before those terms were
read; Massive's were rewritten on 2025-08-28, after the gateway that consumes them.

Three distinct things had been running together under one name, and only the first is the problem:

| | Status |
|---|---|
| Several keys of the **same** provider, to stretch its quota | **prohibited** — this is D18 |
| Falling back to a **different** provider when one fails | legitimate, and already built as `GatewayChain` |
| Rotating a credential on expiry or compromise | legitimate, different purpose, different code |

The resilience the pool appeared to provide is the second row, which exists independently of it. The
pool only ever bought quota — concretely, Alpha Vantage 25 → 50 calls a day.

**Renaming the mechanism to "primary key + fallback key" was considered and rejected.** The terms
prohibit the *conduct* — multiple credentials used to exceed a limit — not the label. A second
account of one's own that activates precisely when the first is exhausted is that conduct whatever
it is called, and a euphemistic name reads worse than an honest one, because it demonstrates the
author understood the rule.

## Decision

**One API key per provider.** `KeyRotation` loses its quota-stretching role, `ApiKeyPool` collapses
to a single credential per source, and the D18 copy and the multi-key affordance are removed from
Integraciones.

The decisive argument is proportion, not law. Nobody litigates over twenty-five free calls; the real
exposure is **account termination**, and Stockerly is a product other people run on their own
machines with their own credentials. A practice that risks stranding every self-hoster is not worth
one extra day of fundamentals.

The same audit also removes most of the incentive: Alpha Vantage grants **unlimited requests to
verified open-source projects**, and DataBursatil supplies 200,000 credits a month on its own.

## Consequences

- **This is a rework, not a delete.** `KeyRotation.next_key_for` currently feeds **seven gateways**,
  including Banxico, which serves both FX and CETES. Removing it carelessly dark-fails all external
  sourcing. The single-key path must replace it before the pool is dropped.
- **Integraciones changes.** The "2 llaves" affordance and the explanatory copy go. The screen shows
  one key per provider.
- **The quota ceiling becomes real**, which the interface must now state honestly. With no pooling,
  a provider's published limit is the limit — and limits are not comparable across providers: calls
  per minute for one, calls per day for another, **KiB per month** for DataBursatil. Integraciones
  needs a provider-defined quota unit rather than one shared integer.
- **The tier ladder keeps its justification either way.** Prioritising positions → watchlist → rest
  against a scarce budget (D9) remains correct; only the size of the budget is in question, pending
  the open-source grant.
- D18 is superseded. `design/DECISIONS.md` records the reversal.
