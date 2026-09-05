# Audit 02 — Use Case + Contract + Domain layer

**Scope:** `app/contexts/*/use_cases/`, `*/contracts/`, `*/domain/` across all 6 bounded contexts.
**Method:** read-only. Every line number verified against the working tree at commit `5cacab1`
(branch `fix/capture-daily-volume`).

**Inventory:** 74 use cases — **50 `ApplicationUseCase`**, **24 `SimpleUseCase`**. 16 contracts.
**Dead code check:** every use case class was grepped against `app/`, `lib/`, `config/`.
**No dead use cases found** — `MarketData::UseCases::SearchTickers` looks orphaned from
controllers but is called at `administration/use_cases/assets/search_ticker.rb:36`. One dead
*model* helper is reported below (UC-13).

Findings are ranked by severity, then by blast radius.

---

### [UC-01] `UpdateTrade` recounts discarded trades into position shares — silent data corruption
- **Severity:** P0
- **Effort:** S
- **Where:** `app/contexts/trading/use_cases/update_trade.rb:60` vs `app/contexts/trading/use_cases/delete_trade.rb:39`
- **Evidence:**
  ```ruby
  # update_trade.rb:60
  remaining = position.trades.where(side: :buy).sum(:shares) - position.trades.where(side: :sell).sum(:shares)

  # delete_trade.rb:39 — the same method, one word different
  remaining = position.trades.kept.where(side: :buy).sum(:shares) - position.trades.kept.where(side: :sell).sum(:shares)
  ```
  `Position#recalculate_avg_cost!` (`app/models/position.rb:51`) also scopes to `.kept`.
- **Why it matters:** `recalculate_position` was copy-pasted between the two use cases and the
  copies drifted. Edit any trade on a position that has ever had a trade deleted, and
  `position.shares` is recomputed **including the discarded rows**. `avg_cost` is recomputed
  correctly (`.kept`), so shares and cost basis end up describing different sets of trades. Every
  downstream figure — `market_value`, `PortfolioSummary#total_value`, `RealizedGain`, the
  snapshots `RebuildSnapshots` writes — inherits the error, and nothing ever corrects it because
  no later path re-derives shares from `kept`. A closed position can also be forced back to
  `status: :open` (line 64) by phantom shares.
- **Recommendation:** extract one `Trading::Domain::PositionSettlement.recalculate!(position)`
  used by `UpdateTrade`, `DeleteTrade` and `UndoImport#settle`
  (`undo_import.rb:28-34`, a third near-copy that *does* use `.kept`). Delete the three private
  copies. Add a spec that deletes a trade, edits a sibling trade, and asserts `position.shares`.

> **C1 Lucía:** Esto no es un bug de estilo, es la cantidad de títulos que crees tener.
> El `avg_cost` sale de `.kept` y las `shares` no — la posición queda internamente incoherente y
> el error se congela en el snapshot de ese día. Para un tracker cuyo único valor es que los
> números cuadren, este es el peor bug del layer.

---

### [UC-02] The setup wizard seeds a fabricated USD/MXN rate that portfolio valuation reads as truth
- **Severity:** P0
- **Effort:** M
- **Where:** `app/contexts/identity/use_cases/create_first_admin.rb:80-93`; consumed via `app/models/portfolio.rb:87,95`
- **Evidence:**
  ```ruby
  # create_first_admin.rb:81-85
  pairs = [
    { base_currency: "USD", quote_currency: "EUR", rate: 0.92 },
    { base_currency: "USD", quote_currency: "MXN", rate: 17.25 },
    { base_currency: "USD", quote_currency: "GBP", rate: 0.79 }
  ]
  ```
  ```ruby
  # portfolio.rb:93-95 — history miss falls back to the seeded row
  def historical_rate(from, to, date)
    fx_rate_cache[[from, to, date]] ||=
      FxRateHistory.rate_on(base: from, quote: to, date: date) || current_rate(from, to)
  ```
- **Why it matters:** `Portfolio#convert` raises `MissingFxRate` when there is no rate — the whole
  fail-loud design the multi-currency work landed. Seeding `FxRate` at first boot **defeats that
  guard**: a fresh self-hosted instance whose FX sync has not run yet will happily value every USD
  holding at a hardcoded 17.25 and every historical date at the same number, and the screen will
  say nothing, because `fx_unavailable` is only set when `MissingFxRate` is raised. The
  differentiator of the product ("TC histórico correcto") silently becomes a constant from
  whenever this line was written.
- **Recommendation:** delete `create_fx_rates!` entirely. Let the first `SyncFxHistory` /
  `RefreshFxRatesJob` populate it; `MissingFxRate` + the `fx_unavailable` banner is the correct,
  already-built behaviour for the gap. Separately: `create_market_indices!` and
  `create_integrations!` are MarketData/Administration writes performed by an **Identity** use
  case through direct AR access — the `FirstAdminCreated` event already exists and already has a
  handler; bootstrap belongs there.

> **C1 Lucía:** Un tipo de cambio inventado es peor que un error. El error lo ves; el 17.25 se
> mezcla con los reales y ya no sabes qué renglón es cierto. Y como cae en el fallback de
> `historical_rate`, contamina también trades de hace dos años.

---

### [UC-03] ADR-006 inverted: 24 of 50 `ApplicationUseCase` subclasses use none of its three features
- **Severity:** P1
- **Effort:** L
- **Where:** verified list below; representative callers at
  `app/controllers/alerts_controller.rb:5-6`, `app/controllers/onboarding_controller.rb:20,32,44`,
  `app/jobs/send_daily_digest_job.rb:9-13`, `app/jobs/detect_technical_observations_job.rb:9-13`
- **Evidence:** ADR-006's own rule: *"If a use case has zero `yield`, zero `validate`, zero
  `publish`, and zero pattern-matched callers, it is a `SimpleUseCase`."* Twenty-four fail all
  three code tests. Eleven of those also **never return a `Failure` at all**, so the `Success(...)`
  wrapper is pure ceremony:

  `administration/.../logs/list_logs.rb` · `.../errors/list_errors.rb` ·
  `.../onboarding/launch_initial_sync.rb` · `.../onboarding/save_api_keys.rb` ·
  `.../onboarding/seed_assets.rb` · `alerts/use_cases/load_dashboard.rb` ·
  `alerts/use_cases/evaluate_date_based_rules.rb` ·
  `market_data/use_cases/detect_technical_observations.rb` ·
  `market_data/use_cases/notify_approaching_earnings.rb` ·
  `notifications/use_cases/send_daily_digest.rb` ·
  `trading/use_cases/notify_approaching_maturities.rb`

  The ceremony is visibly dead at the call sites:
  ```ruby
  # alerts_controller.rb:5-6 — value! on a use case with no Failure branch
  result = Alerts::UseCases::LoadDashboard.call(user: current_user, filter: params[:filter])
  data = result.value!

  # onboarding_controller.rb:20 — the Result is discarded outright
  Administration::UseCases::Onboarding::SaveApiKeys.call(keys: keys)

  # send_daily_digest_job.rb:11-12 — an unreachable branch
  log_sync_failure("Daily Digest", result.failure[1])
  ```
- **Why it matters:** this is anti-pattern #3, and it is now the *majority* shape in the layer, not
  the exception ADR-006 set out to remove. The concrete cost is the dead-branch problem above:
  four jobs contain `else log_sync_failure(result.failure[1])` handlers that can never run, which
  reads as "failures are logged" and means "failures crash the job". ADR-006's own "Deferred"
  section admits the follow-up audit was never run — this is it.
- **Recommendation:** convert the 11 no-Failure cases to `SimpleUseCase` returning their raw hash /
  count, and delete the unreachable `else` branches in the jobs at the same time (they are the
  actual bug). Leave the 13 that return real `Failure` tuples — those have pattern-matched callers
  and belong on `ApplicationUseCase` even without `yield`.

> **C2 Hiroto:** The ADR is correct and the codebase drifted from it in the same direction it
> drifted before the ADR was written. That means the criterion is not being applied at write time.
> A rule nobody consults is a document, not an architecture — pin it with an audit script or accept
> that it will drift again next sprint.

---

### [UC-04] `MarketData` reads Trading's ActiveRecord models — the ADR-002 direction is now violated
- **Severity:** P1
- **Effort:** M
- **Where:** `app/contexts/market_data/use_cases/notify_approaching_earnings.rb:35-36`
- **Evidence:**
  ```ruby
  def users_watching(asset)
    user_ids = WatchlistItem.where(asset: asset).pluck(:user_id)
    position_user_ids = Position.where(asset: asset, status: :open).joins(:portfolio).pluck("portfolios.user_id")
    User.where(id: (user_ids + position_user_ids).uniq)
  end
  ```
- **Why it matters:** ADR-002 §Forbidden is explicit: *"MarketData reading Trading ActiveRecord
  models or domain services. No `Portfolio.find`, no `Trading::Domain::*` call from
  `app/contexts/market_data/`."* Its Context section claims *"MarketData no longer reads from
  Trading anywhere"* — that statement is false as of today, and this is the **only** instance
  (verified by grep across `market_data/`, `alerts/`, `notifications/`). One violation is cheap to
  fix; leaving it makes the ADR non-load-bearing and the next one costs nothing to add.
- **Recommendation:** invert the direction, which is also where the code belongs: the sibling
  `Trading::UseCases::NotifyApproachingMaturities` already lives in Trading and asks Trading's own
  models. Move earnings notification to Trading (it reads `EarningsEvent` through a
  `MarketData::Queries::UpcomingEarnings` read API, which is the sanctioned direction), or have
  MarketData publish `EarningsApproaching` and let a Trading handler fan it out to holders.
  Note the same method is an N+1 (`already_notified?` at line 40 queries per user per event) where
  the Trading twin pre-fetches in one query (`notify_approaching_maturities.rb:57-66`).

---

### [UC-05] `consolidated_summary` copy-pasted three times, and one copy has already diverged
- **Severity:** P1
- **Effort:** S
- **Where:** `trading/use_cases/assemble_panorama.rb:39-48` · `trading/use_cases/assemble_consolidado.rb:71-78` · `trading/use_cases/load_assets.rb:40-48`
- **Evidence:**
  ```ruby
  # assemble_panorama.rb:39-48 and assemble_consolidado.rb:71-78 — identical
  summary = Trading::Domain::PortfolioSummary.new(portfolio, currency: currency)
  summary.total_value
  summary.day_gain          # <- present in both
  summary
  rescue Trading::Domain::MissingFxRate
    nil

  # load_assets.rb:40-48 — the same method, minus one line
  summary.total_value
  summary                   # <- day_gain NOT forced
  ```
  The comment at `assemble_panorama.rb:37-38` names exactly the bug the missing line reintroduces:
  *"Valuing here is the load-bearing part: AssembleDashboard built the summary lazily, so
  `Portfolio#convert` raised in the template instead."*
- **Why it matters:** the third copy is one `<%= summary.day_gain %>` away from a 500 on `/assets`.
  Today `app/views/assets/` does not call it (verified), so this is latent, not live — but the
  divergence proves the copies are already unmaintained, and the fix that landed in two of them
  never reached the third.
- **Recommendation:** `Trading::Domain::PortfolioSummary.valued(portfolio, currency:)` — a class
  method that builds, forces both figures, and returns `nil` on `MissingFxRate`. Three call sites
  become one line each. See UC-06 for the wider version of the same problem.

---

### [UC-06] The "a missing FX rate degrades the figure, not the page" policy is re-decided in 9 places
- **Severity:** P1
- **Effort:** M
- **Where:** `assemble_consolidado.rb:54,76,98,126` · `assemble_panorama.rb:46` · `assemble_historial.rb:40` · `load_assets.rb:46,65` · `load_asset_position.rb:33`
- **Evidence:** nine `rescue MissingFxRate` sites, each choosing its own fallback with no shared
  rule: `nil` (summary), `{}` (allocation, `assemble_consolidado.rb:52-56`), `0` (series value,
  `:96-100`; hold value, `:123-128`), `nil` (per-row gain, `assemble_historial.rb:38-41`), `nil`
  (sort key, `load_assets.rb:60-67`).
- **Why it matters:** the policy is real and correct — but it lives nowhere. Each of the nine
  authors re-derived it, and one of them (`load_assets.rb:65`) silently degrades **sort order** on
  a rate miss, which is a different kind of degradation from "show a dash" and is invisible to the
  reader. Zero of the nine sites are in `domain/`; a policy about what money means when a rate is
  missing is the definition of domain logic.
- **Recommendation:** one domain seam — e.g. `Trading::Domain::Money.safely(fallback) { ... }`, or
  a `Portfolio#try_convert` returning `nil` — so the fallback is chosen once per *kind* of figure
  rather than once per call site. Keep the raising `convert` for calculations; the safe variant is
  for the read path.

> **C2 Hiroto:** Nine rescues is not duplication, it is a missing concept. `MissingFxRate` is a
> domain event in the small — the domain should say what a portfolio is worth when a rate is
> unknown, not each screen separately.

---

### [UC-07] Contracts restate their models' validations — six overlaps in one pair
- **Severity:** P1
- **Effort:** M
- **Where:** `app/contexts/alerts/contracts/create_contract.rb` vs `app/models/alert_rule.rb`
- **Evidence:**
  | Rule | Contract | Model |
  |---|---|---|
  | condition whitelist (9 values) | `create_contract.rb:4-14` | enum `alert_rule.rb:10-20` |
  | `MARKETWIDE_CONDITIONS` | `:17` | `:38` |
  | `DATE_BASED_CONDITIONS` | `:21` | `:23` |
  | asset_symbol required unless marketwide | `:30-33` | `:41` |
  | threshold_value required unless date_based | `:35-38` | `:42` |
  | window_days ≥ 1 | `:40-44` | `:43` |

  Two of these are *literal duplicate constant definitions* of the same frozen array.
- **Why it matters:** adding a condition means editing the enum, `DATE_BASED_CONDITIONS`,
  `MARKETWIDE_CONDITIONS` and the contract's three private copies. Miss the contract's
  `ALLOWED_CONDITIONS` and a valid enum value is rejected at the form with no error anyone can
  trace to a whitelist. The enum already skips integers 5 and 6, so the two lists have drifted at
  least once before.
- **Recommendation:** the contract should reference the model's constants
  (`included_in?: AlertRule.conditions.keys`, `AlertRule::MARKETWIDE_CONDITIONS`) and keep only
  what dry-validation adds that AR cannot: type coercion and cross-field shape. Same treatment for
  `Trading::Contracts::UpdateTradeContract:21` (`Trade.exists?`) and
  `Administration::Contracts::Assets::CreateContract:20-22` (`Asset.exists?` duplicating the
  model's `uniqueness:` — and note the contract's check is case-**sensitive** while the model's is
  `case_sensitive: false`, so the two disagree on `aapl` vs `AAPL`).

---

### [UC-08] `Failure([:validation, …])` carries five different payload types
- **Severity:** P1
- **Effort:** M
- **Where:** `application_use_case.rb:12` · `identity/use_cases/reset_password.rb:11,16` · `market_data/use_cases/search_tickers.rb:10` · `administration/use_cases/assets/track_missing_symbols.rb:13` · `administration/use_cases/assets/map_provider_symbol.rb:13` · `identity/use_cases/create_first_admin.rb:25`
- **Evidence:** one tag, five shapes:
  | Payload | Site |
  |---|---|
  | `Hash` of dry-validation errors | `application_use_case.rb:12` (the canonical one) |
  | `Hash` from `record.errors.to_hash` | `create_first_admin.rb:25`, `create_asset.rb:41`, +5 more |
  | **An ActiveRecord object** | `reset_password.rb:11,16` |
  | `String` | `search_tickers.rb:10`, `track_missing_symbols.rb:13` |
  | `Symbol` | `map_provider_symbol.rb:13` |

  And one tuple has no payload at all: `reset_password.rb:6` → `Failure([:invalid_token])`, a
  1-element array where every other failure in the codebase is 2 elements.
- **Why it matters:** callers cannot pattern-match on the tag alone. The evidence is already in the
  controllers: `assets_controller.rb:100-102` carries a `first_error(errors)` shim
  (`errors.is_a?(Hash) ? errors.values.flatten.first : errors`) that exists purely to normalise
  this, and `password_resets_controller.rb:39` destructures `Failure[:validation, user]` into
  `@user` — a shape no other controller can share. `result.failure.last` at
  `assets_controller.rb:59` returns a `Symbol` for one path and a `String` for another.
- **Recommendation:** fix the payload contract to one type — a `Hash{field => [messages]}` — and
  convert the outliers. `reset_password` should return `Failure([:validation, errors_hash])` and
  let the controller re-attach to `@user` (its `attach_errors` helper already does the mapping, it
  just does it on the wrong side of the boundary). Give `:invalid_token` a message so the tuple
  arity is uniform. Document the shape in `conventions.md` — it is not written down anywhere today.

> **C3 Sven:** dry-monads gives you exhaustive pattern matching for free and this throws it away.
> The moment `Failure[:validation, x]` can be a Hash *or* a String *or* an AR record, every `case`
> becomes defensive and you are back to `if result.success?`. Pick the Hash, convert five files,
> delete `first_error`.

---

### [UC-09] Use cases return the gateway's Result verbatim, leaking provider failure tags upward
- **Severity:** P1
- **Effort:** S
- **Where:** `market_data/use_cases/search_tickers.rb:12` · `market_data/use_cases/sync_articles.rb:9`
- **Evidence:**
  ```ruby
  # search_tickers.rb:12 — no wrapping, no mapping
  Gateways::YfinanceGateway.new.search_tickers(query.strip)

  # sync_articles.rb:9
  return result if result.failure?
  ```
  Reaching, via `administration/.../search_ticker.rb:36` (`yield`), all the way to
  `assets_controller.rb:59`: `render json: { error: result.failure.last }`.
- **Why it matters:** the use case is supposed to be MarketData's public API (ADR-002 names
  `SearchTickers` as the precedent for exactly that). Instead it publishes the gateway's private
  vocabulary — `:gateway_error`, `:timeout`, `:parse_error`, `:not_found`, `:rate_limited` — as its
  own contract, and `result.failure.last` renders a raw Faraday exception message into a JSON
  response the user sees. Swapping Yahoo for another provider changes the use case's failure
  surface, which is the coupling the read API existed to prevent.
- **Recommendation:** map gateway failures onto a small, stable set at the use-case boundary
  (`:unavailable`, `:no_results`) and never render `failure.last` directly — the message is for the
  log, not the screen.

---

### [UC-10] `ImportTrades` is 239 lines doing six jobs; the domain objects it needs already have names in its own comments
- **Severity:** P1
- **Effort:** L
- **Where:** `app/contexts/trading/use_cases/import_trades.rb`
- **Evidence:** one class holds: row validation (`:55-63`), symbol resolution including the
  `former_symbols` alias rules (`:80-102`), FX pre-resolution (`:104-118`), idempotency
  partitioning (`:120-125`), the whole persistence replay (`:130-200`), and report assembly
  (`:218-230`). `call` alone threads 5 locals through 8 collaborators; `Batch = Data.define(...)`
  at `:17` was introduced specifically because *"they were threaded as four parameters through
  five methods"* — the smell was diagnosed and then treated with a parameter object instead of a
  boundary.
- **Why it matters:** the resolution rules here are genuinely subtle and genuinely important —
  `by_former_symbol` (`:96-102`) encodes "a live SATS must win over a retired ECHO", and the
  comment says a *previous* independent copy of that query got it wrong. That rule cannot be
  unit-tested today without constructing a full import batch, which is why the wrong copy survived.
  Same for the FX pre-resolution at `:107-118`, which is the piece that makes a backdated import
  correct.
- **Recommendation:** extract three domain objects with their own specs, in this order of value:
  `Trading::Domain::SymbolResolver` (`:80-102`, the alias precedence rule),
  `Trading::Domain::BatchExecutionRates` (`:104-118`), and `Trading::Domain::ImportReport`
  (`:218-230`). The use case keeps orchestration: validate → resolve → partition → commit →
  after_commit. That is the shape it already advertises at `:19-37`; the extraction just makes it
  true.

> **C2 Hiroto:** The header comment argues correctly that an import is not fifty `ExecuteTrade`
> calls — batch invariants are real. But "the batch owns different invariants" is an argument for a
> batch *domain model*, not for a 239-line use case. Right now the invariants are enforced by
> reading the file top to bottom.

---

### [UC-11] Business rules parked in use cases: signal detection, text similarity, provider mapping, and a `method_missing` decorator
- **Severity:** P2
- **Effort:** L
- **Where:**
  - `market_data/use_cases/detect_technical_observations.rb:70-119` — RSI/MA/Bollinger transition rules
  - `market_data/use_cases/sync_articles.rb:48-70` — Dice-coefficient near-duplicate detection
  - `administration/use_cases/assets/search_ticker.rb:5-33,45-68` — provider→domain mapping tables
  - `alerts/use_cases/evaluate_rules.rb:31-39` — `AssetPriceProxy`, a `method_missing` decorator
  - `market_data/use_cases/load_asset_detail.rb:84-106` — `build_yield_data`, CETES yield maths
- **Evidence:** `detect_technical_observations.rb` calls `Domain::TechnicalIndicators` for the
  arithmetic but keeps the *thresholds and transition semantics* in the use case:
  ```ruby
  events << { type: "rsi_oversold_entered", snapshot: snap } if rsi_prev >= 30 && rsi_now < 30
  ```
  `sync_articles.rb:61-70` is a pure function (`dice_coefficient`) private to a use case whose
  other job is HTTP + persistence.
- **Why it matters:** these are the rules that decide what the product *says* — ADR-013 makes the
  persisted `TechnicalObservation` the sole licence for prescriptive copy, so the thresholds at
  `:77-80` are the ADR's actual enforcement point, and they are unreachable from a unit test
  without stubbing an `Asset` with 210 price rows. `build_yield_data` computes CETES discount
  prices inside a *read* use case, mixing money maths with page assembly.
- **Recommendation:** `Domain::IndicatorTransitions.detect(closes)` returning the event list (the
  use case keeps the loop, dedup and persistence); `Domain::TitleSimilarity`; move `SearchTicker`'s
  two lookup tables into `Administration::Domain::ProviderSymbolMap`; move `build_yield_data` into
  the existing `Domain::YieldCalculator`. Delete `AssetPriceProxy` — pass the old price as an
  argument to `AlertEvaluator` instead; `method_missing` delegation will swallow a typo'd method
  as a `NoMethodError` on the wrong object.

---

### [UC-12] `SplitAdjuster` and `UndoImport` rewrite positions and trades outside a transaction
- **Severity:** P2
- **Effort:** S
- **Where:** `trading/domain/split_adjuster.rb:12-40` · `trading/use_cases/undo_import.rb:12-24`
- **Evidence:**
  ```ruby
  # split_adjuster.rb:15-24 — per-row lock, no enclosing transaction
  positions.find_each { |position| position.with_lock { position.update!(...) } }
  adjust_trades!
  ```
  ```ruby
  # undo_import.rb:19-21
  removed = trades.destroy_all.size
  positions.each { |position| settle(position) }
  Trading::UseCases::RebuildSnapshots.call(portfolio: portfolio, from: earliest)
  ```
  Compare `import_trades.rb:133` — the write path that *does* wrap itself in
  `ActiveRecord::Base.transaction`, with a comment (`:202-203`) explaining why events and
  snapshots are deliberately kept outside it.
- **Why it matters:** `with_lock` opens a transaction **per position** — it prevents concurrent
  writes to one row and provides no atomicity across the batch. A `RecordInvalid` on the fourth
  position leaves three positions adjusted for the split and every trade unadjusted: shares
  multiplied, prices not divided, cost basis wrong by the split ratio with no marker saying so.
  `UndoImport` has the same exposure between `destroy_all` and `settle`.
- **Recommendation:** wrap `SplitAdjuster#adjust!` and `UndoImport`'s destroy+settle in one
  `ActiveRecord::Base.transaction`, keeping `RebuildSnapshots` outside it exactly as `ImportTrades`
  does. Separately: `SplitAdjuster` writes to two tables and publishes nothing — it is a use case
  wearing a `domain/` filename; the handler at `trading/handlers/adjust_positions_on_split.rb:11`
  should be calling `Trading::UseCases::AdjustPositionsForSplit`.

---

### [UC-13] `ExecuteTrade` and `UpdateTrade` guard the same column with different rules; the shared helper is dead
- **Severity:** P2
- **Effort:** S
- **Where:** `trading/contracts/execute_trade_contract.rb:38-52` vs `trading/contracts/update_trade_contract.rb:9` · `trading/use_cases/execute_trade.rb:131-137` vs `update_trade.rb:68-74` · `app/models/trade.rb:28-32`
- **Evidence:**
  - `ExecuteTradeContract:38-52` rejects an unparseable `executed_at` and rejects a future date
    (with es-MX messages). `UpdateTradeContract:9` declares `optional(:executed_at).maybe(:string)`
    and validates nothing — so **editing** a trade can set a date 90 days out, which is precisely
    what the `ExecuteTrade` rule's comment says was a bug worth fixing.
  - `parse_executed_at` is byte-identical in `execute_trade.rb:131-137` and
    `update_trade.rb:68-74`, and both silently coerce a bad value to `Time.current`.
  - The 30-day window exists three times: `UpdateTrade::MAX_EDIT_AGE_DAYS`,
    `DeleteTrade::MAX_DELETE_AGE_DAYS`, and `Trade::MODIFICATION_WINDOW` (`trade.rb:28`) — whose
    comment claims it is *"the view-facing predicate so templates don't repeat the time-arithmetic
    rule"*. **`Trade#editable?` and `MODIFICATION_WINDOW` have zero callers** in `app/`, `lib/`,
    `config/` or `spec/` (verified by grep). The deduplication it was written for never happened.
- **Why it matters:** two write paths to the same column, one guarded and one not. And a constant
  documented as the single source of truth that nothing reads is worse than no constant — the next
  reader will trust the comment.
- **Recommendation:** add the `executed_at` rule to `UpdateTradeContract` (extract it into a shared
  `Trading::Contracts::ExecutedAtRule` macro or a plain module); move `parse_executed_at` to a
  domain helper or drop it once the contract guarantees the format; delete `Trade#editable?` and
  `MODIFICATION_WINDOW`, or make the two use cases reference the constant and use the predicate.

---

### [UC-14] Spanish date/copy formatting hand-rolled twice, in two contexts, with divergent behaviour
- **Severity:** P2
- **Effort:** S
- **Where:** `trading/use_cases/notify_approaching_maturities.rb:68-85` vs `market_data/use_cases/notify_approaching_earnings.rb:48-58`
- **Evidence:**
  ```ruby
  # both files, verbatim
  MONTHS_ES = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze
  ```
  ```ruby
  # maturities.rb:83-85 — with year
  "#{date.day} #{MONTHS_ES[date.month - 1]} #{date.year}"
  # earnings.rb:50-52 — without year
  "#{date.day} #{MONTHS_ES[date.month - 1]}"
  ```
  ```ruby
  # maturities.rb:79-81 — no "hoy" branch
  days == 1 ? "mañana" : "en #{days} días"
  # earnings.rb:54-58 — has one
  return "hoy" if days == 0
  ```
- **Why it matters:** the notification a user reads is assembled by string interpolation in a use
  case, in two places, with two different date formats and two different day-0 behaviours. ADR-011
  puts user-facing copy in `config/locales/es-MX.yml` behind lazy lookups; Rails already ships
  `l(date, format: :short)` with an es-MX locale. `notify_approaching_maturities.rb:79-81` will also
  render *"en 0 días"* if a maturity lands on day 0 (the query at `:44` excludes it today, so this
  is guarded by a comment rather than by the code that formats it).
- **Recommendation:** move both titles and bodies into `es-MX.yml` with interpolation and use
  `I18n.l` for the dates. Delete both `MONTHS_ES`. This is a redesigned surface (notifications
  ship es-MX copy today), so ADR-011's "surface by surface" carve-out does not exempt it.

> **C3 Sven:** Two copies of a month array in two bounded contexts is the cheapest possible
> finding to fix and the most reliable predictor that a third will appear.

---

### [UC-15] The wizard's API-key write has no contract and takes `to_unsafe_h`
- **Severity:** P2
- **Effort:** S
- **Where:** `app/controllers/onboarding_controller.rb:19-20` → `administration/use_cases/onboarding/save_api_keys.rb:5-20`
- **Evidence:**
  ```ruby
  # onboarding_controller.rb:19
  keys = params[:api_keys]&.to_unsafe_h || {}
  Administration::UseCases::Onboarding::SaveApiKeys.call(keys: keys)
  ```
  ```ruby
  # save_api_keys.rb:8-16 — no contract, no validation, iterates arbitrary keys
  keys.each do |integration_id, api_key_value|
    integration = Integration.find_by(id: integration_id)
    integration.update!(api_key_encrypted: api_key_value)
    integration.update!(connection_status: :connected) unless integration.connected?
  ```
- **Why it matters:** the least-validated write path in the app writes encrypted provider
  credentials. `find_by(id:)` + `next unless` means unknown ids are ignored rather than reported,
  so a malformed form silently saves nothing and the wizard still advances (`redirect_to` on
  line 21, Result discarded). It also stamps `connection_status: :connected` for a key nobody
  verified — `RefreshSync` and the gateways then treat an untested credential as working. Two
  `update!` calls where one would do.
- **Recommendation:** an `Onboarding::SaveApiKeysContract` typing the hash as
  `integer => filled string`, `permit`ed params instead of `to_unsafe_h`, one `update!`, and a
  count in the Result the controller actually surfaces ("2 de 4 integraciones guardadas").
  `connected` should be set by a successful probe, not by the presence of a string.

---

### [UC-16] Ceremony noise: `_ = yield publish(...)`, a `yield` on a method that cannot fail, and three publishing styles
- **Severity:** P2
- **Effort:** S
- **Where:** publish styles: `create_asset.rb:10`, `create_first_admin.rb:10`, `update_info.rb:8`, `change_password.rb:8`, `connect_provider.rb:8`, `delete_provider.rb:10`, `update_provider.rb:9`, `export_csv.rb:10` (all `_ = yield publish`) vs `execute_trade.rb:20`, `import_trades.rb:210`, `sync_cetes.rb:19` etc. (bare `publish`) vs `evaluate_rules.rb:22`, `evaluate_date_based_rules.rb:20`, `create_notification.rb:16` (direct `EventBus.publish`). Pointless yield: `execute_trade.rb:15,42-48`.
- **Evidence:**
  ```ruby
  # application_use_case.rb:15-18 — publish ALWAYS returns Success
  def publish(event) = (EventBus.publish(event); Success(event))
  ```
  ```ruby
  # execute_trade.rb:15 + 42-48 — a yield over a method whose only statement is Success(...)
  fx_rate = yield capture_fx(trade_currency, attrs)
  def capture_fx(currency, attrs)
    Success(Trading::Domain::ExecutionRate.capture(...))
  end
  ```
- **Why it matters:** eight `_ = yield` on an infallible call, and a `Success`-wrap-then-`yield`
  round trip whose only effect is to make a plain assignment look fallible. Three different ways to
  publish an event in one layer means a reader cannot tell whether `EventBus.publish` at
  `evaluate_rules.rb:22` is deliberate (bypassing the helper) or an oversight. It is anti-pattern
  #3 at its smallest and cheapest to fix.
- **Recommendation:** `publish(event)` bare everywhere; drop the `_ = yield`; convert the three
  `EventBus.publish` sites to the helper; inline `capture_fx` to
  `fx_rate = Trading::Domain::ExecutionRate.capture(...)`. Note `execute_trade.rb` also queries
  `Asset` three times per trade for the same symbol — `execute_trade_contract.rb:31`
  (`Asset.exists?`), `:60` (`Asset.find_by`), and `execute_trade.rb:9` (`Asset.find_by!`) — and the
  `find_by!` raises `RecordNotFound` inside a use case that otherwise returns `Failure` tuples, a
  fourth failure shape for `trades_controller.rb:27-32` to not handle.

---

## Summary

| ID | Title | Sev | Effort |
|---|---|---|---|
| UC-01 | `UpdateTrade` recounts discarded trades into position shares | P0 | S |
| UC-02 | Setup wizard seeds a fabricated USD/MXN rate | P0 | M |
| UC-03 | ADR-006 inverted — 24/50 use cases carry unused monad ceremony | P1 | L |
| UC-04 | MarketData reads Trading's AR models (ADR-002 violation) | P1 | M |
| UC-05 | `consolidated_summary` triplicated, one copy diverged | P1 | S |
| UC-06 | `rescue MissingFxRate` policy re-decided in 9 places | P1 | M |
| UC-07 | Contracts restate model validations (6 overlaps in one pair) | P1 | M |
| UC-08 | `Failure([:validation, …])` carries 5 payload types | P1 | M |
| UC-09 | Gateway Results returned verbatim from use cases | P1 | S |
| UC-10 | `ImportTrades` — 239 lines, 6 responsibilities | P1 | L |
| UC-11 | Domain rules parked in use cases (signals, similarity, mapping) | P2 | L |
| UC-12 | `SplitAdjuster` / `UndoImport` mutate outside a transaction | P2 | S |
| UC-13 | Two write paths to `executed_at`, one unguarded; dead shared helper | P2 | S |
| UC-14 | `MONTHS_ES` + es-MX copy hand-rolled twice, divergently | P2 | S |
| UC-15 | Wizard API-key write: no contract, `to_unsafe_h` | P2 | S |
| UC-16 | `_ = yield publish`, infallible yields, three publish styles | P2 | S |

**Not found (verified, worth stating):**
- **No dead use cases.** All 74 have a caller in `app/`, `lib/` or `config/`.
- **Failure *tags* are consistent.** Almost every failure is `Failure([:tag, payload])` with a
  sensible tag; the problem is the payload (UC-08) and two arity outliers, not the convention.
  Two gateway-tag leaks (UC-09) and one `find_by!` (UC-16) are the only non-tuple failure paths.
- **`SyncFxHistory` / `SyncCetesHistory`** (`sync_fx_history.rb`, `sync_cetes_history.rb`) are the
  best-shaped use cases in the layer — injected gateway, `yield` on a genuinely fallible call, one
  typed failure, persistence delegated to a model method. Use them as the reference shape.
- **No `SimpleUseCase` doing work that needs monads.** The ADR-006 drift is entirely in one
  direction: over-ceremony, never under. `AssemblePanorama` (147 lines) and `AssembleConsolidado`
  (132) are long but are correctly `SimpleUseCase` — pure reads with no failure path.

**Overall:** the layer is architecturally sound and unusually well-commented — most of these
findings are drift between copies, not wrong design. Two are real correctness bugs
(UC-01, UC-02) and both are in the money path.
