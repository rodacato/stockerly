# Stockerly Audience

> For something to qualify as a feature, someone on this list must actually need it.
> If nobody here needs it, it doesn't get built. Full stop.
> Last updated: **2026-08-20** (pivot — see [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)).

## Primary user — Adrian (the only real user, dogfood)

- Personal investor with patrimony split between **MXN (CETES, possibly Cetesdirecto)** and **USD (NYSE/NASDAQ-listed equities, bought via a Mexican broker that operates in USD for MX residents)**, plus **crypto**.
- The same stocks are quoted in USD; common flow: convert MXN→USD to invest, eventually convert USD→MXN.
- Reviews portfolio **weekly**, not daily. Not a day trader.
- Knows how to code, values clean architecture, but is fed up with his own over-engineering.

**Jobs to be Done (JTBD):**
1. *When I review my portfolio over the weekend, I want to see my total patrimony consolidated in MXN, so I can know whether I'm up or down since last time.*
2. *When my position drops X% from average cost (in MXN), I want to know, so I can decide whether to average down or exit.*
3. *When a CETE is about to mature, I want to know with 7 days of lead time, so I can decide whether to reinvest.*
4. *When an earnings event is coming for something I hold, I want to know 2 days ahead, so I don't find out after the fact.*
5. *When I add a new trade, I want to capture it in under 30 seconds, so I don't abandon the recording out of laziness.* **(Now central — the beta died partly on data-entry friction.)*
6. *When one of my positions (or a watchlist asset) enters a notable technical zone (oversold/overbought per RSI, Bollinger Bands break, moving-average crossover), I want to see it described in context — with a one-sentence explanation of what the indicator means — so I can factor it into my weekly reflection.* **(Now carries the inline-explanation requirement — failure #2.)*

**Product language constraint (formalized in ADR-001):**
- Stockerly speaks descriptively: *"AAPL appears oversold per RSI(14)"*.
- Stockerly does NOT speak prescriptively: *"buy AAPL"*, *"consider selling"*, *"good time to..."*.
- Technical indicators, composite scores (TrendScore, F&G), state interpretations ("oversold", "overbought", "breakout") are valid.
- Probabilistic predictions and action recommendations are out.

**Explicitly OUT of scope (unchanged):**
- ❌ Fiscal reports (ISR, declarations, dividend withholding, foreign-exchange fiscal calculations)
- ❌ SAT integrations
- ❌ Calculations to prepare annual tax declaration

## Packaging target — a technical self-hoster (NOT a managed audience)

The 2.0 is packaged so **any technically capable person can stand it up with one command and understand it without a manual**. This is a **discipline on how we build**, not an audience we build features for.

- We build for Adrian. The self-hoster is served by keeping **setup and onboarding clean** — a one-command deploy, a seeded demo, inline indicator explanations.
- We do **NOT** build features for a hypothetical self-hosting community. That is the next audience-fantasma, and it is the same mistake the failed ≤20-friend beta made ([`ADR-0010`](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)) — building for a persona nobody is, the second entry on the maintainer's own anti-pattern list.
- If real self-hosters ever show up with repeated, documented needs, revisit via ADR — don't pre-build for them.

**What a self-hoster gets:** open-source code (AGPL/MIT as decided), a documented one-command deploy, their own data on their own server. **What they do NOT get:** an SLA, support, or advance notice of breaking changes. It's a personal tool you're welcome to run.

## Why the closed beta was dropped

The 2026-05-14 vision added a secondary audience of ≤20 invited friends. It was tried and **failed**: friends didn't know what to do in the app, couldn't read the indicators, and found loading trades a chore, so they abandoned it. The correct response is not to double down on the beta but to **remove the fake audience** and refocus on the one real user plus clean packaging. The invite-code system, multi-user identity surface, and admin user management built for that beta were **deleted** in the 2.0 cleanup that shipped 2026-08-23 (see ADR-0010).

## Non-users (what we explicitly are NOT)

- ❌ **Multi-user / teams / shared portfolios** — single-user by design; no multi-tenant, no accounts, no roles.
- ❌ **Aggregator-sync seekers** — no Plaid/Yodlee/SnapTrade. See non-goals; it's a cost trap that helped kill a same-stack competitor.
- ❌ **Day traders / scalpers** — no sub-daily time resolution.
- ❌ **Institutional investors / advisors** — no advisor↔client separation.
- ❌ **General public arriving via Google** — no commercial landing, no SEO, no funnel.
- ❌ **Investors outside Mexico** — the logic is modeled around MXN+USD via a Mexican broker.

## When the "use at your own risk" posture changes

- **Only if** Stockerly becomes a paid / monetized product — not currently a goal.
- **Until then:** a personal, self-hostable tool. No SLA, no support guarantee.
