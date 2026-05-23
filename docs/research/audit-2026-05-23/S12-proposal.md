# S12 Scope Proposal — Evidence-Based

> Built from the synthesis in `synthesis.md`. **Not yet committed** — Adrian's call.
>
> Recommended shape: **"Hardening + Instrumentation"** — close the P0/P1 trust + safety + visibility gaps that 8 independent experts surfaced, so cohort #2 can be invited from a position of confidence and the resulting feedback can actually be measured.

---

## Sprint goal (proposed)

**Close the trust, security, and visibility gaps surfaced by the 2026-05-23 expert audit so Adrian can invite beta cohort #2 (5 more amigos) from a position of confidence — and *know* whether they actually use the product.**

Themes:
1. **Trust:** the dashboard numbers must match the broker statement (multi-currency calculator audit + Banxico FX)
2. **Safety:** the invite flow must not break under concurrency or leak via enumeration (invite race + enumeration + expiration)
3. **Visibility:** Adrian must be able to answer "did the amigo open the email? click the link? use feature X?" within seconds (Resend webhooks + UserActivity)
4. **Compliance:** the published privacy notice must route to a real human (support email fix + in-app account deletion)
5. **Polish (carry-over from S11 audit):** finish the Lumen migration so chrome stops feeling assembled from different sources

---

## Issues to file (proposed)

### Wave 1 — P0 trust + legal (sequential, do first)

| # | Title | Source | Effort |
|---|---|---|---|
| A | Audit + fix multi-currency calculators against trade FX rates | C1 Lucía + C6 Esther | 4-8h |
| B | Replace `Stockerly::SUPPORT_EMAIL` with a real, monitored address | S5 Ileana | 15 min |

**Wave 1 rationale:** A blocks more invites (dashboard could be lying). B is a 15-min legal patch. Both ship before anyone else touches code.

### Wave 2 — P0 invite-flow safety (single PR, can be Wave 1 parallel)

| # | Title | Source | Effort |
|---|---|---|---|
| C | Seal invite-code race condition + add expiration + normalize enumeration error | C7 Fadia + S1 Olusegun | 2-3h |

**Wave 2 rationale:** Three small fixes to the same model in one coherent PR. Block cohort #2 if not shipped.

### Wave 3 — P0 visibility (parallel agents)

| # | Title | Source | Effort |
|---|---|---|---|
| D | Wire Resend webhooks → `EmailEvent` table for invite delivery tracking | S1 Olusegun | 2-3h |
| E | Add `UserActivity` table + event subscriptions for top feature actions | S1 Olusegun + C6 Esther | 3h |
| F | Hourly `CheckSyncHealthJob` → Sentry alert on stale syncs | S1 Olusegun | 1-2h |

**Wave 3 rationale:** Three small, disjoint instrumentation PRs. Perfect parallel-agent fit. Together: Adrian can answer "did amigo get email" + "what does amigo do" + "did sync fail" without grepping logs.

### Wave 4 — P1 polish + data trust (parallel)

| # | Title | Source | Effort |
|---|---|---|---|
| G | Integrate Banxico FX rates (TC_TC002) as primary USD/MXN source | C1 Lucía + S2 Adriana | 2h |
| H | Lumen migration: card chrome + sidebar typography + auth pages + allocation donut | C5 Renata | 3h |
| I | In-app account deletion flow (ARCO Cancelación) | S5 Ileana | half day |

**Wave 4 rationale:** Independent areas (gateway / views / use case). Can ship in any order.

### Wave 5 — Close

| # | Title | Source | Effort |
|---|---|---|---|
| J | Audit + qa + retro + close | (sprint protocol) | 1h |

### Parallel/reactive bucket

| # | Title | Source | Effort |
|---|---|---|---|
| K | S12 reactive bucket — beta amigo feedback triage + fixes | (continuing from S11 #150) | flexes |

---

## Totals

| Wave | Items | Effort estimate (raw) | Notes |
|---|---|---|---|
| 1 | 2 (A, B) | 4-9h | Sequential foundation |
| 2 | 1 (C) | 2-3h | Can run parallel to Wave 1 |
| 3 | 3 (D, E, F) | 6-8h | 3 parallel agents |
| 4 | 3 (G, H, I) | 7-9h | 3 parallel agents |
| 5 | 1 (J) | 1h | Close ritual |
| Reactive | 1 (K) | flexes | Beta feedback |
| **Total** | **10 main + 1 reactive** | **~20-30h raw → ~12-18h with parallel-agent dividend** | |

This is a **Large** sprint by S07-S11 calibration — comparable to S11's 8/8 + open + close. The parallel-agent pattern (validated 3 sprints in a row) should compress this to ~1 day of wall-clock if Adrian wants to ship it in one focused window.

---

## Why this shape (not another)

### Why include 10 items, not 4

The S11 retro's anti-pattern flag was "8/8 over-delivery vs the 6-issue plan", but the 8 items were all bounded follow-ups — not greenfield. Same shape here. Each item:
- Surfaced by ≥1 expert with concrete evidence
- Has clear DoD
- ≤ 1 day of effort
- Disjoint from at least 2 others (parallel-friendly)

Smaller (4 items) leaves trust + visibility partially closed; cohort #2 still gets invited blind. Larger (12+) crosses into greenfield.

### Why P0 items go first instead of last

The S10 retro's "preparing-but-not-sending invites" pattern almost repeated with the beta amigo silence. Doing the trust/security/visibility work FIRST means: at any sprint-end checkpoint Adrian can stop and ship a cohort-#2 invite from a position of confidence, even if Waves 4-5 don't complete. Doing them last means a half-finished sprint can't ship.

### Why visibility (Wave 3) ≠ "premature optimization"

Olusegun's audit reframes this: we're not measuring for optimization. We're measuring to **answer questions Adrian asks today and can't answer** (did amigo click? does anyone use the watchlist? did sync fail?). At 1 user, this is overhead; at 5 (cohort #2), it's the only way to learn. Building it BEFORE cohort #2 means cohort-#2 data is captured from day 1.

### Why no broker integration / Bitso / news feeds

S2 Adriana flagged Bitso (BTC/MXN) and El Economista (news) as high-value-add for MX investor. Both are 3-6h. They're P3 here because:
- Beta amigo hasn't validated current crypto / news features
- Adding more without validation = same scope creep S11 flagged

If cohort #2 says "I want native MXN crypto pricing" → S13 P0.

### Why no admin / observability dashboards

C7 Fadia flagged "no audit log UI". S1 Olusegun flagged "no usage dashboard". Both P2 in the audit. The Wave 3 instrumentation captures the DATA; the dashboards to query it can wait until there's enough data to be worth querying.

---

## Risks + mitigations

| Risk | Mitigation |
|---|---|
| Wave 1 calculator audit balloons (more calculators broken than expected) | If A exceeds 8h, split: audit-only PR + per-calculator-fix PRs in S13. Wave 1 ships partial. |
| Beta amigo replies mid-sprint with a critical bug | #150-style reserve bucket (K). 3-5h reserved capacity. If reserve exhausts, scope-cut on H or I (polish-tier). |
| Parallel agents conflict on shared files | Pre-flight audit: D + E both touch event subscriptions; need coordination. Schedule sequentially within Wave 3, or pre-stage the shared `event_subscriptions.rb` edits before launching agents. |
| Adrian's calendar can't absorb a 1-day focused window | Shape A is *sized* for parallel-agent compression but not *required* to be one wall-clock day. Could spread over 3-4 days of normal cadence. |

---

## Alternative: Shape B (minimum-blocker only)

If Adrian prefers a smaller sprint:

**Goal:** Ship only what's required before the next invite.

**Issues:** B (support email, 15 min) + C (invite race, 2-3h) + that's it.

**Total:** 3-4h. One afternoon.

**Trade-off:** Trust gap (F1 calculators) and visibility gap (F5 usage data) remain open. Adrian invites cohort #2 with the same blind spots he has today, and S13 inherits the same audit findings.

**When to choose B:** If Adrian wants to wait on cohort #1 feedback before committing scope. Honest, but defers the same decisions by 1-2 weeks.

---

## Recommendation

**Ship Shape A.** The expert audit gave us 8 independent confirmations of the same pattern: structure is right, calibration is missing. Closing the calibration gaps unlocks every subsequent sprint to be evidence-based instead of guess-based.

If beta amigo feedback arrives mid-sprint and significantly redirects priority, the S11-validated pattern works: absorb into #150 reactive bucket (K), descope H/I if needed, but Waves 1-3 ship regardless because they're foundational to making the rest of the sprint observable.

---

## What needs Adrian's input before filing issues

1. **Confirm Shape A vs Shape B** (or a hybrid)
2. **Confirm support email** — what's the real address to replace `support@notdefined.dev`?
3. **Confirm scope-cut priority** — if we have to drop one of {G Banxico, H Lumen polish, I deletion flow}, which goes first?
4. **Confirm parallel-agent comfort level** — Waves 3 and 4 each suggest 3 parallel agents; that worked in S11 but doubles to 6 concurrent if both waves overlap. Sequential is safer.
5. **Confirm reactive bucket K stays open into S12** (it's already open from S11 as #150)
