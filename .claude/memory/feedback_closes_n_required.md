---
name: closes-n-required-in-pr-bodies
description: "Every PR that resolves a GitHub issue MUST include `Closes #<N>` in its body so GitHub auto-closes the issue on merge. Mandate this explicitly in agent prompts. Captured after S10 left 3 stale issues that needed manual cleanup at S11 open."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2ce9215a-f992-4457-9430-cd525f774f65
---

**Rule:** Every PR body MUST include `Closes #<N>` (or `Fixes #<N>` / `Resolves #<N>` — all equivalent) for each issue it resolves. This is non-negotiable when delegating PR creation to subagents.

**Why:** S10 closed with 3 stale issues (#93, #94, #125) still open because the merging PRs forgot the `Closes #N` keyword. Cleanup happened at S11 open — manual `gh issue close` for each one with a comment explaining the merge. This polluted the open-issue list during the sprint window and made it harder to confirm "scope is terminal" at close. S11 prompts emphasized `Closes #N` explicitly and **all 6 Wave 2 PRs + Wave 3 used it correctly → zero stale issues at S11 close**.

**How to apply:**

1. **In agent prompts:** when delegating PR creation, the prompt MUST include a literal line like:
   > "Your PR body MUST include `Closes #<N>` where N is the issue number you're resolving. This is required so GitHub auto-closes the issue on merge — do NOT omit it."
2. **In the canonical PR template** (mental, not committed): the `## Summary` section's first sentence is "Closes #N." — make it the very first content.
3. **At sprint close:** during the QA audit pass, before writing `qa.md`, run `gh issue list --state open --json number,title` and cross-check against `scope.md`. If any scope item is still open with a merged PR, that's a `Closes #N` miss — manually close with a comment pointing at the merge SHA.
4. **For PRs that touch multiple issues:** repeat — `Closes #N` `Closes #M` (on separate lines or same line, GitHub parses both).

**What "Closes #N" does and doesn't do:**
- It only fires on merge to the **default branch** (master). PRs against feature branches or merged elsewhere don't auto-close.
- It only fires for `close / closes / closed / fix / fixes / fixed / resolve / resolves / resolved`. Other variants (`closing / fixing / resolving`, "addresses", "for") do NOT auto-close.
- It works in PR body OR merge commit message. Easiest path: PR body.

**Cost of getting this wrong:** every miss adds a manual `gh issue close` + a confused moment at the next sprint open ("wait, didn't we ship this?"). At scale (S10's 3 misses across ~14 PRs = ~20% miss rate without explicit mandate) it makes the sprint-close audit unreliable.

Related: [[design-workflow]] (canonical PR pattern), [[pr-review-workflow]] (when handling bot feedback, don't lose the `Closes #N` line on rebases).
