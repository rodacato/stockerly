# TODO — 2.0 Evolve / Cleanup phase

## ✅ STATUS — 2.0 IS LIVE IN PRODUCTION (2026-08-23)

The evolve/cleanup phase is **DONE and DEPLOYED**. `evolve_2_0_pre` merged to `master`,
`master → production` deployed to andys-room, prod cut over to a **fresh single-user instance**
(deleted beta users + audit trails via `User.destroy_all` etc., **kept all market data +
integrations + api keys**). `stockerly.notdefined.dev` runs the single-user 2.0.

**Next phase = the actual point of the pivot: the NEW DESIGN.** Everything below "phase rule" is the
now-finished cleanup; the design work lives in the gitignored `redesign/` hub.

> **How to read the unchecked boxes.** The *phase* is done; the boxes still open are deferred
> follow-ups, not blockers, and this file is a personal scratchpad — **GitHub Issues remain the
> single source of truth for backlog items** (`docs/ops/github-workflow.md`). Two open items are real
> work that should be filed as issues rather than living here: the `SyncDividendsJob` projected-vs-
> received defect (see "Deferred") and the User-model column slim. Anything not filed there is a
> note, not a commitment.

**Adrian's first prod observation (2026-08-23):** the **assets / sync / how market data is shown**
feels confusing — a UX/product area to fix, likely folded into the design phase.

---

> **The phase rule (Adrian, 2026-08-22):** NO new features. Clean up, delete the unnecessary, fix the
> *simplest* thing needed to continue, get minimum-viable to production, update context + docs. THEN
> plan new designs, discuss, decide how to continue. This is my running checklist — I keep it current.

## Standing reminders

- [ ] Append highlights to `BITACORA_2_0.md` as milestones happen (for the AI-slop blog post).
- [ ] `redesign/` is gitignored — discovery hub, kept local. Do NOT commit it, do NOT work in it this phase.
- [ ] Commit locally per logical step; **never push / deploy without Adrian's explicit ok.**
- [x] ~~Long-lived branch: `evolve_2_0_pre`~~ — merged to `master` and **deleted**. The tag
      `pre-2.0-evolve` still marks the baseline; work from `master`.
- [ ] Do NOT build the seam ahead of the screen (panel veto): no pluggable-registry framework, no
      event-table/persistence, no net-new evaluators this phase. Those wait for the design phase.

## Phase 0 — Kickoff & reconcile

- [x] Branch `evolve_2_0_pre` from the pivot commit + tag `pre-2.0-evolve`.
- [x] gitignore `/redesign/`.
- [x] Create `BITACORA_2_0.md` + `todo.md`.
- [x] Reconcile stale **context/memory**: `project_decision`, `project_vision`, `MEMORY.md` (P0 FIXED;
      `api_key_pool` = rework). ⚠️ **Adrian: run `apu save`** to propagate — apu isn't on my PATH.
- [x] Reconcile stale **docs**: CLAUDE.md (dropped the vaporware `EvaluateSentimentAlerts` flow),
      ADR-0010 (addendum: P0 fixed + `api_key_pool` is plumbing). ADR-0009 needed no change.
- [ ] Later (Phase 5): fix the ADR-002 read-boundary leaks (Alerts→MarketData AR; Identity/Notifications)
      — 2 of the 3 die with the multi-user delete anyway.

## Phase 1 — Safety net first (mancuso's pre-step)

- [ ] Characterization tests on the two seams before touching them: `SyncSingleAssetJob#gateway_for`
      routing; the Alerts `case rule.condition` switches. Confirm the ~2725 specs are behavior-pinned,
      not implementation-pinned. If the net is fake, re-plan — evolve is riskier than assumed.

## Phase 2 — Aggressive delete (FK-clean, problems.md §C)

- [x] `email_event` — dropped (model, Resend webhook, route, migration, specs, factory). `78001dd`. Green 2736.
- [x] `user_activity` — dropped (model, ActivityRecorder, 3 handlers, page-view tracking, subs, migration). `4f00567`. Green 2705.
- [x] `invite_code` + registration + admin/invites — dropped (model+table, register use-case/contract/
      controller/view, UserRegistered event, welcome/verify-email handlers, admin/invites, cleanup job,
      registration_open toggle, ~12 specs). Portfolio+alert-prefs re-pointed to `FirstAdminCreated`.
      Fixed dangling refs: admin sidebar "Invites" link (caused 87 admin failures), navbar/login register
      links, users empty-state. Green 2608.
- [x] verify-email feature. `4d29ad2`. Green 2581.
- [x] `remember_token` (auth-core surgery: session-only auth, no "remember me"/active-sessions). `fe6d132`. Green 2556.
- [x] `admin/users` management (list/suspend/reactivate/delete + events + mailers + nav). `7dcd917`. Green 2503.
- [ ] **NEXT — User model slim:** drop `status`/`suspended` (enum + column + Login check + factory trait
      + `not_suspended` scope), `email_verified_at`/`is_verified` column + `email_verified?` + verified
      scopes (now fully dead), `admins`/`traders` scopes. Big spec-blast (factory + many specs set
      `email_verified_at`). Keep `role` (admin zone still gates provider config).
- [ ] Tidy dead `welcome` mailer (caller deleted with registration) + its view/spec.
- [ ] `seeds.rb` single-user rewrite.
- NOTE: `api_key_pool` was never a multi-user delete — it was MarketData plumbing. Resolved
  separately by ADR-015 (see Phase 3).
- NOTE: consider renaming `FirstAdminCreated` → `AccountCreated` (no "admin" in single-user) — later.

## Phase 3 — Fix only the simplest needed to continue (problems.md §F + api_key_pool)

- [x] Fix the 2 `Notification.create!` bypasses (earnings/maturities never broadcast live). `4f51805`.
      Green 2505. Added a broadcast regression test to each.
- [x] `api_key_pool` → collapse to a single key per provider. **SHIPPED 2026-08-26 as
      [ADR-015](docs/architecture/adr/0015-one-api-key-per-provider.md)** — not for elegance, but
      because four providers' terms prohibit multi-credential free-tier stacking. `KeyRotation` →
      `ApiKeyResolver`.
- [ ] Dead `AlertPreference` flags — **decorative UI, not a bug** (toggles that don't gate anything;
      no email/SMS channel exists). Group with the User-column slim as cosmetic cleanup, deferred.

## Product idea captured (from first-boot dogfood, 2026-08-22)

- **Opt-in checkboxes for editorial data sources (news/sentiment).** Adrian's principle: for
  *fungible* data (prices, FX, fundamentals) the source doesn't matter — no choice needed. For
  *editorial* sources (news, sentiment) the source carries bias/coverage → be transparent AND let
  the user check which ones to use. Today the only editorial Integrations are the 2 sentiment ones
  (Alternative.me, CNN); news is a capability of Polygon/Finnhub, not a standalone source.
  **Needs first:** a real per-provider enable/disable on `Integration` (only `connection_status`
  exists, which is sync-state not preference) + onboarding persistence + sync respecting it. The
  onboarding save path sat on `api_key_pool`; that rework **shipped** as ADR-015, so this is no
  longer blocked. Transparency half (show + link each source) already shipped.
  ⚠️ Stale as written: CNN and Polygon are both **retired**
  (`db/migrate/20260826210000_remove_retired_integrations.rb`). The editorial sources today are
  Alternative.me (sentiment) and news as a capability of Alpaca and Finnhub.

## Tier 1 dead-code cleanup — DONE (2026-08-23)

- [x] Dead use cases (LoadProfile, SyncCryptoFundamentals), SkeletonHelper, orphan partials. `d65cbc5`.
- [x] Dead helper methods (alert_directional?, app_nav_active?, compute_margin) + 2 orphan events
      (RuleCreated, WatchlistItemAdded, published to no subscribers). `628a132`.
- [x] Stale closed-beta + email-verification copy. `08c4299`.
- [x] Unused gems money-rails + image_processing. `89b83aa`. **Audit was WRONG on thruster (prod
      Docker CMD) + faraday-retry (~11 gateways) — kept both.** Always verify sweep findings.

**Cleanup base is complete and green (2496 examples).** The multi-user surface is gone and no dead
code is left loose. Remaining items below are working-code reworks / cosmetic — separate sessions.

## Deferred (working code / cosmetic — focused follow-up sessions, not this marathon)

- User model column slim (`status`/`is_verified`/`email_verified_at`) — ~40 spec files, dead columns.
- ~~`api_key_pool` → single-key simplification — CANCELLED (2026-08-23), keep the multi-key pool~~
  **REVERSED AND SHIPPED (2026-08-26).**
  [ADR-015](docs/architecture/adr/0015-one-api-key-per-provider.md) retired multi-key rotation: the
  2026-08 provider audit found that Alpaca, Massive (ex-Polygon), Finnhub and CoinGecko all
  **explicitly prohibit** using multiple credentials to exceed a free tier. The "rate-limit
  workaround" was adopted before those terms were read. `KeyRotation` is gone, replaced by
  `app/shared/domain/api_key_resolver.rb`; there is one key per provider. Nothing left to do here.
- `AlertPreference` decorative flags.
- Dead `welcome` mailer + its view/spec.
- `seeds.rb` single-user rewrite.
- Rename `FirstAdminCreated` → `AccountCreated`.
- `SyncDividendsJob` records **projected**, not received, income — two defects found 2026-08-26 while
  scoping FIBRA support. `create_payments` multiplies `position.shares` *as of today* instead of the
  shares held at the dividend's `ex_date`, so a position opened after the ex-date gets a payment it
  never received; and `received_at` is only ever set in `seeds.rb`. Harmless while the dividends tab
  is display-only — wrong data the moment income feeds a return calculation.

## Phase 4 — Minimum viable to production

- [ ] Get the cleaned single-user app running the minimum functional in production (Kamal → andys-room).
      [needs Adrian's explicit deploy ok]

## Phase 5 — Update context & docs

- [ ] Update CLAUDE.md architecture map to match the cleaned single-user reality.
- [ ] Finalize the doc/memory reconciliation; graduate the `redesign/` analysis into `docs/` where it belongs.

## Then — NEW designs (separate phase, after cleanup)

- Plan new designs (Claude Design prototypes, mobile-first cockpit) → discuss → decide how to continue.
- Open decisions parked in the `redesign/` hub: event-log fork (Q1), plugin seam (Q3), evaluators, Q5
  comparativas. NOT this phase.
- **Income as a domain fact (dividends / FIBRA distributions).** No documented trigger yet — parked on
  purpose, not forgotten. Today the portfolio measures price appreciation only: `portfolio_snapshots`
  carries `invested_value` + `total_value` and nothing else, and `DividendPayment` never reaches a
  return calculation. Scoped 2026-08-26:
  - **Already there:** Yahoo covers BMV (`.MX`), so a FIBRA registered as a `stock` in MXN prices
    correctly today with historical FX. The `dividends` + `dividend_payments` tables exist.
  - **The feature is income, not FIBRAs.** Captured payment (amount, currency, FX at pay date,
    withholding, shares at `ex_date`), `income_received` on the snapshot, and yield-on-cost /
    current-yield / total-return. That serves every dividend-paying holding, not just FIBRAs.
  - **The expensive part is the MX tax treatment.** A FIBRA's *reembolso de capital* reduces the
    position's cost basis, so a distribution mutates `Position#avg_cost` — a second position-mutating
    event alongside splits, on the seam the multi-currency P0 just stabilised.
  - **The blocker:** no configured gateway returns FIBRA distributions. Only FMP implements
    `fetch_dividends` and its BMV coverage is poor; Yahoo exposes them via `events=div`, unimplemented.
    Manual capture is the data-entry fastidio that killed the beta.
  - **Cheapest path to a real trigger:** buy one small FIBRA position, register it as a `stock` in MXN,
    and wait for the first distribution to become annoying. Then the discovery card writes itself.
