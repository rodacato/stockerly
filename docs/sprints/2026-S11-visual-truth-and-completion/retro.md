# Retro — Sprint S11 (visual-truth-and-completion)

> Honest post-mortem. Without retro, the sprint does NOT close (hard rule of the protocol).
>
> **Close date:** 2026-05-22
> **Actual duration:** 1 day (vs estimated: 4-5 days)
> **Goal:** Close the visual-truth gap discovered at S10 close (Lumen palette never applied to `application.css`) and finish the 3 deferred Stockerly-2.0 surfaces (dashboard sidebar, profile 2-col, password recovery) so the product Adrian invited a beta amigo to on 2026-05-21 stops *claiming* Lumen and *actually renders* Lumen.

---

## What worked?

- **"Large with discipline" sprint sizing.** Adrian chose Large (8 main + 1 reactive) at open knowing it echoed S10's over-delivery anti-pattern. The difference this time: every item was a bounded follow-up (not greenfield), every PR used `Closes #N` correctly, and the wave sequencing was decided at open instead of accreted in flight. Shipped exactly 8/8 + the planned #140 carryover, no scope balloons.
- **Sequencing #142 first as foundation.** Wave 1 took ~30 minutes (one ~120-LoC CSS file), but doing it before Wave 2 launched meant every parallel agent compounded on the correct chrome. If we'd flipped the order, each Wave 2 PR would have either (a) re-papered over wrong tokens or (b) collided with #142 on rebase. Sequencing was free; not sequencing would have cost rework.
- **Parallel-agent pattern (3rd sprint validated).** Wave 2 launched 2 agents in worktrees, each shipping 3 PRs. Agent A: #143 dashboard / #144 asset Ficha / #148 statements. Agent B: #145 trades / #146 profile / #147 password recovery. All 6 shipped CI-green with bot reviews handled in <2h end-to-end. Pattern is now boring (in a good way) — fits the canonical workflow.
- **`Closes #N` discipline fixed.** S10's gap (3 stale issues needed manual cleanup) explicitly went into S11 agent prompts. All 6 Wave 2 PRs + #149 used `Closes #N` correctly — zero stale issues at this close.
- **#140 + #142 as a coherent S11 opening.** Brand asset SVG refresh + Lumen CSS migration shipped within hours of each other. Together they close the two highest-visibility brand-quality gaps simultaneously, making the visual jump from "claimed Lumen" to "rendered Lumen" feel like one coherent moment instead of a creeping 5-sprint drift correction.
- **Audit-then-act on #149.** The bug-report mailer audit found the body + layout were already correct from #124 work; only the subject string was English. Result: a 2-line code fix + 1 spec change + 1 regression spec, instead of speculating about a "big mailer rewrite" that wasn't needed.

## What didn't work?

- **Beta amigo silence.** The 2026-05-21 invite (sent between S10 close and S11 open) has produced zero feedback in the 24h since. #150 reactive bucket received zero items. This was anticipated ("expected to take days") but it means S11's 8 design completions ship as theory — we're calibrating on mockup parity, not actual use. The structural metric checkboxes in `qa.md` are ✅; the usage metric checkboxes are still ⚠️ pending the same blocker S10 had.
- **Wave 2 worktree gotcha recurred on Agent A's first file write.** The S10 retro flagged this and S11 prompts had explicit "use absolute paths starting with worktree root" language. Agent A still wrote to the main checkout on the first file, recovered via `cp` within minutes. The mitigation worked (recovery was fast) but the prompt language clearly isn't strong enough to prevent the first-write slip. **Followup:** strengthen the prompt template — possibly add a "before any Write tool call, confirm the absolute path matches the worktree root" instruction.
- **The Lumen drift took 5 sprints to surface.** #142 was a one-file ~30-LoC change. If S07 had done an audit-pass after merging the first design pass, this would have been caught immediately. The "structurally-Lumen but chromatically-not" rendering went undetected because nobody opened the running app in a browser between S07 and S10's audit. This is a process gap, not a coding gap.

## What to change for the next sprint?

- [ ] **Save memory entry for "Closes #N discipline".** The S10 → S11 lesson is now confirmed (mandate the keyword in agent prompts → zero stale issues at close). Promote it from "lesson learned" to durable working-method memory.
- [ ] **Strengthen worktree-gotcha mitigation in agent prompts.** Current language ("use absolute paths starting with the worktree root") didn't prevent Agent A's first-write slip. Try a stronger formulation: an explicit pre-Write self-check.
- [ ] **Add a "render-pass-spot-check" ritual after any design-pass PR merges.** 30 seconds in a browser per sprint would have caught the Lumen drift 4 sprints earlier. Make this part of the close ritual or the PR review checklist.
- [ ] **Decide what to do if the beta amigo stays silent through S12.** S10 retro's "meta-pattern of preparing-but-not-sending" became "meta-pattern of preparing-and-sending-but-no-response". If S12 ends with #150 still at zero, the framing has to shift from "waiting on real use" to "we have a delivery channel without a delivery". May need to invite cohort #2 instead of waiting indefinitely.

---

## Vision alignment — state of the 6 axes

> What % does each axis feel like vs before the sprint?

| # | Axis | Before | After | Notes |
|---|---|---|---|---|
| 1 | Every feature maps to a JTBD | 100% | 100% | No new orphan features. All 8 issues mapped to a JTBD in `qa.md`. |
| 2 | Zero prescriptive copy in code | ~98% | ~99% | #148 closed the StatementsHelper English-line-item pocket; #149 closed the bug-report mailer subject pocket. No new prescriptive copy introduced anywhere. |
| 3 | Zero aspirational fake copy | 100% | 100% | No new copy added to surfaces that lacks a real backing source. Profile sessions UI shows real session data; 3-channel prefs are pure UI shells over the existing notification model and labeled as such in PR body. |
| 4 | Dashboard arithmetic truthful for MXN+USD | 100% | 100% | Untouched by S11. |
| 5 | Architecture without cross-context leaks | 100% | 100% | No new cross-context AR reads from Trading → MarketData or sibling boundaries. Profile sessions added a new model inside Identity; sidebar revamp + trades footer used existing scopes/queries. |
| 6 | Docs reflect current code | ~70% | ~98% | **The single biggest jump of any sprint.** `docs/design/tokens.md` was the spec the whole time; `application.css` finally matches it via #142. The "docs lie about reality" gap that drove S10's audit finding is now closed. Remaining ~2% gap: a few minor `docs/design/` references to surfaces that haven't been re-screenshotted. |

---

## Anti-patterns I committed (if any)

- **None caught.** No "feature creep beyond the scoped issue" — every PR stayed inside its discovery card. No "preemptive abstraction" — Lumen CSS migration just changed values, didn't introduce a token-loader abstraction. No "skipping discovery" — #149's audit-first approach prevented an unneeded mailer rewrite. No "false confidence" — `qa.md` correctly flags usage metrics as ⚠️ pending instead of claiming verification.

The one gotcha (Wave 2 Agent A worktree slip) was a tool behavior issue, not an anti-pattern I committed. It's listed under "what didn't work" because the mitigation language wasn't strong enough, but the recovery was clean.

---

## Real vs estimated time

| Task / Issue | Estimated | Real | Reason for deviation |
|---|---|---|---|
| #142 Lumen CSS | 1h (~30 LoC swap + 7 hex literal patches) | ~45 min | Spot-on. Foundation work always feels fast when the diagnosis is clean. |
| #143 Dashboard sidebar + grid | 3-4h (7 partials) | ~1h (agent) | Parallel-agent compression: agent ships in single pass while main thread does other work. |
| #144 Asset detail Ficha | 2-3h | ~1h (agent) | Same. |
| #145 Trades filter + footer | 2-3h | ~1h (agent) | Same. |
| #146 Profile 2-col + sessions | 4-5h (backend gaps possible) | ~1.5h (agent) | Session model + 3-channel prefs added; agent shipped both UI + stub backend in single PR. |
| #147 Password recovery 5 states | 3h | ~1h (agent) | Same. |
| #148 Statements es-MX | 30 min | ~20 min (agent) | Small change. |
| #149 Bug-report mailer | 30 min | ~30 min (main thread + bot review loop) | Spot-on. |
| **Total raw effort estimate** | **16-19h** | **~7h actual wall-clock** | **~0.4× ratio** — parallel-agent dividend. |
| Wave 4 close | 1h | ~45 min | Standard close ritual. |

Calibration note: the ~0.55-0.7× ratio from S09/S10 is now ~0.4× because Wave 2 ran 2 agents concurrently, multiplying effective hours without multiplying wall-clock hours. Future sprint sizing should account for the multiplier when parallel-agent workflow is viable (bounded, disjoint, well-spec'd tasks).

---

## Registered decisions (link to ADRs if applicable)

- No new ADRs written this sprint.
- **Informal decision (documented in PR #159 review reply):** the `body.to_s` vs `.decoded` distinction in mailer specs — applied gemini suggestion to use `.decoded` because it returns the rendered output (not transfer-encoded), making tests robust to MIME edge cases. Not ADR-worthy but worth recording: prefer `.decoded` for any new mailer spec.
- **Informal decision (Wave 1):** legacy semantic color names (`success`, `error`, `warning`, `info`) kept as aliases of the canonical Lumen names (`positive`, `negative`, `warning`, `info`) to avoid a wide view sweep in #142. Migration is opportunistic in subsequent sprints (S12+) when each surface is touched for other reasons.

---

## Issues open at close

- **#150 reactive bucket** — by design. Reserve channel for beta-amigo feedback when it arrives. Stays open into S12 as the continuing reactive channel; no migration needed.

No other issues from S11 scope remain open.

---

## Brutal quote of the sprint

> S11 was mostly catching the codebase up to its own documentation: the Lumen palette had been real in `tokens.md` since S07 — five sprints of "design pass" PRs claimed it without anyone noticing nothing was actually wired up. The fix was 30 lines. The lesson is that nobody opened the running app between S07 and S10.
