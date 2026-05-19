# Log — Sprint S09 (design-pass)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-19 — Sprint opening: 24h-pause rule overridden

S08 closed 2026-05-19 with PR #114 (close artifacts) merged same day. S09 opens same day — **24h-pause rule overridden consciously.**

Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: **respected** (the first time)
- S08→S09: overridden (today, 1st after the first respect)

Per S07 retro: "third consecutive override would invalidate the rule". This is the 1st override after honoring once — not yet a pattern-break, but on watch. **S09→S10 should honor the pause** to preserve the rule. If S09→S10 also overrides, the rule is effectively dead and should be either retired or rewritten.

---

## 2026-05-19 — Initial scope set

Scope agreed with Adrian on 2026-05-19:

**Core (critical path, 4 issues):**
- #90 Dashboard revamp — unlocks visual verification of S08 C1 truthful math
- #91 Portfolio revamp — mixed-MXN/USD trade form coherent with C1
- #98 Trades (Movimientos) revamp — auditable history, same family as #91
- #99 Password recovery — closes auth family (login + register already es-MX)

**Optional (2 issues, opportunistic):**
- #92 Market explorer revamp — MX indices first
- #97 Profile revamp — settings-focused

**Quick win paralelo (1 issue):**
- #113 i18n Go/No-Go decision card — closes the Gemini repetition loop

**Deferred to S10 (mockups ready, lower critical-path):**
- #93 Asset detail, #94 Alerts, #100 Earnings, #101 Notifications

**Closed as superseded:**
- #83 (S08 design pass research) — S08 took compliance + correctness direction; the per-screen design issues now carry the design-pass intent.

---

## 2026-05-19 — PR #115 review pass

Gemini caught a real mistake in this PR: my initial commit had all 5 sprint docs at their template state, not the sketched content. Cause: my Write tool calls right after `cp` from `_template/` failed silently with "File has not been read yet" errors and I committed without verifying. Reviewer flagged the unpopulated placeholders correctly.

Lesson: **never commit a file created via Write without re-reading it**, especially when it was first generated via `cp` or any non-Edit path. The Read-then-Write contract exists exactly to prevent this kind of slip. Captured as failure mode worth remembering for the AP review.

Fixed by re-Reading each file and re-Writing with the intended content. Replied inline to all 7 review comments.
