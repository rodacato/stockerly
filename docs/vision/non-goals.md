# Stockerly Non-Goals

> What Stockerly explicitly **is NOT**. As important as what we ARE.
> Each non-goal here is a conscious decision with a reason. Changing one requires an ADR.
> Last updated: **2026-08-27** (provider rationales re-verified against the code; pivot to
> self-hosted single-user is [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md), 2026-08-20).

---

## Non-users (audiences we do NOT serve)

| Not for | Why |
|---|---|
| **Multiple users on one instance** | Single-user by design (ADR-0010). No multi-tenant, no accounts, no roles. Self-hosting means one person, one instance. |
| **Day traders / scalpers** | Product is modeled around daily-EOD cadence. No sub-daily time resolution, no tick-level WebSocket. |
| **Institutional investors / advisors** | No multi-tenant, no accounts, no role separation between advisor and client. |
| **General public arriving via Google** | No commercial landing, no SEO, no conversion funnel. The repo is a public portfolio, not a pull product. |
| **Investors outside Mexico** | Logic is modeled around MXN+USD via a Mexican broker. CETES, IPC, Banxico FX. |
| **Tax-professional accountants** | We don't replace accountants. See "Functionality out of scope" below. |
| **OSS contributors forking the project** | Public repo as portfolio, but PRs **not** accepted until v1.0. |
| **Minors / users without investment capacity** | Product assumes an adult user with a real broker account. |

---

## Functionality out of scope

### Fiscal

| Not built | Why |
|---|---|
| ISR declaration reports | 2026-05-14 decision: fiscal is out of scope. The product focuses on patrimony tracking, not tax preparation. |
| SAT integrations | Same reason. |
| US W-8BEN dividend withholding calculation | Same reason. |
| Fiscal foreign-exchange gain/loss for declarations | Same reason. |
| FIFO/LIFO tax lot tracking | Requires a complete tax model. Out of scope. |
| Wash sale detection | US-specific tax rule, doesn't apply to MX context. |

### Product language (ADR-001)

| Not built | Why |
|---|---|
| Prescriptive recommendations: "buy X", "sell Y" | Moral liability toward anyone reading it (the original reason, argued when a friends beta was still planned); empirical evidence that retail TA rarely generates alpha; wrong signal about what the product is. |
| Probabilistic predictions: "73% chance of going up" | Same. Detail: see ADR-001. |
| Implicit timing recommendations: "now is a good time to...", "worth considering..." | Same. |
| Confidence-weighted action forecasts | Same. |
| Section names like "Suggestions", "Recommendations", "Actions to take" | The prescriptive noun becomes a loophole for feature creep. Use "Observations", "Technical analysis", "Context" instead. |

### Data entry & integrations

| Not built | Why |
|---|---|
| **Aggregator bank/broker sync (Plaid, Yodlee, SnapTrade)** | **Permanent non-goal at this scale.** A cost trap: automated sync always sits behind a paid aggregator, and Maybe Finance — the same Rails/Hotwire/Postgres stack — died partly on Plaid economics. MX coverage is thin and expensive. See [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md) and [the competitive research](../research/competitive-trackers-2026-08.md). Pluggy.ai / Belvo (LatAm-native) are the only ones worth even a future spike, and only behind a documented trigger. |
| Per-broker CSV auto-parsers (Portfolio-Performance-style, 90+ parsers) | Huge maintenance surface; few MX brokers justify it. Smart generic CSV mapping covers the realistic need. |
| AI PDF/screenshot statement import; crypto exchange API sync; read-only wallet import | Genuinely attractive, but each requires a documented trigger + JTBD before any work (4-filter, anti-pattern #1). Not rejected — deferred until earned. |
| **Any third-party service the instance *requires* to work** | [ADR-019](../architecture/adr/0019-self-contained-by-default.md): a self-hoster inherits every dependency the product declares, and cannot be asked to sign up for one to get a feature. Optional vendors are fine and must degrade honestly — market-data providers are the model. The maintainer's own ingress (Cloudflare Tunnel, Tailscale, Access) is deployment, never the product's answer to a risk every instance carries. Adding a required service is a scope change and needs its own ADR. |

### Product

| Not built | Why |
|---|---|
| Formal SLA (uptime, response time) | This is a personal, self-hostable tool. Revisit only if Stockerly becomes monetized. |
| Native mobile apps (iOS/Android) | PWA already covers installation and icons. Not worth maintaining two platforms. |
| Multi-tenancy / shared accounts / team portfolios | Single-user by design (ADR-0010). The multi-user surface built for the failed beta was deleted in the 2.0 cleanup, not extended. |
| ~~Internationalization (i18n)~~ | **No longer a non-goal.** [ADR-0011](../architecture/adr/0011-adopt-i18n-for-the-2.0-rewrite.md) adopted `i18n-tasks` with a single locale during the 2.0 rewrite: deferring was right while the alternative was rewriting working screens, and stopped being right once every string was being rewritten anyway. es-MX is still the only language — what changed is where the strings live. |
| Social features: public sharing, comments, forums, leaderboards | Not a social product. Not a community product. |
| Profile sharing / public profile privacy mode | Subset of the above. |
| Real push notifications (browser/SMS) | Optional bonus, not core. Email + in-app is enough. |

### Market and asset classes

| Not built | Why |
|---|---|
| Markets outside USA + Mexico | Audience is MX investor. Other markets are scope creep. |
| Options / warrants / derivatives | Products with Greeks, expiries, chains — entirely different asset class. Would be another product. |
| Forex (pure FX trading) | FX is modeled only as a rate for conversion, not as a tradable asset. |
| Futures / commodities | Same. |
| Corporate bonds (beyond CETES) | If Adrian needs them personally, evaluate via ADR. For now, no. |
| Real estate / illiquid assets | Out of scope. |
| Tokenized assets / NFTs | Out of scope. |
| Active crypto trading (beyond basic holdings) | Current crypto model is tracking-only, not active trading with order types. |

### Real-time and data engineering

| Not built | Why |
|---|---|
| Tick-level WebSocket for live prices | No configured provider streams on a free tier — Alpaca's free plan refuses anything inside 15 minutes at all — and daily polling is enough for a weekly cadence. |
| Deep historical data (>5 years) | Alpaca reaches 2016 and CoinGecko's free tier walls off at 365 days; the exception is Banxico, whose full FIX series was backfilled to 1991 because it is one free request (ADR-009). Enough for current JTBDs; if Adrian needs more depth, evaluate. |
| Strategy backtesting | A TA backtesting product is a different thing. Stockerly observes the present, it doesn't simulate the past. |

### Performance

| Not built | Why |
|---|---|
| Optimize for >10K simultaneous users | Single-user, self-hosted, one instance per person. Current architecture is already excessive for that scale. |
| Read replicas, sharding, advanced caching | Solid Cache + fragment caching are already in place. More would be over-engineering. |

---

## How a new non-goal gets added

1. A feature or expansion proposal comes up.
2. If it falls into one of the categories above → automatically out, not discussed in sprint planning.
3. If it's ambiguous → discussion + conscious decision → if decided "out", add it here with a reason.
4. Changing a non-goal (removing it from the list) requires an ADR.

---

## How a non-goal gets removed

Only under one of these conditions:
- Audience change (e.g., Stockerly gets monetized → SLA may come in)
- Change in Adrian's personal reality (e.g., he starts trading European markets)
- A real self-hoster shows up with a documented, repeated need (not a hypothetical one) — evaluate via ADR, don't pre-build

In any case: an ADR documents the change and the reason.
