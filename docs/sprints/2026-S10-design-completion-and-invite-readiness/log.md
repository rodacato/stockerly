# Log — Sprint S10 (design-completion-and-invite-readiness)

> NON-trivial notes during execution. **Not a daily journal.** Only what you'd want to remember when reviewing this sprint in 6 months.

---

## 2026-05-20 — Sprint opening: 24h-pause rule honored

S09 closed 2026-05-19. S10 opens 2026-05-20 — exactly 24h later. **Pause rule respected.**

Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden (1st after the first respect)
- S09→S10: **respected** (today)

The rule is alive. Per the S07 retro commitment, two consecutive overrides would invalidate it; S09 was the override and S10 is the recovery. Honor maintained.

---

## 2026-05-20 — Initial scope set

Scope agreed with Adrian on 2026-05-20:

**Core (4 issues, mockup-ready):**
- #100 Earnings calendar revamp (simple, ship early)
- #101 Notifications inbox revamp (simple, ship early)
- #93 Asset detail revamp (adaptive by type — backend implications)
- #94 Alerts revamp (MX-aware rule types — backend implications)

**Parallel (2 issues, newly created):**
- #124 Logo audit — visual consistency across user-facing surfaces
- #125 Bug triage + reactive fixes during first beta invite (reserve capacity)

**Adrian plans to invite the first beta amigo during S10** — that's why #125 exists as reserve. Anything surfaced from real usage lands there with triage discipline (severity + action documented).

---

## 2026-05-20 — Why now for the first invite

S08 + S09 spent two sprints preparing: legal validity, mathematical truth, es-MX auth flow, es-MX operational screens. Continuing to polish without ever inviting becomes design-by-assumption. The first invite during S10 (not after) means feedback feeds back into the same window — reactive fixes in #125, not a separate post-invite cleanup sprint.

The sequence matters: ship #100 + #101 first (read-only revamps, low risk), do manual e2e test, send invite, then continue with #93 + #94 in parallel with reactive bucket #125 absorbing whatever surfaces.

---

## 2026-05-20 — #101 Notifications inbox shipped (PR #127)

First PR of the sprint. Discovery audit surfaced one decision point: the BMV-earnings data source for #100 doesn't exist yet — Yahoo gateway isn't registered for `:earnings` capability and Polygon/Finnhub don't cover MX equities. Routed that to a spike that ran in background (Yahoo `calendarEvents` module is viable) while #101 shipped in foreground. Pattern worked — keep using it when audits surface backend blockers.

Side-effect of #101: 3 notification-creator handlers (alerts, earnings, maturities) all had English copy. Translated them in the same PR because the inbox revamp in es-MX with English notifications inside was incoherent. Also surfaced that the dropdown panel in the navbar bell shared the same partial — translated that too.

---

## 2026-05-20 — #100 Earnings + BMV via Yahoo (PR #128)

Spike paid off: extended `YahooFinanceGateway` with `fetch_earnings` hitting `quoteSummary?modules=calendarEvents,earnings`. `SyncEarnings` now routes by `exchange`: BMV → Yahoo direct, others → existing chain. Explicit routing (not adding Yahoo to the chain capability) because Finnhub returns `Success([])` for unknown tickers, which short-circuits the chain and prevents Yahoo from ever being tried.

Added `confirmed` boolean to `EarningsEvent` for Yahoo's range-date case ("estimated 24-28 Apr"). UI surfaces it as "fecha por confirmar" warning.

---

## 2026-05-20 — #124 Logo audit (PR #129) + side-effects

The audit kept ballooning. Canonical `shared/_logo` partial extracted, 4 inline `<img>` callsites swapped, asset_badge fallback hardened with `onerror` for 404 cases, _asset_header delegated to badge. Then mailer layout — discovered transactional mailers had **no logo header at all**, also English copy in welcome/verify/suspended/reactivated. Translated all 5 to es-MX with the new layout because Adrian was about to invite beta amigos and the first welcome email can't ship in English.

Logged finding: navbar tabs (Dashboard / Market / Portfolio / Alerts / Earnings / News / Sign Out) were still English. Flagged for #130.

---

## 2026-05-20 — #130 Invite-prep landed (navbar es-MX + smoke + runbook)

Per scope sequence: Day 3 = invite prep. Translated navbar (Panel/Mercado/Portafolio/Alertas/Reportes/Noticias/Perfil/Cerrar sesión + admin Console). Wrote `spec/system/beta_smoke_spec.rb` (e2e: register → onboard → dashboard → market → asset → earnings → inbox → portfolio → profile → logout). Wrote `docs/ops/beta-invite.md` runbook (pre-flight checklist + es-MX message draft + rollback toggles + known gaps).

**Invite was supposed to go out this evening per scope. Adrian deferred sending.** Noted for retro.

---

## 2026-05-21 — Parallel agents for #93 + #94 in worktrees (PR #131 + #132)

First time using `Agent` tool with `isolation: worktree` for sustained implementation work (not just research). 2 agents in parallel, both completed:

- **#94 Alerts (PR #131)**: 4 of 6 rule types shipped (`price_crosses_above/below`, `rsi_overbought/oversold`, `volume_spike`, `dividend_ex_date` NEW). 2 deferred (`cete_auction`, `bmv_holiday`) — no upstream calendar source.
- **#93 Asset detail (PR #132)**: 4 asset-type-adaptive variants (equity / ETF / crypto / fixed_income). Recent observations promoted above chart, tabs trimmed from 8 to ≤4.

Pattern learnings (carry to memory):
- **Worktree gotcha**: both agents had their `Write/Edit` operations land in the main checkout (`/workspaces/stockerly/`) instead of the worktree path. Had to `cp` files into the worktree before committing. The agent prompt needs explicit instruction to use absolute paths starting with the worktree root.
- **Bot review polling**: agents stopped polling for `gemini-code-assist` reviews too early (within 5 min) and reported done while reviews arrived later. Adrian had to manually run the review loop on #132. Future prompts: "wait up to 15 min after CI completes for bot review".

---

## 2026-05-21 — #133 BMV/CETE follow-up unblocked the 2 deferred rule types

Spike: BMV holidays are a short annual list; CETE auctions land deterministically on Tuesdays (skip Banxico holidays). No external sync needed — single `MarketHoliday` model + seed for BMV + Banxico 2026 + a `next_business_day` helper on the model. `DateBasedAlertEvaluator` extended with `evaluate_bmv_holiday` + `evaluate_cete_auction` using boundary-trigger semantics (fire on the day the event is exactly `window_days` away, not a range — prevents daily spam).

Migration relaxed `asset_symbol` + `threshold_value` NOT NULL constraints; marketwide rules store nil for both. Trigger handler uses `.presence ||` fallback for the empty-string case the publisher passes.

---

## 2026-05-21 — Admin Lumen migration pulled forward (6 PRs #134-#139)

Originally S11+ scope per the GOAL.md anti-scope. Adrian wanted to advance the design pass on the admin zone in parallel with BMV/CETE. Followed the canonical visual-design workflow: drafted 6 self-contained prompts at `.local/design-mockups/Stockerly-2.0/admin/PROMPTS.md` (with shared preamble + screen-specific sections), Adrian generated mockups externally, I launched 2 parallel agents in worktrees:

- **Agent A** (chrome trio): #134 dashboard, #136 integrations, #138 settings — last including a new `SiteConfigChange` audit-log model + migration
- **Agent B** (records trio): #135 users, #137 assets, #139 logs

All 6 shipped 10/10 CI green. Agent B caught a **real XSS** (CodeQL HIGH) in the new `_empty_state` partial — `params` interpolated into an `html_safe` string. Fixed with `safe_join` + `content_tag`. Also caught a pre-existing N+1 in `_assets_table` (per-row `SystemLog` last-failure lookup) and fixed it with `DISTINCT ON` batched query + `make_queries(at_most: 10)` regression cap.

---

## 2026-05-21 — Read-only audit pass (2 reports under `.local/`)

After all PRs merged, Adrian asked for an audit of the 12 non-admin Stockerly-2.0 surfaces against their mockups. 2 read-only agents (no code, no commits) produced:
- `.local/design-mockups/Stockerly-2.0/AUDIT-operational.md` — 6 surfaces (dashboard / market / portfolio / alerts / earnings / notifications)
- `.local/design-mockups/Stockerly-2.0/AUDIT-surrounding.md` — 6 surfaces (asset / trades / profile / login / register / password_recovery)

**Critical cross-cutting finding:** the Lumen palette in `docs/design/tokens.md` was **never applied** to `app/assets/tailwind/application.css`. The CSS layer still ships `--color-primary: #005A98` (pre-Lumen corporate blue) instead of `#5B6CFF` (Lumen primary). Every "Stockerly-2.0 design pass" since S07 merged Lumen-shaped layouts + copy against the *wrong color tokens*. Structurally surfaces match the mockups; chromatically none do.

This single file fix (~30 lines) would close the visual gap on all 12 surfaces simultaneously. Carrying as #1 priority into S11.

---

## 2026-05-21 — Brand asset refresh (PR #140, opens for merge after S10 close)

While auditing, I checked `public/*.svg` — the live favicon + PWA icons + navbar wordmarks. All 6 shipped a pre-Lumen `#004a99` corporate blue with the old "ascending bars" glyph, while the canonical brand kit (focal-frame glyph + Plus Jakarta Sans wordmark + Lumen primary `#5B6CFF`) had been sitting at `docs/design/wordmark.svg` + `glyph.svg` since #34 but never wired into `public/`.

Regenerated all 6 SVGs from the canonical source on `chore/refresh-brand-assets`. Adrian asked to merge this PR **after** S10 closes so the brand refresh lands cleanly as S11's opening signal.

---

## 2026-05-21 — Beta invite NOT sent (called out for retro)

The whole structural premise of S10 was "invite during the sprint, feedback inside #125 reactive bucket." 13 PRs later, invite never went out. Scope said Day 3 evening; Adrian deferred. This is the 3rd consecutive sprint (S08, S09, S10) where we prepared for the invite and didn't send. **Meta-pattern** — flagged for retro.
