# TODO — 2.0 Evolve / Cleanup phase

> **The phase rule (Adrian, 2026-08-22):** NO new features. Clean up, delete the unnecessary, fix the
> *simplest* thing needed to continue, get minimum-viable to production, update context + docs. THEN
> plan new designs, discuss, decide how to continue. This is my running checklist — I keep it current.

## Standing reminders

- [ ] Append highlights to `BITACORA_2_0.md` as milestones happen (for the AI-slop blog post).
- [ ] `redesign/` is gitignored — discovery hub, kept local. Do NOT commit it, do NOT work in it this phase.
- [ ] Commit locally per logical step; **never push / deploy without Adrian's explicit ok.**
- [ ] Long-lived branch: `evolve_2_0_pre` (tag `pre-2.0-evolve` marks the start).
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
- NOTE: `api_key_pool` is NOT a delete — it's MarketData plumbing (7 gateways). See Phase 3.
- NOTE: consider renaming `FirstAdminCreated` → `AccountCreated` (no "admin" in single-user) — later.

## Phase 3 — Fix only the simplest needed to continue (problems.md §F + api_key_pool)

- [ ] Fix the 2 `Notification.create!` bypasses (earnings/maturities never broadcast live).
- [ ] Dead `AlertPreference` flags: honor or remove.
- [ ] `api_key_pool` → collapse to a single key per provider (expand-contract: add single-key path →
      migrate the 7 gateway call-sites + `KeyRotation` → drop the pool ceremony). Simplify for single-user.
- Minimal only. Registry-wiring / event-log / evaluators are NOT here — they wait for the design phase.

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
