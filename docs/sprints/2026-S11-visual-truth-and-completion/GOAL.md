# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Close the **visual-truth gap** discovered at S10 close (the entire Lumen palette was never applied to `application.css` — every "design pass" since S07 rendered against the wrong tokens) and finish the **3 deferred Stockerly-2.0 surfaces** (dashboard sidebar, profile 2-col, password recovery) so the product Adrian invited a beta amigo to on 2026-05-21 stops *claiming* Lumen and *actually renders* Lumen.

**Sprint period:** 2026-05-22 → TBD (close by QA + retro, not by date)

**Sprint number / milestone:** S11 — 2026-S11-visual-truth-and-completion

---

## Why this goal and not another

The S10 close audit (`.local/design-mockups/Stockerly-2.0/AUDIT-operational.md` + `AUDIT-surrounding.md`) surfaced **the single most consequential structural finding of the last 5 sprints:**

> The Lumen palette in `docs/design/tokens.md` was never applied to `app/assets/tailwind/application.css`. The CSS layer still ships `--color-primary: #005A98` (pre-Lumen corporate blue) instead of `#5B6CFF` (Lumen primary). Every "Stockerly-2.0 design pass" since S07 merged Lumen-shaped layouts + copy against the wrong color tokens. Structurally surfaces match the mockups; chromatically none do.

This is a one-file, ~30-LoC change (#142) that unblocks visual truth on all 12 user-facing surfaces simultaneously. **Ship it first** so the design completions that follow (#143 dashboard, #146 profile, #147 password recovery, #144 asset detail, #145 trades) compound on top of correct chrome instead of re-papering over the wrong primary.

The 3 design-pass deferrals from S10 retro (dashboard sidebar, profile 2-col, password recovery) are the highest-value remaining gaps the beta amigo will see if they actually log in and start clicking around. They were deferred in S09/S10 due to scope discipline, not because they were unimportant — and now that we have the parallel-agent capacity demonstrated twice (S10 #93/#94 + admin 6-pack), they can fit in one sprint.

**Critical context:** Adrian sent the first beta invite on 2026-05-21 (between S10 close and S11 open). No response yet — beta amigo may take days. Whatever surfaces from real use lands in **#150 reactive bucket** as it arrives, without derailing scope.

**What this unblocks:** the visual gap between "what the design system claims" and "what the user sees" closes. Brand audits over the next sprints don't keep re-finding the same chromatic drift. The retro's "structurally-Lumen but chromatically-not" finding is permanently retired.

---

## What's NOT in this sprint (anti-scope)

Deliberately excluded:

- **Beta invite re-send / second-amigo invite** — first invite is already out (2026-05-21). Wait for response before considering cohort #2.
- **PromoteUser + ResendVerification use cases** — admin/users overflow menu stubs from #135. Disabled UI is honest; backend stubs aren't a beta blocker. Defer.
- **Asset `issue_date` column** for non-CETES fixed-income progress bar — #132 follow-up. Niche, low traffic. Defer until a real CETES-like instrument that isn't pattern-parseable shows up.
- **Wordmark text-to-paths** (#140 deferred) — requires offline Figma/Inkscape tooling Adrian owns. Park as Adrian's external task; not blocked by us.
- **Glyph variants §11.1 doc in `docs/design/brand.md`** — pure documentation, low impact. Bundle into another docs PR when convenient.
- **`MarketData::Domain::MetricDefinitions` translation** (P/E, EV/EBITDA, Beta) — out of scope; financial-glossary translation is a separate decision (some terms read better in English even in MX context).
- **Admin views Lumen migration touch-ups** — admin 6-pack shipped in S10 (#134-#139). Any micro-tweaks deferred to admin-feedback cycle.
- **Performance benchmarking** — same as S10. Until usage data exists, premature.
- **`MissionControl::Jobs::Engine`** at `/admin/jobs` — third-party UI. Cannot restyle without forking.

---

## 24h-pause rule note

S10 closed 2026-05-21. S11 opens 2026-05-22 — **24h-pause rule honored** (exactly 24h, 2nd consecutive respect after S09→S10).

Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden
- S09→S10: respected
- S10→S11: **respected** (today)

Per S07 commitment, two consecutive overrides invalidate the rule. The recovery sequence is holding.
