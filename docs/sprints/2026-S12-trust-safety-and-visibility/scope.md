# Scope — Sprint S12 (trust-safety-and-visibility)

> Issues assigned to this sprint. State-ful work lives in GitHub (Milestone + Project); here just the initial snapshot + brief reason per issue.

---

## Main work

**10 issues.** Wave sequencing matters: Waves 1 + 2 ship first (P0 trust + safety + legal). Wave 3 ships the instrumentation that makes Waves 1-4 measurable from cohort #2 onward. Wave 4 is the polish + completion sweep.

| # | Title | JTBD / Source | Discovery card OK? |
|---|---|---|---|
| #168 | Audit multi-currency calculators against trade fx_rate_at_execution | JTBD #1 (consolidated patrimony in MXN) · C1 + C6 audit | ✅ |
| #169 | Confirm support@notdefined.dev is monitored + alias documented | Compliance (LFPDPPP Art. 32) · S5 audit | ✅ |
| #170 | Harden InviteCode flow — enumeration + expiration (race-condition finding retracted post-review) | Beta invite safety · C7 + S1 audit | ✅ |
| #172 | UserActivity table + event subscriptions for feature usage | Decision-making capacity · C6 + S1 audit | ✅ |
| #173 | CheckSyncHealthJob — proactive Sentry alert on stale syncs | Operational visibility · S1 audit | ✅ |
| #179 | Resend webhooks → EmailEvent table (invite delivery tracking) | Beta-cohort observability · S1 audit | ✅ |
| #174 | Lumen migration completion — cards/sidebars/auth/allocation donut | Visual coherence · C5 audit | ✅ |
| #175 | [research] Data sources deep-dive + TradingView free widgets evaluation | Data strategy · Adrian direction + S2 audit | ✅ |
| #176 | In-app account deletion (ARCO Cancelación) | LFPDPPP Art. 19 · S5 audit | ✅ |
| #177 | Banxico FX (TC_TC002) as primary USD/MXN source | Trust differentiator MX · C1 + S2 audit | ✅ |

> **Issue numbering note:** The parallel `gh issue create` batch on 2026-05-23 returned issue numbers out of input order. A subsequent `gh issue edit 170` (to apply gemini's race-condition retraction from PR #178 review) accidentally overwrote what turned out to be the Resend webhooks issue. Cleanup: #171 closed as duplicate invite; Resend re-filed as #179. The 10-issue scope is preserved.

**Total estimated raw effort:** ~20-30h (~12-18h actual with parallel-agent compression per S08-S11 calibration ~0.4-0.6×)

## Parallel work (max 30% effort)

| # | Title | Parallel axis | Discovery card OK? |
|---|---|---|---|
| #150 | S11 reactive bucket → S12 (continuing reactive channel) | ops / beta amigo feedback | ✅ |

**Parallel effort:** #150 reserves 3-5h, flexes with beta amigo response volume. Carries open from S11; no new issue needed.

---

## Rules verified at opening

- [x] Each issue has a complete discovery card — 10/10 filed 2026-05-23 with audit-derived discovery
- [x] Total `In Progress` issues ≤ 7 (hard rule) — 0 currently; max 4-6 during sprint depending on parallel-agent batches
- [x] Parallel ≤ 30% of total estimated effort — #150 reserve is ~15% of estimated effort; well inside cap
- [x] `GOAL.md` goal is covered by the selected issues — trust (#168 + #177), safety (#170), visibility (#172 + #173 + #179), compliance (#169 + #176), polish (#174), research carry (#175)
- [x] `blocked` issues have their dependency identified — none; all 10 main issues are independent except #176 (in-app deletion) which is conceptually adjacent to #169 (support email) but neither blocks the other

---

## Discovery-card audit applied at sprint open

Carry-over discipline from S07-S11. Findings to verify at start of each issue:

- **#168 (calculators):** Lucía's scenario in the issue body MUST be reproducible as a spec before fixing. Spec-first audit; if scenario passes already, partial credit — find a scenario where it doesn't.
- **#169 (support email):** Confirm Adrian owns `notdefined.dev` MX/DNS records (he does; serves `stockerly.notdefined.dev`). Test the alias roundtrip end-to-end before closing.
- **#170 (invite-code):** Race-condition portion withdrawn (gemini-code-assist review of PR #178 caught false positive — `Register#persist_with_invite` already uses `ActiveRecord::Base.transaction` + `InviteCode.lock.find_by`, which is `SELECT ... FOR UPDATE`, textbook pessimistic locking). Scope reduced to enumeration normalization + expiration timestamp (~1.5h instead of ~3h). Audit doc updated in `docs/research/audit-2026-05-23/C7-fadia-security.md` §"What's missing #1".
- **#172 (UserActivity):** Avoid double-counting on Turbo Frame requests. Use `ActiveSupport::Notifications` or controller `after_action` filtered to `format.html`. Don't subscribe to every domain event blindly — pick the 6-8 actions that map to JTBDs.
- **#179 (Resend webhooks):** Resend signature verification is non-negotiable. Test with both valid and invalid signatures.
- **#173 (CheckSyncHealthJob):** Dedup via Solid Cache to prevent alert storms.
- **#174 (Lumen polish):** Spot-check after grep — search-and-replace can miss interpolations. Visual browser pass before merge.
- **#177 (Banxico FX):** Banxico SIE returns null on weekends/holidays. Handle gracefully — fall back to exchangerate-api.
- **#176 (account deletion):** Hard-delete vs soft-delete: docs/ops/arco-procedure.md says "30 days for deletion". Use soft-delete (timestamp) + recurring job for hard-delete after 30d.
- **#175 (research):** Read-only. No code changes. Output is the markdown deliverable + S13 issue candidates.

---

## Sprint sequence (suggested)

**Wave 1 — P0 trust + legal (Day 1, sequential):**
1. **#168** Calculators audit — Adrian does this himself in main thread (it's an audit; needs domain understanding)
2. **#169** Support email confirmation — 15 min check; can be done in parallel with #168

**Wave 2 — P0 invite safety (Day 1-2):**
3. **#170** Invite-code hardening — single agent, ~3h. Can launch parallel to Wave 1 since files are disjoint.

**Wave 3 — P0 visibility (Day 2-3, parallel agents):**
4. Launch 3 parallel agents in worktrees:
   - **#179** Resend webhooks
   - **#172** UserActivity
   - **#173** Sync health alerting
5. All 3 ship as separate PRs

**Wave 4 — P1 polish + research (Day 3-4, parallel agents):**
6. Launch 3 parallel agents in worktrees:
   - **#177** Banxico FX gateway
   - **#174** Lumen polish sweep
   - **#176** In-app deletion flow
7. Launch #175 research issue as a 4th read-only Explore agent (no worktree needed)
8. All ship as separate PRs (research = one doc PR)

**Wave 5 — Close (Day 4-5):**
9. Audit pass + qa + retro + close

**Throughout:** #150 reactive bucket absorbs beta amigo feedback if it arrives.

---

## Deferred (out of S12 scope, candidates for S13)

- Implementation of TradingView widgets (depends on #175 research outcome)
- New data-source integrations (Bitso BTC/MXN, El Economista, etc. — depends on #175)
- Admin AuditLog viewer UI (Fadia P2)
- Performance indexes + Solid Queue worker tuning (Yui P2)
- ARCO Acceso (export my data) flow (Ileana P1, next sprint)
- Cookies disclosure update + Resend DPA filing (Ileana P3)
- Polygon news gateway cleanup (Adriana — bundle into #175's implementation phase)
- Bug-report mailer reply-to masking (Ileana P3)
- Kill JTBD #2 drawdown alerts (Esther's recommendation — Adrian's call)
- Remember-me token IP/UA enforcement (Fadia P2)
- Disk space monitor in /health (Olusegun P2 — bundle with future Kamal/ops sprint)

---

## Risks and mitigations

- **#168 calculator audit balloons** if more calculators are wrong than Lucía's audit suggested. Mitigation: if effort exceeds 8h, split into "audit-only" PR (this sprint) + "fix per-calculator" PRs (S13). Document findings in `docs/research/audit-2026-05-23/calculators-followup.md`.
- **Wave 3 parallel agents conflict** on shared files (event subscriptions, base controller). Mitigation: pre-stage `config/initializers/event_subscriptions.rb` edits in main thread before launching agents; brief each agent on the specific files it owns.
- **Beta amigo replies mid-sprint** with critical bug. Mitigation: #150 reserve bucket. If reserve exhausts, scope-cut on #176 (in-app deletion) first per Adrian's stated descope priority.
- **#175 research surfaces a P0 finding** (e.g., a critical provider is down 50% of the time). Mitigation: file as S13 P0 issue immediately; don't disrupt S12 unless beta-amigo-blocking.
- **Large scope (10 main + reactive) repeats S11 over-delivery anti-pattern.** Adrian explicitly chose this size at sprint open knowing this, tied to audit findings (not feature creep). Tracking goal at retro: did we close 10/10, or did we close 7/10 + descope cleanly?
