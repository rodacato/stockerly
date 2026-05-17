---
name: parallel-research-workflow
description: "Validated pattern for spending idle Claude weekly budget on parallel research agents whose outputs feed future sprints, ADRs, or get discarded. First applied 2026-05-17."
metadata: 
  node_type: memory
  type: project
  originSessionId: 55a739cb-5ada-48ba-99b9-3535be8620ae
---

# Parallel Research Workflow

**First validated:** 2026-05-17 (Stockerly idle weekly budget run). 8 parallel agents → 4 audits + 4 content/product reports + 1 cross-synthesis. Output: 9 files in `.research/`, 5 S08 candidates, 3 anti-features, ~10-12 day path to beta-ready identified. Several correctness bugs surfaced (TakeSnapshotsJob currency-mix, Notification.create! bypass, legal/terms placeholder with NY jurisdiction + false product claims, F-01 encryption-key fallback).

**Why:** With Claude Max (5x) plan, weekly quota often has 80%+ unused budget mid-week. Read-only research and audits cost tokens but no user time and no production risk — ideal use of slack.

**How to apply:** When Adrian flags idle budget + time available, propose this workflow. Recommended pattern:

1. **Setup.** Create `.research/` folder (gitignored via `/.research/` line in `.gitignore`) + README with index + status log. Each agent writes a `.md` there.
2. **Mixed delivery** (Adrian's preference): each agent writes full report to file AND returns a chat-ready executive summary (≤250-300 words). Avoids context bloat while keeping action-ready summaries in chat.
3. **Tracks to offer** — group into buckets to fit AskUserQuestion's 4-option max:
   - Technical audits (security / performance / test coverage / architecture drift)
   - Content/product research (instruments / competitors / educational primers / compliance)
4. **Expert panel feedback mandatory** — every agent consults 2-3 relevant experts from `docs/research/experts.md` in the experts' voice. Adrian explicitly asked for this; it makes reports actionable instead of academic.
5. **Web permissions:** `WebSearch` and `WebFetch` need to be in allow-list for any agent that researches external content (rates, regulations, competitors). Add to `.claude/settings.local.json` (gitignored). **Re-run agents that failed or ran offline** if their content was time-sensitive — first offline run of compliance missed NEW LFPDPPP (2025) and INAI extinction; re-run with web caught both.
6. **Synthesis pass.** Once all reports complete, dispatch one final agent to cross-synthesize: overlaps, contradictions, S08/S09 candidates as discovery cards (trigger + JTBD + metric + DoD + effort + risk), anti-features, ADRs to write, open questions for Adrian. This is where the workflow earns its keep — without synthesis, 8 reports = 8 inboxes.
7. **README index.** Keep `.research/README.md` updated with: "🎯 Start here" pointing at SYNTHESIS, then audits and research sections, plus status log of re-runs / changes. The synthesis is the entry point, not the individual reports.

**Calibration learned:**
- Audits take ~5-7 min each (running RSpec / Brakeman / bundler-audit).
- Web-enabled research takes ~10-15 min each.
- Synthesis takes ~5-6 min (reads 4 markdowns + 30K tokens of context).
- Total wall-clock for 8 + synthesis: ~45 min.
- Token cost concentrates in audits (large code-reading) and synthesis (reads 4 reports). Plan for ~150K-200K tokens for the whole pass.

**Anti-pattern to avoid:**
- Don't dispatch agents serially "to be safe" — burns wall-clock without saving tokens.
- Don't ask the agent for "everything you can find" — give them sharp scope + expert panel + executive summary length cap.
- Don't skip web permissions for time-sensitive content. The offline-then-web re-run cost is justified by the structural reforms that get missed (e.g., new laws, extinct agencies, current rates).

**Related:** [[project_working_method]] for sprint protocol; [[project_expert_panel_v2]] for which experts each agent should consult; [[feedback_brutal_honesty]] for tone of expert callouts.
