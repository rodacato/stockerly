# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Close the trust, security, and visibility gaps surfaced by the 2026-05-23 expert audit so Adrian can invite beta cohort #2 (5 more amigos) from a position of confidence — and *know* whether they actually use the product.

**Sprint period:** 2026-05-23 → TBD (close by QA + retro, not by date)

**Sprint number / milestone:** S12 — 2026-S12-trust-safety-and-visibility

---

## Why this goal and not another

The 2026-05-23 audit ran 8 experts in parallel against the running product (synthesis at [`docs/research/audit-2026-05-23/synthesis.md`](../../research/audit-2026-05-23/synthesis.md)). **The single most consistent finding across all 8 lenses:** structure is right, calibration is missing. Calculators that read but don't write the new fields. CSS tokens defined but not applied. Privacy notice pointing at a possibly-unreachable email. Gateway chains that work but aren't observed. The same pattern S11 closed for visual (tokens defined since S07, never wired into CSS until #142) — now repeating in 4-5 other layers.

The goal addresses the **four highest-confidence gaps** from the audit:

1. **Trust** — multi-currency calculators (Lucía + Esther) may show dashboard numbers that don't match a Mexican investor's broker statement. P0 blocker for any future invite.
2. **Safety** — invite-code flow has a race condition + enumeration leak + no expiration (Fadia + Olusegun). P0 before cohort grows from 1 to 5.
3. **Visibility** — zero data on whether the beta amigo even clicked the invite, let alone used any feature (Olusegun + Esther). Every S13+ scope decision is currently a guess.
4. **Compliance** — published privacy notice must route to a real human (Ileana). P0 legal.

Plus the **carry-over polish** the audit unanimously called out: finish the Lumen migration that S11 #142 started (Renata: 60% done), wire Banxico FX as the authoritative MXN source (Lucía + Adriana), and one research deliverable Adrian asked for directly: data-source health audit + TradingView free widgets evaluation.

**What this unblocks:**
- Adrian can invite cohort #2 (5 amigos) from a position of confidence — dashboard numbers honest, invite flow secure
- Adrian can *measure* what cohort #2 does — UserActivity + Resend webhooks turn silence from inscrutable to diagnosable
- Sync failures wake Adrian up via Sentry instead of via amigo support messages
- Brand audits stop re-finding the same Lumen drift
- Next sprint scope decisions become evidence-based instead of guess-based

**Critical context:** First beta amigo invited 2026-05-21 with zero response in 48h. Adrian decided to ship this audit-driven sprint *during* that silence rather than wait, on the bet that the work needed to convert "silence" into "actionable data" is the same work needed to scale to 5 amigos.

---

## What's NOT in this sprint (anti-scope)

Deliberately excluded:

- **Implementation of TradingView widgets** — the research issue (#177) evaluates them. Implementation lands in S13 if research recommends it.
- **Bitso / El Economista / new data-source integrations** — covered in the research issue's recommendations; implementation in S13+.
- **Admin AuditLog UI** (Fadia P2) — capture is in place; the read-side UI can wait until there's enough data to be worth visualizing.
- **Performance indexes + Solid Queue tuning** (Yui P2) — defer to S13. No real load yet to justify.
- **"Export my data" ARCO Acceso flow** (Ileana P1) — defer to S13. "Delete my account" #176 covers the more urgent Cancelación right.
- **Cookies disclosure update + Resend DPA filing** (Ileana P3) — pure docs; bundle into next privacy review.
- **Kill JTBD #2 drawdown alerts** (Esther) — Adrian's call whether to actually deprecate, not in audit-driven sprint scope.
- **Second-cohort beta invite** — happens *after* this sprint closes, once trust/safety/visibility are in place.

---

## 24h-pause rule note

S11 closed 2026-05-22. S12 opens 2026-05-23 — **24h-pause rule overridden** by Adrian's explicit decision. Counter status:

- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden
- S09→S10: respected
- S10→S11: respected
- S11→S12: **overridden** (today, Adrian's call after audit completed in same window)

Per S07 commitment: two *consecutive* overrides would invalidate the rule. The pattern so far is one override followed by two respects — the rule holds. The override here is justified by the audit's urgency (P0 trust + security findings), not momentum-without-need.
