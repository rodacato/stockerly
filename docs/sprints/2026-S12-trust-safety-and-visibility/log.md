# Log — Sprint S12 (trust-safety-and-visibility)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-23 — Sprint opening: 24h-pause rule overridden

S11 closed 2026-05-22. S12 opens same day as audit (2026-05-23) — **24h-pause rule overridden** by Adrian's explicit decision. Counter status:

- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden
- S09→S10: respected
- S10→S11: respected
- S11→S12: **overridden** (today)

3rd override of 7 transitions. Per S07 commitment, two *consecutive* overrides invalidate. We have 2 respects then 1 override — rule holds. Override justified by audit's urgency (P0 trust + safety + legal findings), not momentum-without-need.

---

## 2026-05-23 — Audit + sprint open in the same window

Same-day sequence:
1. PR #162 merged (post-S11 brand-glyph fix Adrian flagged after a manual browser audit)
2. Adrian asked: "what we have, what delivers value, what's missing, what doesn't work — with help from the experts"
3. Launched 8 expert audits in parallel via Explore subagents:
   - C1 Lucía (MX financial domain)
   - C5 Renata (UX/UI fintech)
   - C6 Esther (JTBD value)
   - C7 Fadia (security)
   - S1 Olusegun (observability)
   - S2 Adriana (data sources)
   - S3 Yui (performance)
   - S5 Ileana (legal/compliance MX)
4. All 8 returned within ~10 min of each other (~3 min compute each on parallel infra)
5. Saved 8 reports + wrote `synthesis.md` + `S12-proposal.md` under `docs/research/audit-2026-05-23/`
6. Adrian chose Shape A (10 issues) + override 24h-pause + add data-source/TradingView research issue
7. Filed 10 issues #168-#177 + this sprint folder + this log

**Total wall-clock** for audit → scope-locked: ~90 min. Validates the parallel-research workflow at sprint-planning scale (not just for one-off audits).

---

## 2026-05-23 — Initial scope set

10 main issues + #150 reactive (carried from S11). Adrian chose Large scope explicitly knowing it echoes the S11 over-delivery anti-pattern. Rationale: each issue is bounded, audit-derived, and clusters into 4 waves with parallel-agent potential.

**Wave sequencing:**
- Wave 1: #168 (calculators) + #169 (support email) — P0 trust + legal, sequential
- Wave 2: #170 (invite-code hardening) — P0 safety, can run parallel to Wave 1
- Wave 3: #171 (UserActivity) + #172 (Resend webhooks) + #173 (sync alerts) — 3 parallel agents
- Wave 4: #174 (Lumen polish) + #175 (Banxico FX) + #176 (account deletion) + #177 (data-source research, read-only) — 4 parallel agents
- Wave 5: close

**The override + Large + audit-driven combination** is intentional: the audit identified specific gaps with concrete evidence and small effort estimates. Closing them all in one sprint is cheaper than spreading them across S12-S14 individually. If beta amigo feedback arrives mid-sprint and demands different scope, #150 absorbs the disruption.

---

## 2026-05-23 — Key audit findings driving scope

From [`docs/research/audit-2026-05-23/synthesis.md`](../../research/audit-2026-05-23/synthesis.md):

The cross-cutting finding (7 of 8 experts converged): **structure is right, calibration is missing**. Same shape as S11's Lumen finding (tokens defined, never wired), now repeating in 4-5 layers:
- Multi-currency calculators (Lucía + Esther): may not be using `fx_rate_at_execution` field that's been captured for 4 sprints
- Lumen CSS (Renata): ~60% migrated; cards/sidebars/auth/donut still pre-Lumen
- Invite-code flow (Fadia + Olusegun): race + enumeration + no expiration + no click tracking
- Privacy notice (Ileana): published, but the support email may not be monitored
- Gateway chains (Adriana): work, but no proactive observability

**Adrian's stated direction beyond the audit:** "Stockerly will be my principal site for informed decisions, so I want to polish + integrate other sources or analysis." This led to issue #177 — research-only audit of all 10 current providers (which jal, which don't, alternatives) + evaluation of TradingView free widgets as a candidate augmentation. Implementation deferred to S13 based on research findings.
