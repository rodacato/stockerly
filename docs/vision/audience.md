# Stockerly Audience

> For something to qualify as a feature, someone on this list must actually need it.
> If nobody here needs it, it doesn't get built. Full stop.
> Pivot of 2026-08-20 — see [ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)).

## Primary user — Adrian (the only real user, dogfood)

- Personal investor with patrimony split between **MXN (CETES, possibly Cetesdirecto)** and **USD (NYSE/NASDAQ-listed equities, bought via a Mexican broker that operates in USD for MX residents)**, plus **crypto**.
- The same stocks are quoted in USD; common flow: convert MXN→USD to invest, eventually convert USD→MXN.
- **Checks the portfolio 2–3 times a day**, in his own words: *"me gusta saber si voy ganando o
  perdiendo dinero al momento, como 2-3 veces al día reviso mis apps"* (2026-09-05). This line read
  *"Reviews portfolio weekly, not daily"* from 2026-05-14 until then, and it was never measured.
- **Trades on 1–2 days a week, in batches.** Measured against production 2026-09-05 — trading days
  per month since the account opened: `8, 13, 13, 12, 6, 2, 8, 8, 4, 4`, about five trades on a day
  he trades. Not a day trader, which is the half of the old line that was right.

> **The two cadences are not the same premise, and only one of them moved.** Reviewing is how often
> he *looks*; trading is how often he *decides*. [ADR-0001](../architecture/adr/0001-descriptive-not-prescriptive-language.md)
> and [ADR-0013](../architecture/adr/0013-action-labels-on-persisted-observations.md) both argue
> from *"retail investors on a weekly cadence rarely generate alpha"* — that is the **decision**
> cadence, the measurement above confirms it, and neither ADR is affected. Do not "correct" them
> from this entry.

- Knows how to code, values clean architecture, but is fed up with his own over-engineering.

**Jobs to be Done:** the seven JTBDs, with statements, surfaces and metrics, are in [`jobs-to-be-done.md`](./jobs-to-be-done.md).

### Consult as `el-usuario`

The primary user is also a seat on the [expert panel](./experts.md) — **C11 `el-usuario`**: Adrian on
the couch on a Sunday night, phone in hand. Kept apart from builder-Adrian on purpose, because the
builder is the one who wants the events table and the user is the one who wants to know whether he
is up or down.

- **Who he is in that moment:** part-time, on a phone, 15–20 minutes, wants a *decision* rather than
  a dashboard, and abandons anything that feels like a chore. He is the person the closed beta
  failed.
- **Consult on:** every screen, every data-entry flow, every "should we add X".
- **His job is to veto** a proposal that serves builder ambition over that moment — backend rigor
  before a usable screen, a feature for a self-hoster who does not exist, a step that makes capture
  slower.
- **His voice:** plain and impatient. *"Beautiful plumbing for a house I still can't live in."*

**Product language constraint (formalized in ADR-001):**
- Stockerly speaks descriptively: *"AAPL appears oversold per RSI(14)"*.
- Stockerly does NOT speak prescriptively: *"buy AAPL"*, *"consider selling"*, *"good time to..."*.
- Technical indicators, composite scores (TrendScore, F&G), state interpretations ("oversold", "overbought", "breakout") are valid.
- Probabilistic predictions and action recommendations are out.

**Explicitly OUT of scope:** fiscal work of any kind. The list is in [`non-goals.md`](./non-goals.md#fiscal).

## Packaging target — a technical self-hoster (NOT a managed audience)

The 2.0 is packaged so **any technically capable person can stand it up with one command and understand it without a manual**. This is a **discipline on how we build**, not an audience we build features for.

- We build for Adrian. The self-hoster is served by keeping **setup and onboarding clean** — a one-command deploy and inline indicator explanations (a first-run demo is a stated intent, not built).
- We do **NOT** build features for a hypothetical self-hosting community. That is the next audience-fantasma, and it is the same mistake the failed ≤20-friend beta made ([`ADR-0010`](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)) — building for a persona nobody is, the second entry on the maintainer's own anti-pattern list.
- If real self-hosters ever show up with repeated, documented needs, revisit via ADR — don't pre-build for them.

**What a self-hoster gets:** MIT-licensed code, a documented one-command deploy, their own data on their own server. **What they do NOT get:** an SLA, support, or advance notice of breaking changes. It's a personal tool you're welcome to run.

## Why the closed beta was dropped

The 2026-05-14 vision added a secondary audience of ≤20 invited friends. It was tried and **failed**: friends didn't know what to do in the app, couldn't read the indicators, and found loading trades a chore, so they abandoned it. The correct response is not to double down on the beta but to **remove the fake audience** and refocus on the one real user plus clean packaging. The invite-code system, multi-user identity surface, and admin user management built for that beta were **deleted** in the 2.0 cleanup that shipped 2026-08-23 (see ADR-0010).

## Non-users

Kept in one place: [`non-goals.md`](./non-goals.md#non-users-audiences-we-do-not-serve).

## When the "use at your own risk" posture changes

- **Only if** Stockerly becomes a paid / monetized product — not currently a goal.
- **Until then:** a personal, self-hostable tool. No SLA, no support guarantee.
