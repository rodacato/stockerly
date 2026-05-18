# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Close the pre-beta blockers surfaced by research (terms + risk + privacy + ARCO + Art. 8 consent + cost-basis P0) and revamp the auth flow (login + register) so the first invited friend registers on legally sound and mathematically truthful foundations.

**Sprint period:** 2026-05-17 → TBD (close by QA + retro, not by date)

**Sprint number / milestone:** S08 — 2026-S08-beta-readiness

---

## Why this goal and not another

S07 closed with the system functionally ready to invite the first friend to closed beta. But the parallel research executed on 2026-05-17 surfaced 5 pre-beta blockers + 1 carry-over P0 that **make the invite irresponsible** in its current state:

1. **Terms of Service and Risk Disclosure are defective** — they declare broker activities (margin/leverage/liquidation/NY jurisdiction) that Stockerly does NOT perform. An invitee "accepts" documents that misrepresent the product. Consent defect + possible civil liability.
2. **The Privacy Notice** rewritten in S07 #73 is es-MX and well-intentioned, but remained incomplete against the NLFPDPPP (DOF 20-mar-2025): missing SABG context (INAI extinct), distinguishing necessary vs voluntary purposes (Art. 15), retention policy (Art. 11), declaration of international remissions (Arts. 35-36 — currently says "we do not transfer to third parties" which is false).
3. **No express consent for patrimonial data** (Art. 8 NLFPDPPP). The current register accepts terms + privacy but the user's portfolio + trades require specific non-pre-checked consent.
4. **No operational ARCO procedure** documented (Art. 32 NLFPDPPP, 20 business days).
5. **TakeSnapshotsJob sums cross-currency without conversion** — the dashboard mockup (#90) shows `MXN 1,247,580.40` as consolidated total, but the job that produces that figure today sums USD + MXN as if they were the same unit. **The dashboard math is fiction for mixed portfolios.**

In addition to closing blockers, S08 revamps **/login** + **/register** for Lumen + es-MX (auth-family completion started in S07 #73). The register naturally integrates the B-03 Art. 8 consent — co-fix.

**What this unblocks:** the system becomes **actually** ready to send the first invite, with legally correct and mathematically truthful foundations. The auth flow is coherent and natively es-MX.

---

## What's NOT in this sprint (anti-scope)

- **Design revamps of operational screens** (#90 dashboard, #91 portfolio, #92 market, #93 asset-detail, #94 alerts, #97 profile, #98 trades, #99 password recovery) — the Stockerly-2.0 mockups are ready in `.local/`, but implementation belongs to **S09**. Reason: there's no point implementing the dashboard while TakeSnapshotsJob produces false data; the post-fix implementation will sit on truthful math.
- **S08 research candidates not prioritized:** C2 tax_regime, C3 natural-language alerts, C4 single-primary-number dashboard, C5 technical microcopy, C6 liquidity tag, C7 FIBRA distributions, C8 UDI third unit. Defer to S09+.
- **Non-critical audit findings:** F-01 encryption-key fallback (audit-security), `Notification.create!` bypass (audit-architecture-drift), admin/settings + ExecuteTrade concurrency coverage gaps (audit-test-coverage). NOT beta-blockers. Worth tackling but defer.
- **Pending Earnings + Notifications mockups** (#100, #101) — Adrian generates them tomorrow when his Claude Design quota resets.
- **External legal review** of the new terms + risk disclosure + privacy — remains a post-beta TODO (consistent with S07 #73 decision).
- **Discovery-card audit script automation** — process discipline carry-over from S07 retro, applied manually this sprint.
