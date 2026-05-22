# Stockerly Memory Index

> Persistent memory for future conversations. One line per entry. Edit individual files; only modify this index when adding/removing entries.

## User
- [Adrian profile](user_adrian.md) — MX investor, MXN+USD portfolio, demands brutal honesty

## Project
- [Vision & audience](project_vision.md) — North star + beta cerrada B+ (≤20 invited friends), decided 2026-05-14
- [Decision: fix not rewrite](project_decision.md) — Commitment + P0 multi-currency bug blocker for beta invites
- [Working method](project_working_method.md) — GitHub Issues/Projects + docs/ split, sprint protocol, discovery cards required
- [Expert panel v2](project_expert_panel_v2.md) — 8 Core + 8 Situational with names; canonical doc at docs/research/experts.md
- [Design assets](project_design_assets.md) — External mockups live in .local/design-mockups/ (gitignored); Lumen palette is source of truth; current batch Stockerly-1.0 for S07
- [Design workflow](project_design_workflow.md) — Canonical visual-design workflow validated at S07 close (5 screens, zero regenerations); promoted from WIP
- [Parallel research workflow](project_parallel_research_workflow.md) — Validated 2026-05-17: spend idle weekly budget on 8 parallel agents → audits + content/product research → cross-synthesis. ~45min, ~150-200K tokens.

## Feedback
- [Brutal honesty mandate](feedback_brutal_honesty.md) — Adrian's explicit ask, applies to all responses
- [My anti-patterns](feedback_anti_patterns.md) — 7 enforcement targets from 22-phase retrospective
- [No co-author attribution](feedback_no_coauthor.md) — Never add Co-Authored-By or AI attribution to commits/issues/PRs
- [Three-layer language rule](feedback_repo_language_english.md) — Chat es / repo en / UI es-MX. No i18n infra today — hardcoded es-MX is the explicit convention.
- [Readable code, minimal comments](feedback_readable_code.md) — Self-explanatory code first; comments only for non-obvious why, one short line
- [PR review workflow](feedback_pr_review_workflow.md) — When asked to handle PR feedback, run the full Gemini-review loop (fetch → triage → fix → CI → push → reply inline) without asking for steps
- [Protect master](feedback_protect_master.md) — Never push directly to master / never bypass branch protection. Use explicit refspec on push. Captured after 2026-05-16 incident on #81.
- [Parallelize low-risk work](feedback_parallelize_when_low_risk.md) — When sprint has disjoint, well-spec'd tasks, launch parallel Agents in worktrees instead of sequential. Captured after S08 retro 2026-05-18.
- [Closes #N required](feedback_closes_n_required.md) — Every PR body MUST include `Closes #<N>` so GitHub auto-closes. Mandate explicitly in agent prompts. Captured after S10 left 3 stale issues; S11 fix proved it works.
