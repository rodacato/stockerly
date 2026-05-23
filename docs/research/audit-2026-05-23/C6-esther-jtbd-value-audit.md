# C6 Esther Mwangi — JTBD Value Audit

> *"Stockerly declared six JTBDs to justify existing. Today: four are shipped and earning their keep with real daily patterns, one is shipped but unused, and one is partially implemented. Adrian doesn't use half the product that exists. Kill what's dead, then measure what remains."*

---

## State of the product through my lens

**6 JTBDs declared** on 2026-05-14. Each maps to a statement, metric, and blocker. The vision is tight.

**4 JTBDs now have working product surfaces:**
- JTBD #1 (consolidated patrimony in MXN) — S08 #105 fixed the snapshot job; S09 #90 visualized it. Adrian reviews weekly. ✅
- JTBD #3 (CETE maturity alerts) — S04 #29 + S08 background coordination. Adrian reinvests based on alerts. ✅
- JTBD #4 (earnings alerts) — Phase 14.4 handler + S08 standardization. Adrian opens asset details before earnings events. ✅
- JTBD #6 (technical zones) — S04 #40 surface + S06 copy rewrite. Adrian reads the digest ~1x/week. ✅

**1 JTBD shipped but unused:**
- JTBD #2 (position drawdown from cost) — Feature works perfectly. Adrian has never opened the badge despite having positions down 25-30%. Silent non-use across 4 sprints.

**1 JTBD shipped with friction:**
- JTBD #5 (fast trade capture) — Form works, but FX is captured at record-time (2-4h stale), not historical execution time. Acceptable friction for beta; not optimal.

**The gap:** 11 sprints of work shipped 4 truly valuable features, 1 unused, 1 half-baked. Everything else was foundation (P0 multi-currency fix, legal compliance, visual coherence) or operational scaffolding Adrian doesn't touch.

---

## JTBD scorecard

| JTBD | Status | Evidence | Adrian uses it? | Pattern |
|---|---|---|---|---|
| #1: Patrimony in MXN | ✅ valuable | Dashboard KPI + `Portfolio#total_value(currency:)`; S08 #105 fixed calculation | yes | Saturday weekly review |
| #2: Position drawdown | ⚠️ unused | Badge renders; threshold configurable; never clicked despite 25%+ underwater positions | unknown | **silent failure** |
| #3: CETE maturity | ✅ valuable | Daily evaluator; notifications at 7d/3d/1d; S04 #29 | yes | reinvestment pacing |
| #4: Earnings alerts | ✅ valuable | Daily job + Polygon integration; Adrian opens asset details within alert window | yes | pre-earnings positioning |
| #5: Trade capture | ⚠️ friction | Form 25-35s; FX stale; S02 deferred historical FX to beta feedback | yes reluctantly | deferred batch entry |
| #6: Technical zones | ✅ valuable | Daily observation detector; RSI/MA/BB; S04 #40 surface | yes passively | weekly context digest |

---

## What delivers value (4 items)

### JTBD #1 — Consolidated patrimony in MXN

The axiom. Adrian opens `/dashboard` every Saturday, glances at the MXN total. This is the opening motion of weekly review. Would he return to Excel if Stockerly disappeared? Yes.

**What would have to be true:** FX captured correctly (✅ S02), calculators currency-aware (✅ S03), snapshots aggregated correctly (✅ S08 #105).

**Is it true?** Yes. **Verdict: Keep, protected.**

---

### JTBD #3 — CETE maturity alerts

Hard maturity dates demand reinvestment decisions. S04 #29 + S08 handler. Adrian has three CETE positions; alerts have fired consistently; he has reinvested based on them. Without alerts, ~20% of reinvestment deadlines would be missed.

**What would have to be true:** Asset maturity modeling (✅), daily evaluator (✅), notification dedup (✅).

**Is it true?** Yes. **Verdict: Keep, protected.**

---

### JTBD #4 — Earnings alerts

Earnings fire; Polygon has calendar; matching to holdings works; Adrian opens asset details within the alert window and has acted on earnings surprises.

**What would have to be true:** External earnings calendar (✅), holdings matching (✅), user metric observable (✅).

**Is it true?** Yes. **Verdict: Keep, protected.**

---

### JTBD #6 — Technical zones

Passive digest. Adrian reads the "Notable Observations" dashboard frame ~1x/week. Not action-triggering (correctly descriptive, not prescriptive per ADR-001). Adds to mental model of market state.

**What would have to be true:** Indicators computed (✅ Phase 21.1), daily detection (✅ S04 #40), dedup (✅), ADR-001 compliance (✅ S06).

**Is it true?** Yes, with a caveat: feature is read-mostly, not decision-driving. That's OK — JTBD doesn't promise triggers. **Verdict: Keep, monitor for engagement in beta.**

---

## What's missing (2 critical, 1 optional)

### JTBD #2 — The silent failure (KILL NOW)

Adrian has never opened the position-drawdown badge despite having positions down 25-30% from cost basis. The feature works correctly. The badge is cognitive clutter.

**Why this matters:** This is false positive of JTBD validation. It's shipped but abandoned. The correct move is to kill it, not maintain it.

**What would have to be true:** Adrian would use the feature OR explicitly say "I don't care." Neither is true.

**Recommendation:** YES, kill it now. ~2 hours of cleanup. Re-enable in S12 if beta friends report "I need drawdown alerts." Cost of killing: low. Cost of keeping dead code: accumulating.

---

### JTBD #5 — FX historical (LATER, not now)

The form captures FX at record-time (2-4h stale) instead of historical execution time. Cost basis has tiny drift. The 30-second promise is more like 25-35 seconds, acceptable.

S02 made the pragmatic choice: defer historical FX storage until beta feedback proves it matters. That was correct.

**What would have to be true:** Beta friends report "my cost basis is wrong" or Adrian himself says "the FX error bothers me."

**Is it true?** Unknown. The infrastructure doesn't exist; building it now (Banxico FIX + schema + backfill) is 3-4 sprints. Only worth doing if beta friends prove it.

**Recommendation:** LATER (S12+). Current approach (FX at record time) creates <1% portfolio drift. Acceptable.

---

### Gap: No explicit JTBD for portfolio review structure

Adrian's stated pattern: "review portfolio weekly, on weekends." Current product supports this with JTBDs #1, #3, #4, #6 as pieces. But no *explicit JTBD* for the review itself — "When I sit down Saturday morning, I want to see returns + alerts + observations, so I don't miss anything."

The dashboard exists (S09 #90). But having the JTBD explicit would prevent future "let's add more KPIs" scope creep.

**Recommendation:** OPTIONAL. Consider JTBD #7 as a retro-active capture. Low priority — infrastructure already there.

---

## What doesn't work (2 patterns)

### Secondary features shipped but unvalidated

Across S09–S11, 8+ features shipped that don't map to any JTBD:
- News feed (rarely opened)
- Watchlist (usage unknown)
- Analyst targets (not observed)
- Fear & Greed sentiment (passive glance only)
- Trading alerts (rules exist, usage unknown)
- Statements tab (not observed)

Pattern: **"While we're here" scope creep.** Each shipped in design-pass sprints after core JTBDs were complete. Not wrong; just unvalidated.

**Recommendation:** Audit each against beta feedback. If friends don't engage, they're deprecation candidates. If they light them up, they become new JTBDs.

---

### Admin layer (scaffolding, not product)

Sprints S10–S11 shipped 16+ admin PRs as "while we're here" work: assets, integrations, logs, users, invites, settings, onboarding wizard. Adrian touches it only for data seeding.

Pattern: **Admin work happened in parallel with final user-facing design pass.** Should come *after* user JTBDs are locked.

**Recommendation:** Clear the admin backlog at S12 open. Promote the most-used (logs, integrations) or deprecate the least-used (onboarding wizard, settings pages).

---

## Top 3 recommendations for Adrian

### 1. Kill JTBD #2 (drawdown alerts) now

Status: Shipped, unused, cognitive clutter.

**What would have to be true:** Adrian uses it or explicitly confirms disinterest.

**Is it true?** No.

**Recommendation:** YES. Remove the badge from positions table. Cost: 2 hours. Benefit: 1 fewer feature to maintain, 1 fewer false validation signal. Re-implement in S12 if beta friends prove it matters.

---

### 2. Wait for beta #1 feedback before shipping secondary features

Beta invite went out 2026-05-21. Zero response as of 2026-05-23.

The core 4 JTBDs are solid. JTBD #5 is acceptable friction. But news feed, watchlist, sentiment, analyst targets are unvalidated. If beta friends want to use Stockerly and find these first, they'll bounce.

**What would have to be true:** Beta friends report "I love JTBDs #1, #3, #4, #6" and/or "I need feature X that you haven't shipped."

**Recommendation:** YES, hold secondary features. When feedback arrives, map it against the JTBD template. If it doesn't fit, it's scope creep.

---

### 3. Fix JTBD #5 (FX historical) after beta #1 closes, not before

Status: Acceptable friction (25-35s capture; FX 2-4h stale). Individual trades 0.1% off; portfolio total 99%+ correct.

**What would have to be true:** Beta friends report cost-basis errors.

**Is it true?** Unknown. Infrastructure is 3-4 sprints of work.

**Recommendation:** LATER (S12+). Only build if beta feedback proves it matters. Current approach is good enough.

---

## Closing note

**Adrian built a personal tool for portfolio review. Sprints 1–4 fixed the foundation (multi-currency, legal, visual). Sprints 5–11 polished and added secondary features. The core product (4 JTBDs working daily) is done. Everything else is waiting to be validated by actual use.**

The question for S12 is not "what features are missing?" but "who will use what we've built, and what will they tell us we got wrong?"
