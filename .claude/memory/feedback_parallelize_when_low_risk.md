---
name: parallelize-independent-work-when-conflict-risk-is-low
description: "When a sprint contains multiple mechanical, well-spec'd tasks that touch disjoint files (or only touch the same file in non-overlapping regions), launch them as parallel Agents in worktrees instead of doing them sequentially. Confirmed 2026-05-18 after S08 retro."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 304a846f-9186-4678-bff5-d986163ce3f1
---

**Rule:** If a batch of tasks fits all of these conditions, parallelize them. Otherwise, sequential.

| Condition | Why it matters |
|---|---|
| Each task has a clear, well-defined discovery card (no major decisions pending) | Parallel agents can't pause to ask — they need full specs |
| Tasks touch disjoint files, OR touch the same file in non-overlapping regions (different methods, different sections, different test blocks) | Conflicts at rebase must be trivial to resolve |
| Risk per task is low — no shared schema migrations interacting, no shared service contracts changing | Failure of one shouldn't cascade |
| The benefit (wall-clock saved) exceeds the rebase overhead | Don't parallelize 3 × 5-min tasks |

**Why:** Confirmed 2026-05-18 after S08. The sprint had 6 issues; 4 of them (#105 C1, #102 Terms, #103 Risk, #104 Privacy) were independent enough to parallelize:

- #105 was 100% disjoint (jobs + models + spec/jobs).
- #102 + #103 + #104 all touched `app/controllers/legal_controller.rb` (3 different actions) and `spec/requests/legal_spec.rb` (3 different `describe` blocks) — trivially mergeable.

I did all 6 sequentially. Adrian's note: *"se podian trabajar en paralelo?"* — yes, four of them, and it would have saved ~40-50 min wall-clock. The remaining two (#95 login, #96 register) shared cross-cutting system specs and visual-coherence concerns, so sequential was the right call for those.

**How to apply:**

1. After scope is finalized in `docs/sprints/.../scope.md`, look at the file list each issue touches.
2. Group issues into:
   - **Cluster A — parallelize**: disjoint files, or same-file non-overlapping regions.
   - **Cluster B — sequential**: cross-cutting specs, shared visual idioms, layered dependencies (e.g. #96 reads `/login` toggle copy from #95).
3. For cluster A, launch one Agent per issue in `isolation: "worktree"`. Brief each agent with the discovery card + relevant existing patterns + explicit instructions to push a branch and open a PR — but NOT to merge.
4. After agents return, rebase the PRs in dependency order; resolve trivial conflicts.
5. For cluster B, do them sequentially as before.

**What NOT to parallelize even if files are disjoint:**
- Tasks where one outcome shapes the other's design decisions (e.g. login + register should land the same toggle pill — sequential keeps them coherent).
- Tasks that share a cross-cutting system spec (`navigation_spec.rb` is the canonical hot spot).
- Tasks where you're not confident in the discovery card. Parallel agents amplify bad specs into bad implementations × N.

**Cost of getting this wrong:** parallel work with high conflict risk → merge hell, rework, and the user ends up reviewing PRs that step on each other.
