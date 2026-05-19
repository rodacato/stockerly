# QA Pass — Sprint S09

> Mandatory checklist BEFORE writing `retro.md` and closing the sprint.
> If an item isn't met → either document why in `retro.md`, or the sprint does NOT close.

---

## Goal & scope

- [x] **Sprint goal achieved** — Stockerly-2.0 design pass implemented on 6 operational screens (dashboard, portfolio, trades, market, profile, password recovery). First invited friend lands on a visually coherent es-MX UI end-to-end.
- [x] **All `main` scope issues** closed — 6/6 (#90, #91, #98, #99, #92, #97).
- [x] **Parallel issues** — #113 i18n decision closed wont-fix (No-Go, re-visit triggers documented).
- [x] **Unclosed issues** — none. #98 didn't auto-close on PR #118 merge; closed manually with comment for traceability.

## Code health

- [x] `bundle exec rspec` green — **2353 examples, 0 failures**
- [x] `bin/rubocop` no offenses — **830 files inspected, no offenses detected**
- [x] `bin/brakeman` no new warnings — **0 warnings**
- [x] `bin/bundler-audit` no vulnerabilities — **No vulnerabilities found**
- [ ] CI on GitHub Actions green — pending verification after `chore/s09-close` lands (last per-PR CI was green)
- [x] Working tree clean — only `.DS_Store` and `.research/` (both gitignored)

## Vision compliance

- [x] **Manual audit of new copy** — no ADR-001 violations. Dashboard greeting + portfolio + trades + market + profile + password recovery all descriptive, no marketing copy or aspirational claims.
- [x] **Manual scope audit** — no non-goal violations. No fiscal copy, no public-audience copy, no investment recommendations introduced. ARCO data-export action references LFPDPPP correctly.
- [x] **JTBD mapping** — every shipped feature maps to a JTBD:
  - Dashboard revamp → "consolidated patrimony truthful" (JTBD #1, depends on S08 C1)
  - Portfolio revamp → "portfolio control" (multi-currency entry)
  - Trades revamp → "portfolio control" (audit trail)
  - Market revamp → "market discovery" (MX-anchored)
  - Profile revamp → "account control" (preferences + LFPDPPP data rights)
  - Password recovery → "auth-family completion" (closes S08 #95 + #96 set)
  - i18n decision → meta / architecture (closes Gemini repetition)
- [x] **Discovery card DoD** — every issue's DoD checklist completed in its respective PR.

## Documentation

- [x] **New ADR written** — not applicable this sprint; built on ADR-0007 (i18n defer) + ADR-0008 (domicile disclosure) from S08.
- [x] **Vision update** — not applicable.
- [x] **Design docs** — not applicable; implementation is mockup-faithful, no token/component/brand changes.
- [x] **Screenshots regenerated** — not applicable; manual visual check is the verification, screenshots come from S10 when the broader design audit happens.
- [x] **CLAUDE.md / IDENTITY.md / memory updated** — CLAUDE.md got the new "Language (3 zones, no Rails I18n)" section as part of #113 close. Memory `feedback_repo_language_english.md` updated with explicit re-visit triggers.

## GitHub hygiene

- [x] **Closed issues** — all 7 sprint issues closed (6 via PR auto-close, #98 manually, #113 via PR #122 wont-fix).
- [x] **Milestone ready to close** — 7/7 issues in terminal state.
- [x] **No orphan issues** — sprint board reviewed; nothing in flight.

## Usage metric (post-close verification)

For each JTBD touched in this sprint:

| JTBD | Expected metric | State |
|---|---|---|
| Consolidated patrimony truthful (dashboard) | "Adrian opens /dashboard and the MXN total reads from `Portfolio#total_value(currency:)` truthfully for mixed MXN+USD positions" | ✅ verified via spec invariant (S08 #105 + S09 #90 KPI) |
| Portfolio control (trade form + positions table) | "Adrian registers a USD trade and an MXN trade; positions table shows them with correct currency prefix per row" | ✅ verified via spec (S09 #91 portfolio_revamp_spec) |
| Auth-family completion (recovery flow es-MX) | "Adrian invites first friend; if friend forgets password, the recovery email + form + flash are all es-MX" | ⚠️ pending first invite verification (real email send) |
| Account control (currency preference) | "Adrian switches preferred_currency from MXN to USD in /profile; dashboard + portfolio reflect the new denomination immediately" | ✅ verified via spec (S09 #97 profile_revamp_spec PATCH test) |
| LFPDPPP data rights (ARCO export) | "Adrian clicks 'Solicitar acceso a mis datos'; mail client opens with pre-filled subject + body referencing the support email" | ⚠️ pending manual verification on first ARCO request received |

---

## Additional notes

- 7 PRs merged in S09: #116 (Dashboard), #117 (Portfolio), #118 (Trades), #119 (Password recovery), #120 (Market), #121 (Profile), #122 (i18n decision). Plus PR #115 (sprint open docs).
- Test suite grew from 2255 (S08 close) → 2353 (S09 close), +98 specs (+~4%). Coverage held at 94.7% line / 76.9% branch.
- Three new constants introduced for cross-context truth-sharing: `Stockerly::SUPPORT_EMAIL` (from S08, used in #97), `User::PASSWORD_RESET_EXPIRES_IN` (#99), `Trade::MODIFICATION_WINDOW` (#98), `MarketIndex::MAJOR_SYMBOLS` (#92).
- New helpers extracted: `DashboardHelper#format_currency_mx`, `#dashboard_greeting`, `#duration_in_words_es` (ApplicationHelper), `TradesHelper#trades_summary_by_currency`, `MarketHelper#vix_tier`, `#trend_strength_label`.
- One cross-repo correctness fix landed inside a PR (#121): NLFPDPPP → LFPDPPP across 26 occurrences in 12 files. Captured in retro as a "legal acronyms get authoritative-source lookup" discipline going forward.
- Auth flow now fully es-MX end-to-end: login (S08 #95) → register (S08 #96) → recovery (S09 #99). The dashboard + portfolio + trades + market + profile arc is also fully es-MX + Lumen.
