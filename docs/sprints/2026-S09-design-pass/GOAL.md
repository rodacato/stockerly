# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Implement the Stockerly-2.0 design pass on the operational screens (dashboard, portfolio, trades, password recovery) so the first invited friend lands on a visually coherent es-MX UI built on top of S08's truthful + legally valid foundations.

**Sprint period:** 2026-05-19 → TBD (close by QA + retro, not by date)

**Sprint number / milestone:** S09 — 2026-S09-design-pass

---

## Why this goal and not another

S08 closed with the foundations intact: legal validity (B-01/B-02/B-04 + Art. 8 consent + ARCO), mathematical truth (C1 cost-basis fix), and auth-family es-MX (login + register revamps). The first invited friend can now register on legally sound and arithmetically honest ground.

But once they pass `/register`, the screens they actually *use* — dashboard, portfolio, trades — still wear the pre-Lumen treatment with mixed English copy and the pre-2.0 visual language. The Stockerly-2.0 mockups for these screens have lived in `.local/design-mockups/` since before S08; they were explicitly deferred because implementing the dashboard while `TakeSnapshotsJob` produced false data would have shipped a mockup sitting on top of garbage. That precondition is now removed.

**Critical path priority:**

1. **#90 Dashboard** unlocks the visual verification that the C1 fix actually renders truthful MXN for mixed portfolios. Without it, S08's correctness work lives only in specs.
2. **#91 Portfolio** + **#98 Trades** share the trader workflow and the mixed-MXN/USD trade form — they belong in the same sprint.
3. **#99 Password recovery** closes the auth family (login + register already es-MX). Without it the auth flow is 80% native.

**Optional / opportunistic:**
4. **#92 Market explorer** — MX indices first + CETES rates, anchors the MX-first vision.
5. **#97 Profile** — settings-focused, small, mockup-ready.

**Quick win paralelo:**
- **#113 i18n decision card** — ~1h Go/No-Go. Cleanest cleanup for Gemini repetition; doesn't bind sprint resources.

**What this unblocks:** the first invitation can land on a coherent visual experience end-to-end, not a half-revamped one. The mathematical truth from S08 becomes legible (a chart with MXN totals that match what the user expects). The Stockerly-2.0 mockup batch transitions from `.local/` to production.

---

## What's NOT in this sprint (anti-scope)

Explicitly deferred to S10 (mockups exist in `.local/` but not on the S09 critical path):

- **#93 Asset detail revamp** — adaptive-by-type implementation has substantive backend implications (asset-type-adaptive routing for stock/crypto/CETES/FIBRA observation panels) beyond pure visual revamp.
- **#94 Alerts revamp** — MX-aware rule types (CETES rate alerts, FX threshold alerts) require backend rule-type additions, not pure visual work.
- **#100 Earnings revamp** — read-mostly surface; doesn't gate first-invite UX.
- **#101 Notifications revamp** — read-mostly surface; notifications inbox is essentially empty during beta cerrada.

Other deliberate exclusions:

- **Full i18n migration** — decision card (#113) is in scope as Go/No-Go; the actual migration (if Go) is its own multi-sprint effort.
- **External legal review** of S08 legal artifacts — remains post-beta TODO (consistent with S08 retro).
- **External design review** of Stockerly-2.0 — implementation is mockup-faithful; aesthetic critique is post-implementation.
- **New JTBDs or vision shifts** — S09 is purely cosmetic + auth completion on top of S08's foundations.

---

## 24h-pause rule note

S08 closed 2026-05-19 with PR #114 merged same day. S09 opens 2026-05-19 — **24h-pause rule overridden** consciously. Counter: this is the 1st override after the 1st successful honoring (S07→S08). Per memory: "third consecutive override would invalidate the rule". S09→S10 should honor the pause to preserve the rule.
