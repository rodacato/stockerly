# Log — Sprint S11 (visual-truth-and-completion)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-22 — Sprint opening: 24h-pause rule honored (2nd consecutive)

S10 closed 2026-05-21. S11 opens 2026-05-22 — exactly 24h later. Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden
- S09→S10: respected
- S10→S11: **respected** (today)

2nd consecutive respect, restoring the rule's full health after the S08→S09 override. Per S07 commitment, 2 consecutive overrides invalidate; the recovery sequence is now solid.

---

## 2026-05-21 — Beta invite sent (between S10 close and S11 open)

Adrian sent the first beta invite the same day S10 closed. The S10 retro framed the invite procrastination as "the meta-pattern" — that pattern broke the moment the retro published. No response yet from the beta amigo; expected to take days. Whatever feedback arrives lands in **#150 reactive bucket** without derailing S11 main scope.

The S10 retro narrative ("3rd consecutive sprint to defer") is technically true at the moment it was written; the invite-going-out timing means it was the last sprint where that statement applied.

---

## 2026-05-22 — Initial scope set

Adrian chose **Large scope (8 main + 1 reactive)** at sprint open knowing this echoes the S10 over-delivery anti-pattern. Rationale: the parallel-agent capacity is proven, and most S11 issues are bounded (post-design-pass completions, not greenfield). Tracking goal at retro: did we close 8/8, or did we close 6/8 + hide something?

**Main work filed as #142-#149 + reactive #150:**

- **#142 Lumen CSS migration** — #1 priority, ~30 LoC. Foundation everything else depends on.
- **#143 Dashboard sidebar + main grid** — 7 partials still English + pre-Lumen (#116 only did the top hero).
- **#144 Asset detail "Acerca de la empresa" Ficha** — #93 follow-up.
- **#145 Trades filter + footer totals** — #98 follow-up.
- **#146 Profile 2-col + theme/sessions/3-channel prefs** — #97 follow-up.
- **#147 Password recovery re-implement (centered card + 5 states)** — #99 follow-up.
- **#148 StatementsHelper line-item labels es-MX** — #132 follow-up (small).
- **#149 Bug-report mailer es-MX migration** — #124 follow-up (audit before deciding scope).
- **#150 reactive bucket** for beta-amigo feedback.

---

## 2026-05-22 — Stale issues from S10 closed (#93, #94, #125)

Discovered at sprint open that PRs #131, #132 didn't use the `Closes #N` keyword in their bodies so GitHub didn't auto-close #93 and #94. Same for #125 which was qa-marked as resolved but never actually closed. All 3 cleaned up manually before filing S11 issues to keep the open-issue list clean.

Lesson for S11+ agents: prompts must explicitly require `Closes #<N>` syntax in PR body (already in the canonical pattern; one agent missed it). Re-emphasize in the next round of agent prompts.

---

## 2026-05-22 — Sprint sequence locked

Wave 1: #142 alone (do it myself, sequential, ship as foundation).
Wave 2: 2 parallel agents in worktrees, each shipping 3 PRs (Agent A: #143 + #144 + #148 / Agent B: #145 + #146 + #147).
Wave 3: #149 single PR (~30 min cleanup).
Wave 4: close (read-only audit + qa + retro).

Rationale: #142 unlocks visual truth on all surfaces. Wave 2 PRs compound on a Lumen-correct chrome instead of re-papering over the wrong primary. If we'd parallelized Wave 2 with #142 in flight, each agent would have ended up touching the same color classes that #142 just changed → rebase conflicts.

---

## 2026-05-22 — Wave 1 shipped (#142 PR #152)

Lumen CSS migration. Wrote canonical tokens in `app/assets/tailwind/application.css` from `docs/design/tokens.md` directly. Primary moved `#005A98 → #5B6CFF`, full surfaces/foreground/borders/semantic blocks added, dark-mode overrides under `:where(html.dark, [data-theme="dark"])`. Legacy semantic names (`success/error/warning/info`) kept as aliases of canonical Lumen names (`positive/negative/warning/info`) to avoid a wide view sweep this PR — explicit migration note in the CSS comment block.

Gemini reviewer flagged 7 hardcoded hex literals in 7 view files that escaped a previous design pass; patched all in the same PR. Also updated `public/manifest.json` (`theme_color #005A98 → #5B6CFF`, `background_color #F5F7F8 → #FAFAF7`) for PWA chrome parity with the new tokens.

Wave 1 took ~45 min from "start of #142" to "merged on master" including the bot review loop.

---

## 2026-05-22 — Wave 2: 6 PRs from 2 parallel agents in worktrees

Launched Agent A (chrome: #143 + #144 + #148) and Agent B (records: #145 + #146 + #147) in parallel worktrees. All 6 PRs shipped CI-green within ~3h end-to-end including bot reviews.

- **#143 dashboard** (PR #154): sidebar + main grid revamp, 7 partials touched, Stockerly-2.0 layout matched.
- **#144 asset detail Ficha** (PR #155): "Acerca de la empresa" block on `/market/:symbol` for equities with Alpha Vantage `OVERVIEW` data.
- **#148 statements es-MX** (PR #157): `StatementsHelper` line-item labels translated; small change.
- **#145 trades** (PR #153): filter strip + footer totals + inline delete-confirm, no extra SQL queries (Ruby aggregation on loaded array).
- **#146 profile** (PR #156): 2-col with IdentityCard sidebar, theme toggle, sessions list, 3-channel notification prefs. New `Session` model + migration.
- **#147 password recovery** (PR #158): centered card layout + 5 dedicated states (forgot, forgot-sent, reset-form, reset-success, reset-expired).

**Worktree gotcha recurred** on Agent A's first file write — landed in main checkout instead of worktree path. Recovered via `cp` within minutes; rest of session was clean. Mitigation language in the prompt didn't prevent the first-write slip → followup in retro to strengthen the prompt template.

**All 6 PRs used `Closes #N` correctly** — direct fix for the S10 retro's discipline gap. Zero stale issues at this close.

---

## 2026-05-22 — Wave 3 #149 bug-report mailer (PR #159)

Audit-first: read `app/mailers/bug_report_mailer.rb` and `app/views/layouts/mailer.html.erb` before scoping. Result: body + layout already correct from #124 work — only the subject string `"[Beta bug] ..."` was English. 2-line code fix (`[Beta bug] → [Bug beta]`) + 1 spec assertion update + 1 new regression spec asserting the canonical Stockerly logo renders via the shared mailer layout (`logo_light.svg` + `alt="Stockerly"`).

Gemini reviewer made 2 comments: (1) suggested I18n migration — declined per ADR-0007 with canonical boilerplate, (2) suggested `.decoded` over `body.to_s` for mailer body assertions — applied. The `.decoded` swap is a legit improvement for any future mailer spec; informal decision recorded in retro.

---

## 2026-05-22 — Wave 4: close

This commit. Audit + qa + retro + log close entry. Suite: **2637/2637 green** (+51 specs vs S10 close). Rubocop **875 files clean**. Brakeman **0 warnings**. Bundler-audit **0 vulns**. Master CI all green across the 10 merged PRs.

Pre-Lumen hex literal grep (`#005A98|#004a99|#3BC175`) across `app/`, `public/` returns 0 matches in live code — the visual-truth gap is closed. The migration-note comment in `application.css` is the only remaining mention (intentional, documents the history).

**Beta amigo silence:** zero #150 reactive bucket traffic since the 2026-05-21 invite. Anticipated. Carries into S12 as the continuing reactive channel.

---

## 2026-05-22 — Sprint counter snapshot

- Issues closed: 8/8 main scope (#142, #143, #144, #145, #146, #147, #148, #149) + #140 carryover merged + sprint-open #151
- Issues open: #150 (reactive bucket, by design)
- PRs merged this sprint: 10 (#140, #151, #152, #153, #154, #155, #156, #157, #158, #159) + close PR pending
- Wall-clock: ~7h actual against 16-19h estimate (~0.4× ratio — parallel-agent dividend)
- 24h-pause rule status going into S12: held (2 consecutive respects)
