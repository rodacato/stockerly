# Stockerly — Vision

> Last updated: **2026-08-20** (pivot to self-hosted single-user tracker — see [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md))
> This folder is the **single source of truth** for why Stockerly exists, who it's for, what it does, and what it doesn't do.

---

## North star

> **Stockerly is a self-hosted, single-user asset tracker for one person's investment patrimony — stocks (USD), crypto, and Mexican fixed income (CETES) — with correct multi-currency MXN/USD tracking (historical FX at trade execution). It is built for Adrian as a daily-driver, and packaged from day one so any technically capable person can stand it up with one command and understand what they're seeing without a manual. MXN/MX-first is the differentiator.**

**Success is measured by two things:** (1) Adrian opens it every week by choice, and (2) a technical third party can stand it up, load their first asset, and read their first indicator without friction — *without a chore*.

This north supersedes the 2026-05-14 reset, which set the audience as Adrian + a closed beta of ≤20 invited friends. **That beta was run and failed** — friends didn't know what to do inside the app, couldn't read the indicators, and found loading trades a *fastidio*. Those are UX failures, not code failures. The full decision, including why this is a pivot-in-place and not a rewrite, is [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md).

---

## Audience

See [`audience.md`](./audience.md). In summary:

- **Primary (and only real) user:** Adrian (dogfood) — MX investor with mixed MXN+USD patrimony plus crypto. **Reads it 2–3 times a day, trades on 1–2 days a week** — two cadences, not one; see [audience.md](audience.md).
- **Packaging target (not a managed audience):** a technically capable self-hoster who can run a container. We build for Adrian; the third party is served by keeping setup and onboarding clean — never by building features for users who don't exist yet.
- **Non-users:** multi-user / teams, day traders, advisors, gringo investors, accountants, aggregator-sync seekers.

---

## Jobs to be Done

See [`jobs-to-be-done.md`](./jobs-to-be-done.md). The 6 JTBDs from 2026-05-14 largely survive the pivot; a seventh was added 2026-08-29. **JTBD #5 (capture a trade in under 30 seconds) is now central** — the beta died partly on data-entry friction, so frictionless capture is a first-class goal, not a nicety.

---

## The three failures the 2.0 must fix

The beta abandonment gave us three concrete failures. They are the product work of the 2.0:

1. **Empty first-run / no guidance** → seed a realistic MXN/USD+CETES demo so first-run is never a blank screen.
2. **Can't read the indicators** → inline `?`-tooltips explaining each indicator (RSI, MA200, F&G) in one sentence, plus one distilled signal metric.
3. **Data entry is a chore** → holdings-snapshot entry with a *skip-history* default, smart CSV import, and manual entry made pleasant (ticker autocomplete, Banxico FX auto-filled at trade date, learned rules).

Evidence for these choices — how nine other self-hosted trackers succeed and fail on the same three axes — is in [`../research/competitive-trackers-2026-08.md`](../research/competitive-trackers-2026-08.md).

---

## What we are NOT

See [`non-goals.md`](./non-goals.md). The headline additions from the pivot: **no multi-user**, and **no aggregator sync (Plaid/Yodlee/SnapTrade)** — the latter is a cost trap that helped kill a same-stack competitor (Maybe Finance).

---

## Four hard rules (non-negotiable)

1. **Multi-currency MXN/USD is a first-class citizen**, not an "international feature". Without this, the JTBDs lie.
2. **Build for the real user (Adrian) first.** "Self-hosted for anyone" is packaging discipline, not a mandate to build for a hypothetical community. When a feature serves only the imagined self-hoster, it doesn't get built.
3. **Every new feature passes the 4-filter:** documented personal trigger + JTBD + usage metric + Definition of Done. Without all 4, it doesn't get built. This applies with full force to the tempting data-entry ideas (AI PDF import, crypto exchange sync).
4. **Self-contained by default — the fewest vendors a self-hoster can inherit.** When a capability can be met inside the app or by a third-party service, the in-app answer wins unless it isn't viable. A *required* external service is a scope change and needs its own ADR; an optional one must degrade honestly, the way a missing market-data key does. **The maintainer's own infrastructure is never the product's answer** — Cloudflare Tunnel, Tailscale and Access are how this instance is deployed, not a mitigation any other instance inherits. See [ADR-019](../architecture/adr/0019-self-contained-by-default.md), which was written the day this rule decided TOTP over Cloudflare Access.

---

## Product language

Stockerly speaks in **descriptive language, never prescriptively**. Interpreted technical indicators (*"AAPL appears oversold per RSI(14)"*) are allowed. Action verbs directed at the user (*"buy AAPL"*) are forbidden. Full decision: [`../architecture/adr/0001-descriptive-not-prescriptive-language.md`](../architecture/adr/0001-descriptive-not-prescriptive-language.md).

---

## How this north changes

- Edits to `README.md`, `audience.md`, `non-goals.md`, `jobs-to-be-done.md` require a commit message with reason.
- Structural changes (audience, scope, product language) require a **new ADR** referencing the change. This pivot is [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md).
- **Periodic audit:** a sprint retro question is *"Is the north still true, and does Adrian actually use it?"*. The 2026-05-14 audience failed that audit; this is the correction.

---

## Sibling documents

| Doc | Purpose |
|---|---|
| [`audience.md`](./audience.md) | The single real user, the packaging target, non-users |
| [`non-goals.md`](./non-goals.md) | What we explicitly are NOT (audience, scope, market) |
| [`jobs-to-be-done.md`](./jobs-to-be-done.md) | The 7 JTBDs expanded with data, surfaces, triggers, metrics |
| [`../research/competitive-trackers-2026-08.md`](../research/competitive-trackers-2026-08.md) | How other self-hosted trackers solve onboarding / indicators / data-entry |
| [`../architecture/adr/`](../architecture/adr/) | Immutable architecture decisions |
