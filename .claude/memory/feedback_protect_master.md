---
name: protect-master
description: Never push directly to master/main; never bypass branch protection. Every change to master goes through a Pull Request with CI and review.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 449ed44b-ae1c-4450-aa46-301f14b8eb2c
---

Never push directly to master/main, never bypass branch protection rules. Every change to master must go through a Pull Request — CI runs, review happens, only then merge.

**Why:** 2026-05-16 — While creating a branch from master for the Claude Design handoff bundle (issue #81), I ran `git checkout -b BRANCH origin/master`. That set the new local branch's upstream to `origin/master`. The follow-up `git push -u origin BRANCH` resolved the push destination against that upstream config and pushed the local branch's commits directly to remote `master`, bypassing the PR-required branch protection (Adrian's admin permissions allowed the bypass). The output showed `BRANCH -> master` and `Bypassed rule violations for refs/heads/master: Changes must be made through a pull request.` Files were content-correct, but no CI ran, no review happened, and the workflow was violated. `CLAUDE.md` explicitly prohibits force-pushing to master without explicit approval and treats branch protection as inviolable.

**How to apply:**
- When creating a branch for a PR, use `git checkout -b BRANCH master` (no `origin/` prefix), so the new branch has no preset upstream.
- On first push, use an explicit refspec: `git push -u origin BRANCH:BRANCH` — never rely on upstream-config resolution to pick the destination.
- Treat `BRANCH -> master` in a push output and any `Bypassed rule violations` warning as hard failures. Stop immediately, do not chain further git actions, and surface the incident to Adrian.
- If a direct-to-master push has already happened, do NOT attempt to undo via force-push without explicit approval — contents are already in clones / CI history and the recovery decision belongs to Adrian.
- Treat this rule as load-bearing for all repositories that have branch protection, not just Stockerly.

Related: [[stockerly-working-method]] (GitHub Issues + PR flow), [[pr-review-workflow]] (review handling).
