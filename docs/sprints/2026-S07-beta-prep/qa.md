# QA Pass — Sprint S07 (beta-prep)

> Mandatory checklist BEFORE writing `retro.md` and closing the sprint.
> Filled at sprint close on 2026-05-16.

---

## Goal & scope

- [x] **Sprint goal achieved.** The 5 scoped items all shipped: LFPDPPP rewrite (#73), invite-by-code (#74), beta support runbook (#78), TrendScore enum rename (#70), and onboarding (#77 — `/welcome` + `/help` + `/report-bug` + `BugReportMailer`).
- [x] **All `main` scope issues** are closed (5/5).
- [x] **Parallel issues** — N/A; S07 had zero parallel-labeled items.
- [x] **Unclosed issues** — none. Milestone has `open_issues: 0, closed_issues: 5`.

## Code health

- [x] `bundle exec rspec` — **2248 examples, 0 failures** (line coverage 94.67%, branch coverage 76.84%)
- [x] `bin/rubocop` — **818 files inspected, no offenses detected**
- [x] `bin/brakeman` — **Models: 33, Templates: 134, Errors: 0, Security Warnings: 0**
- [x] `bin/bundler-audit` — **No vulnerabilities found**
- [x] CI on GitHub Actions — green across all 7 merged sprint PRs
- [x] Working tree clean post-close

## Vision compliance

- [x] **Manual audit of new copy in views** — `script/audit-entropy.sh` returns `adr001_violations_in_views: 0`. New es-MX copy in `/privacy`, `/welcome`, `/help`, `/report-bug`, `/admin/invites` is descriptive, not prescriptive (per ADR-001).
- [x] **Manual scope audit** — No new features violate non-goals. `/welcome` + `/help` + `/report-bug` are operational, not feature surface. Invite-by-code is access control, not fiscal/trading. TrendScore rename is internal cleanup.
- [x] **JTBD mapping** — Sprint was operational/compliance-focused; no direct JTBD added. Indirectly unblocks all 6 canonical JTBDs by enabling the first invite to real beta users.
- [x] **Each issue's discovery card was fulfilled** — DoD checklists verified across the 5 closed issues. Two documented architectural deviations from the cards (both in #74 and #77, recorded in commit messages + PR bodies):
  - #74: `GenerateInviteCode` moved from `Identity::` to `Administration::` (matches admin/users pattern)
  - #74: No separate `ConsumeInviteCode` use case; consumption integrated into `Register` in a single transaction
  - #77: Replaced existing `OnboardingController` wizard with `/welcome` (Adrian's conscious approval recorded mid-sprint)

## Documentation

- [x] **New ADR** — none required. The two architectural deviations in #74 were small enough to document inline in PR/commit (admin context placement; single-use-case transaction). The bigger wizard-replacement in #77 is documented in `log.md` and the commit message.
- [x] **Vision update** — none. Audience/scope unchanged.
- [x] **Design docs** — `docs/design/` unchanged. The mockup batch `Stockerly-1.0` is gitignored under `.local/` per `project_design_assets.md`. Brand kit honored across all 5 implementations (Lumen palette, Plus Jakarta Sans + Inter + JetBrains Mono, descriptive voice).
- [ ] **Screenshots regenerated** — pending. `docs/screenshots/` not updated this sprint (visual changes were verifiable in mockups + manual smoke).
- [x] **CLAUDE.md / IDENTITY.md / memory** — three new memory entries added: `project_design_assets`, `project_design_workflow_wip`, `feedback_protect_master`. Memory index `MEMORY.md` reflects all three.

## GitHub hygiene

- [x] **Closed issues** have `Done` status (via auto-close on PR merge).
- [x] **Milestone ready to close** — 5/5 issues in terminal state.
- [x] **No orphan issues** in the sprint without a status.

## Usage metric (post-close verification)

| JTBD | Expected metric | State |
|---|---|---|
| N/A — operational sprint, no JTBD directo | "Primer amigo invitado y registrado en beta cerrada" | ⚠️ **pending — depends on Adrian sending the first invite post-close** |

## Beta-prep specific checks

- [x] **LFPDPPP notice accesible** — `/privacy` rewritten in es-MX, linked from footer (public + auth layouts) and `/register` agreement text. Cumple Art. 16 LFPDPPP (7 sections).
- [x] **Invite code flow end-to-end** — Admin can generate at `/admin/invites`, code is hex 12 chars formatted with hyphens, `/register` requires + consumes atomically, race condition handled via `InviteCode.lock.find_by(...)`, used codes show as `Canjeado` in history. Verified by integration spec.
- [x] **Onboarding visible en primer login post-registro** — `AuthenticatedController#redirect_to_onboarding` sends non-onboarded users to `welcome_path`. Verified by `spec/requests/welcome_spec.rb` and `spec/system/navigation_spec.rb`.
- [x] **Runbook ejercitable** — `docs/ops/beta-support.md` has a §4 end-to-end exercise. Not yet exercised against a real bug report — pending first real reporter post-close.

## Additional notes

**Audit-entropy delta from S06 close → S07 close:**

| Metric | S06 close | S07 close | Δ |
|---|---|---|---|
| Cross-context leaks | 5 | 5 | 0 (no change — ADR-005 future) |
| Hardcoded USD literals | 8 | 8 | 0 (not touched this sprint) |
| ADR-001 violations in views | 0 | 0 | 0 (held the line) |
| Bloated docs (>200 lines) | 11 | 13 | **+2** (added `docs/ops/beta-support.md` 253 lines for #78; `docs/design/brand-kit-portable.md` already there) — acceptable, operational doc |
| TODO/FIXME markers | 2 | 2 | 0 |
| Hardcoded color classes in views | 62 | **59** | **−3** (side effect of removing the slate-heavy wizard views in #77) |

**Side-effect axis #2 (Zero prescriptive copy) and axis #6 (Docs reflect code) both nudged forward** despite S07 being operational. Replacing the wizard removed pre-Lumen residue and aspirational "You're all set! 🎉" copy.

**Two automatic dependency PRs** (Faraday 2.14.2, Puma 8.0.1) remained open across the sprint — not S07 scope, not blocking close.
