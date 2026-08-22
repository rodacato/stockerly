# ADR-0010 — Pivot to a self-hosted, single-user asset tracker

- **Status:** Accepted
- **Date:** 2026-08-20
- **Author:** Adrian Castillo
- **Supersedes:** the audience/scope half of the 2026-05-14 vision reset (`docs/vision/` as of that date)
- **Related:** [`docs/vision/`](../../vision/), [`docs/research/competitive-trackers-2026-08.md`](../../research/competitive-trackers-2026-08.md), [ADR-0001 (descriptive language)](0001-descriptive-not-prescriptive-language.md), [ADR-0009 (historical FX)](0009-fx-history-strategy.md)

---

## Context

The 2026-05-14 reset set the audience as **Adrian (dogfood) + a closed beta of ≤20 invited friends**. That beta was run and **it failed on its secondary audience**. Observed, not assumed:

- Friends did not adopt it. Concretely: they did not know what to do inside the app, could not read the indicators (RSI, MA200, F&G), and abandoned it quickly.
- Loading trades / tokens was reported as a *fastidio* (an annoying chore).

These are **product and UX failures — empty first-run, indicator illiteracy, data-entry friction — not architecture or code-quality failures.** The codebase is healthy: ~2,760 passing specs, 14 working market-data gateways, correct hexagonal boundaries, a working Kamal self-host path. The `[[feedback-anti-patterns]]` #7 audit ("did anyone actually use it?") finally ran, and its answer is what drives this ADR.

Two options were on the table when re-scoping:

1. Deprecate the repo and start a fresh "Stockerly 2.0".
2. Pivot in place on the same repo.

The 2026-05-14 decision (`[[project-decision]]`) had already diagnosed "start from scratch" as an *emotional escape, not strategy*, and that reasoning still holds for the **code** — a rewrite would discard real assets to rebuild the same UX failure in a new stack. What genuinely changed is the **audience**, and an audience change does not require a code rewrite.

A competitive survey of nine self-hosted / open-source trackers was run to learn how the field solves these three failures ([`docs/research/competitive-trackers-2026-08.md`](../../research/competitive-trackers-2026-08.md)). The load-bearing finding: **no self-hosted tracker has solved the data-entry chore** — Ghostfolio, Portfolio Performance, and Wealthfolio all fall back to CSV + manual entry; automated sync always sits behind a paid aggregator. **Maybe Finance — the same Rails/Hotwire/Postgres stack as Stockerly — died partly because a VC-funded consumer-finance app could not sustain the Plaid aggregator cost model.** That is `[[feedback-cost-justified-tech]]` written in someone else's blood.

## Decision

**Pivot in place. No deprecation, no rewrite.** Reframe Stockerly as a **self-hosted, single-user asset tracker** for one person (Adrian, dogfood), packaged from day one so any technically capable person can stand it up with one command and understand it without a manual. MXN/MX-first (multi-currency MXN/USD, CETES, Banxico FX) stays the differentiator.

Concretely:

1. **Audience** drops the closed-beta secondary. The primary user is Adrian; "self-hosted for a technical third party" is a *packaging discipline*, not a managed audience. Building for a hypothetical self-hosting community is the next audience-fantasma and is explicitly rejected (`[[feedback-anti-patterns]]` #2).

2. **Aggressive subtraction.** The 2.0 begins by deleting what the multi-user/beta framing required and the single-user product does not: most of the `Administration` context (invites, user management, `pool_keys`), the multi-user surface of `Identity` (registration, email verification, first-admin bootstrap), and the models `invite_code`, `api_key_pool`, `remember_token`, `email_event`, `user_activity`. `Identity` collapses to a single-user login/setup. `Notifications` shrinks to in-app only. `MarketData` and `Trading` are kept and reinvested in. The hexagonal boundaries make this deletion clean.

3. **No aggregators, ever, at this scale.** Plaid/Yodlee/SnapTrade and equivalents are a permanent non-goal. They are a cost trap that helped kill a same-stack competitor and have thin, expensive Mexican coverage. (Pluggy.ai / Belvo are the only LatAm-native aggregators with real MX coverage, and even they are gated behind a documented trigger, not adopted now.)

4. **Data-entry strategy = make manual/CSV not feel like a chore**, not chase magic sync. Priority order (full ranking in the research doc): (1) holdings-snapshot entry with a *skip-history* default, (2) smart CSV import (heuristic column mapping, MX date/number formats, idempotency), (3) manual entry made pleasant — ticker autocomplete, **Banxico FX auto-filled at trade date** (which simultaneously resolves the P0 `currency: "USD"` hardcode), learned rules. Read-only crypto exchange keys / wallet addresses (Rotki's model) and AI PDF-statement import (Kubera's) are attractive but require a documented trigger + JTBD before any work (`[[feedback-anti-patterns]]` #1).

5. **The three failures are the actual product work**, addressed with cheap, high-leverage patterns from the survey: a seeded MXN/USD+CETES demo so first-run is never blank (failure #1), inline `?`-tooltips explaining each indicator in one sentence plus one distilled signal metric (failure #2), snapshot + skip-history + learned rules so manual entry decays (failure #3).

What is preserved from the prior vision: ADR-0001 descriptive-not-prescriptive language, the fiscal-out-of-scope boundary, and MXN/USD multi-currency as a first-class citizen.

## Consequences

**Positive.** The 2.0 is mostly a *subtraction* (roughly half the app is deleted), which is cheap and low-risk versus a rewrite. Real assets are preserved. A single-user self-hosted tool is simpler than a multi-user beta, and the current Rails + Postgres stack already fits self-hosted single-instance deployment. Fixing the P0 FX-at-execution bug now doubles as a data-entry improvement.

**Negative / risks.** "Self-hosted for anyone" can regress into building for users who do not exist — mitigated by dogfooding for Adrian first and treating third-party self-hosting as packaging discipline. Deleting `Administration`/`Identity` surface is irreversible-in-spirit (recoverable via git) and must be done deliberately, context by context. The MX-first choice keeps the audience narrow by design.

**Rollback.** If, while executing the subtraction, the architecture is found to actively fight the single-user self-hosted goal (not expected), reconsider deprecation — with evidence, not before. Deleted code remains in git history.

**Documentation follow-up.** `docs/vision/` (README, audience, non-goals) is rewritten in the same change; the beta-specific `jobs-to-be-done.md` JTBDs largely survive, with JTBD #5 (sub-30-second trade capture) promoted to central given the data-entry finding.

## Addendum — 2026-08-22 (evidence from the code audit)

A 5-stage parallel code audit + a 7-expert panel confirmed the "subtract, don't rewrite" bet with evidence (all 5 stages: EVOLVE). Two factual corrections to this ADR:

- **The P0 FX-at-execution bug is already FIXED**, not pending. `execute_trade.rb` captures `fx_rate_at_execution`; FX-weighted cost basis + honest gain + currency-coherent snapshots are implemented and tested (`multi_currency_audit_spec.rb`). Only the *backdated-trade* FX refinement (Banxico TC at the trade's date) remains — a refinement, not a foundation bug. References above to "fixing the P0" should be read as already-done.
- **`api_key_pool` must NOT be deleted with the multi-user models.** It is MarketData plumbing — `KeyRotation.next_key_for` feeds 7 gateways (incl. Banxico). Deleting it as-is dark-fails all external data sourcing. Reclassify as **rework** (collapse the pool to a single key per provider), not deletion. The multi-user delete list is otherwise correct and FK-clean.

The EVOLVE execution runs on branch `evolve_2_0_pre` (baseline tag `pre-2.0-evolve`).
