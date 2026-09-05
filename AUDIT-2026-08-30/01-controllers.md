# Audit 01 — Controllers layer and its DDD boundary

**Scope:** all 34 files in `app/controllers/` (+ `app/controllers/concerns/`, empty) and the 20 files in `app/helpers/`.
**Method:** read every controller and every helper in full; cross-checked against `CLAUDE.md`, `docs/architecture/conventions.md`, ADR-006, ADR-002, ADR-012; verified use-case inventory (77 use cases, 8 `Queries::*`) and the specific use-case bodies referenced below.
**Date:** 2026-08-30. Branch `fix/capture-daily-volume`.

---

## What is genuinely fine — say it first

The controller layer is in better shape than its reputation. Concretely verified:

- **The `Assemble*` screens are exemplary.** `DashboardController` (14 lines), `PortfoliosController` (16), `PositionsController` (16), `AssetsController#index`/`#tracked` — all are pure ivar-unpacking over one use case call. Zero logic. That is what the rest of the layer should look like.
- **`:unprocessable_entity` is gone.** Zero occurrences anywhere in `app/`. The Rails 8.1 rename landed completely.
- **Rate limiting is applied where it matters** — `sessions#create` (5/min), `password_resets#create` (3/hr), `two_factor#create` (5/min), `assets#toggle_sync`/`#track` (10/min), `#search_ticker` (15/min), `admin/settings#trigger_data_source` (5/min), `admin/integrations#refresh_sync` (5/min).
- **The two-factor flow (ADR-018) is the best-reasoned code in the layer.** `TwoFactorController#require_pending_user` (`two_factor_controller.rb:62-76`) withholds `session[:user_id]` so an unfinished login has no identity anywhere; the pending window is bounded at 10 minutes and `reset_session` is called on every failure path. No note needed.
- **Ownership scoping is correct.** Every user-owned lookup goes through `current_user.*` or a use case that takes `user:`. No IDOR found.
- **`PwaController`, `HealthController`, `LegalController`, `HelpController`, `WelcomeController`** — nothing to say. Correct as written.
- **Most helpers are honest presentation:** `Admin::LogsHelper`, `Admin::ErrorsHelper`, `Admin::IntegrationsHelper`, `EarningsHelper`, `StatementsHelper`, `NavigationHelper`, `ApplicationHelper`, `SparklineHelper`, `TotpHelper`, `DiscoverHelper`, `PortfoliosHelper`, `DashboardHelper`. Lookup tables and formatters. Leave them alone.

The debt is concentrated in **three clusters**: the admin surface (which never adopted the pattern the app screens did), the money-formatting helpers (which do FX math the view layer should not own), and a missing concerns layer.

---

## Findings

### [CTRL-01] `Admin::SettingsController#update` is a use case written inside a controller
- **Severity:** P1
- **Effort:** M
- **Where:** `app/controllers/admin/settings_controller.rb:29-48`
- **Evidence:**
  ```ruby
  def update
    configs = SiteConfig.where(key: TOGGLE_KEYS).index_by(&:key)
    changes = TOGGLE_KEYS.each_with_object([]) do |key, memo|
      next unless params.key?(key)
      new_value = (params[key] == "1").to_s
      old_value = enabled?(configs[key]).to_s
      next if old_value == new_value
      memo << [ key, old_value, new_value ]
    end
    SiteConfig.transaction do
      changes.each do |key, old_value, new_value|
        SiteConfig.set(key, new_value == "true")
        SiteConfigChange.create!(key: key, old_value: old_value, new_value: new_value, admin: current_user)
      end
    end
    redirect_to admin_settings_path, notice: t("admin.settings.flash.guardados")
  end
  ```
- **Why it matters:** this is a diff computation, a transaction, and **the only writer of the instance's settings audit trail** — all of it unreachable from anywhere but an HTTP PATCH. A rake task, a job, or a future CLI that flips `maintenance_mode` will bypass `SiteConfigChange` entirely and the audit log will silently lie by omission. The audit row is also the one artifact you would want in an incident post-mortem. There is no use case, no contract, no event, and no unit-level spec for the write. `Administration::UseCases::Integrations::*` exists for the sibling screen; settings just never got one.
- **Recommendation:** `Administration::UseCases::Settings::UpdateToggles < ApplicationUseCase` — validate the toggle set through a contract, compute the diff, write both rows in the transaction, `publish` a `SiteConfigChanged` event. Controller drops to a `case/in`.

> **C7 Fadia Haddad:** an audit trail whose only writer is a controller action is an audit trail with a documented bypass. The `admin:` on `SiteConfigChange` records *who*, which is exactly the field you cannot reconstruct later — so the moment a job flips a toggle, the log is not incomplete, it is wrong. Move the write next to the mutation, not next to the request.

---

### [CTRL-02] Two admin controllers render nil on a failure they never branch on
- **Severity:** P1
- **Effort:** S
- **Where:** `app/controllers/admin/errors_controller.rb:6-13`, `app/controllers/admin/logs_controller.rb:3-17`
- **Evidence:**
  ```ruby
  # admin/errors_controller.rb:6
  result = Administration::UseCases::Errors::ListErrors.call(params: filter_params, request: request)
  if result.success?
    data = result.value!
    @pagy = data[:pagy]
    @error_events = data[:errors]
  end                       # <- no else. @pagy and @error_events stay nil.

  # admin/logs_controller.rb:14
  csv = Administration::UseCases::Logs::ExportCsv.call(admin: current_user, params: filter_params).value!
  ```
- **Why it matters:** two distinct problems in the same three lines. (a) If the use case ever fails, the template renders with `@pagy == nil` → `NoMethodError` inside the view, i.e. a 500 with a stack trace pointing at the wrong layer. (b) I read both use cases: `ListErrors` and `ListLogs` **have no `Failure` path at all** — they return `Success(...)` unconditionally. So the guard is dead ceremony that *documents a failure mode that does not exist*, while the one call that can actually blow up (`.value!` on `ExportCsv`, `logs_controller.rb:14`) is unguarded and would raise `Dry::Monads::UnwrapError` — an exception whose message tells an admin nothing.
- **Recommendation:** ListErrors/ListLogs have zero `yield`, zero `validate`, zero `publish` and zero pattern-matched callers — by ADR-006's own "rule when in doubt" they are `SimpleUseCase`s returning the hash directly. Convert them and delete the guard. Give `ExportCsv` a real `case/in` or the same treatment.

---

### [CTRL-03] Result-consumption drift: 9 `if result.success?` sites, 2 bare `.value!`, 1 hybrid
- **Severity:** P1
- **Effort:** M
- **Where:**
  - `app/controllers/admin/integrations_controller.rb:16, 29, 42, 52` (all four actions)
  - `app/controllers/notifications_controller.rb:18-22`
  - `app/controllers/assets_controller.rb:57-61`
  - `app/controllers/alerts_controller.rb:6` — `data = result.value!`
  - `app/controllers/admin/logs_controller.rb:14` — `.value!`
  - `app/controllers/setup_controller.rb:11-23` — a third style: `if result.success?` **plus** `case result.failure in [...]`
- **Evidence:**
  ```ruby
  # admin/integrations_controller.rb:16 — repeated verbatim four times
  if result.success?
    redirect_to admin_integrations_path, notice: t("...")
  else
    redirect_to admin_integrations_path, alert: result.failure.last
  end
  ```
- **Why it matters:** `CLAUDE.md` calls pattern matching canonical and 14 controllers follow it; these 6 do not. The cost is not aesthetic. `result.failure.last` **assumes the failure is an indexable tuple whose last element is a user-facing es-MX string**. A `Failure([:not_found])` (no payload) renders the literal `"not_found"` as a flash to the user; a `Failure(:rate_limited)` raises `NoMethodError: undefined method 'last' for Symbol`. Pattern matching makes that shape a compile-time-ish contract — an unmatched failure raises `NoMatchingPatternError` at the boundary instead of leaking a symbol into the UI. `SetupController`'s hybrid is the worst of both: it pays for `case/in` and still wraps it in `if success?`.
- **Recommendation:** convert all nine to `case/in Dry::Monads::Success(...) / Failure[:tag, payload]`. `alerts_controller.rb:6` and `logs_controller.rb:14` are the two `.value!` sites — either pattern-match or (better, per CTRL-02) demote the use case to `SimpleUseCase`.

> **C3 Sven Kowalski:** `result.failure.last` is the dry-monads equivalent of `rescue => e; e.message`. It works until someone adds a failure that isn't shaped like the ones you had in mind, and then it fails in the UI instead of at the call site. The `admin/` namespace is four identical copies of it, which is also why nobody noticed — it looks like a convention because it is repeated, but the other 14 controllers voted the other way.

---

### [CTRL-04] `DiscoverController#show` assembles a whole screen with no use case
- **Severity:** P1
- **Effort:** M
- **Where:** `app/controllers/discover_controller.rb:2-27`
- **Evidence:**
  ```ruby
  cached = Rails.cache.read(WarmDiscoverJob::CACHE_KEY)
  @waves = cached&.dig(:waves) || []
  @waves_since = cached&.dig(:since)
  @waves_generated_at = cached&.dig(:generated_at)
  cached_headlines = Rails.cache.read(WarmDiscoverJob::HEADLINES_KEY)
  @headlines = cached_headlines&.dig(:headlines) || []
  @owned_symbols = Trading::UseCases::OwnedSymbols.call(user: current_user)
  @has_world_data = @waves.any? || @headlines.any?
  MarketData::Discover::VisitLog.record
  ```
- **Why it matters:** every other screen in the app (`/dashboard`, `/portfolio`, `/positions`, `/assets`) goes through an `Assemble*`/`Load*` use case; Descubrir is the one that reaches into a **job's cache-key constants**, dig-chains the payload shape, derives the empty-state rule, and performs a **side-effect write** (`VisitLog.record`) — the very telemetry D31's kill criterion depends on. Consequence: the cache payload shape is now a contract between a job and a controller with nothing in between, and the kill-criterion counter can only be incremented by an HTTP GET. Changing `WarmDiscoverJob`'s payload breaks a controller, and no use-case spec catches it.
- **Recommendation:** `MarketData::UseCases::AssembleDescubrir` owning the cache reads, the empty-state derivation and the visit record; the controller unpacks ivars like its four siblings. `OwnedSymbols` stays where it is — the ADR-002 comment on line 15-17 is correct and should move with the code.

---

### [CTRL-05] Trading domain rules live in `TradesController` private methods
- **Severity:** P1
- **Effort:** M
- **Where:** `app/controllers/trades_controller.rb:107-114` and `:129-133`
- **Evidence:**
  ```ruby
  def held_position
    return nil unless @side == "buy" && @symbol.present?
    asset = Asset.find_by(symbol: @symbol.upcase)
    return nil if asset.nil? || asset.asset_type_fixed_income?
    current_user.portfolio&.open_positions&.find_by(asset_id: asset.id)
  end

  def find_trade_or_redirect
    trade = current_user.portfolio&.trades&.find_by(id: params[:id])
    ...
  end
  ```
- **Why it matters:** `held_position` encodes three business rules — the average-cost projection only applies to buys, never to fixed income, and only against an *open* position — plus a symbol-normalisation (`.upcase`) and a two-hop portfolio traversal. This is the same anchor logic `Trading::UseCases::LoadAssetAnchors` exists for, decided in a second place with a second policy. `find_trade_or_redirect` is a fourth direct AR traversal. Consequence: the "is fixed income excluded from cost projection?" rule has no spec that isn't a request spec, and when the rule changes (CETES getting an average cost, say) nothing points the next reader at this file.
- **Recommendation:** `Trading::UseCases::LoadTradeSheet.call(user:, side:, symbol:)` returning `{side:, symbol:, currency:, held:}` — the controller's `#new` becomes four ivar assignments. Fold `find_trade_or_redirect` into a `SimpleUseCase` with `find!` per ADR-006 (`FindTrade`), and let the controller `rescue ActiveRecord::RecordNotFound` like `AlertsController#toggle` already does.

> **C2 Hiroto Watanabe:** the giveaway is `asset_type_fixed_income?` in a controller. A controller may ask *who is asking* and *what did they send*; the moment it asks *what kind of instrument is this and does the rule apply to it*, the boundary has moved and the context no longer owns its own invariant. The two-hop `current_user.portfolio&.open_positions&.find_by` is the same leak wearing safe-navigation as a disguise.

---

### [CTRL-06] `TradeImportsController` counts the batch and consults the catalogue itself
- **Severity:** P1
- **Effort:** M
- **Where:** `app/controllers/trade_imports_controller.rb:61-66, 72-74, 90-99`
- **Evidence:**
  ```ruby
  def split_by_symbol(details)
    unknown = Array(details).map(&:upcase).to_set
    blocked = rows.count { |row| unknown.include?(row[:asset_symbol].to_s.upcase) }
    [ blocked, rows.size - blocked ]
  end

  def catalogued(details)
    Administration::Domain::AssetCatalog.find_by_symbols(Array(details)).map { |entry| entry[:symbol] }.to_set
  end
  ```
- **Why it matters:** `split_by_symbol` is a real aggregation over the parsed CSV that decides the number the refusal screen shows ("N rows blocked, M importable") — computed in the controller, against a `rows` memo that itself swallows `CsvRows::MissingHeader` into an ivar (`:96-99`) and returns `[]`. So a malformed header and an empty paste reach `preview` as the same state, and the count that drives the "import the rest" offer is derived independently of `ImportTrades`, which produced the refusal. Two counts of the same batch, computed by two layers, that can disagree. `catalogued` additionally reaches into another context's `Domain::` object straight from a controller.
- **Recommendation:** `ImportTrades`'s `Failure[:unknown_symbols, details]` should carry the split and the catalogued set in its payload — it already has the rows and the refusal reason. Controller keeps `rows`/`csv_text` (genuinely HTTP-shaped concerns: multipart vs textarea, encoding) and drops the three derivation methods.

---

### [CTRL-07] `ProfilesController` re-implements a validation the contract already owns, and queries three contexts for a sidebar
- **Severity:** P1
- **Effort:** S
- **Where:** `app/controllers/profiles_controller.rb:27-28` and `:89-99`
- **Evidence:**
  ```ruby
  # :27
  currency = params.dig(:profile, :preferred_currency).to_s.strip
  return respond_currency(:unprocessable_content, alert: t("profiles.flash.moneda_no_soportada")) unless Asset::SUPPORTED_CURRENCIES.include?(currency)

  # app/contexts/identity/contracts/update_profile_contract.rb:7 — already does this
  optional(:preferred_currency).maybe(:string, included_in?: Asset::SUPPORTED_CURRENCIES)

  # :89-99
  # "Three COUNTs run in parallel at the SQL level when the relation is laid out this way."
  def identity_card_counts
    portfolio = current_user.portfolio
    { open_positions:  portfolio&.positions&.where(status: :open)&.count || 0,
      watchlist_items: current_user.watchlist_items.count,
      active_alerts:   current_user.alert_rules.where(status: :active).count }
  end
  ```
- **Why it matters:** two things. (1) The currency guard duplicates `UpdateProfileContract:7` — the `case/in Failure[:validation, errors]` two lines below would already handle it, with a different message. Two sources of truth for one rule, and the contract's is the one the CSV importer and `ExecuteTrade` also use. (2) `identity_card_counts` issues three queries across **three bounded contexts** (Trading positions, Trading watchlist, Alerts rules) directly from a controller, bypassing every use case. And the comment is simply false: these are three sequential synchronous `SELECT COUNT(*)` round-trips — ActiveRecord does not parallelise them, and "laid out this way" changes nothing. A wrong comment about performance is worse than none; it will stop the next person from fixing the actual N.
- **Recommendation:** delete the currency guard, let the contract fail and reuse the existing `Failure[:validation, ...]` branch. Move the counts into an `Identity::UseCases::LoadIdentityCard` (or one `Queries::` object) — and delete the parallelism claim rather than rewording it.

---

### [CTRL-08] Direct ActiveRecord reads in controllers where the use case layer already exists
- **Severity:** P1
- **Effort:** M
- **Where:**
  - `app/controllers/market_controller.rb:32` — `current_user.watchlist_items.exists?(asset_id: @asset.id)`, sitting between three use-case calls (`:29`, `:31`, `:33`)
  - `app/controllers/market_controller.rb:55-56` — `Asset.find_by!` + `@asset.earnings_events.order(report_date: :desc).limit(8)`
  - `app/controllers/admin/integrations_controller.rb:7` — `Integration.where(provider_name: ...).index_by(&:provider_name)`
  - `app/controllers/onboarding_controller.rb:15, 25, 37-39` — `Integration.order(...)`, `AssetCatalog.all`, three counts
  - `app/controllers/settings_controller.rb:7-9` — `current_user.alert_preference`, `Integration.count`, `SiteConfig.developer_mode?`
  - `app/controllers/admin/errors_controller.rb:16, 22` — `ErrorEvent.find(...)`, `ErrorEvent.find(...).destroy!`
- **Evidence:**
  ```ruby
  # market_controller.rb:27-33 — the comment explains the boundary, then line 32 crosses it anyway
  # ADR-002 forbids MarketData reading Trading or Alerts, so the user-side
  # readings are composed here from their own contexts.
  @position_data  = Trading::UseCases::LoadAssetPosition.call(user: current_user, asset: @asset)
  @asset_rules    = Alerts::UseCases::LoadAssetRules.call(user: current_user, symbol: @asset.symbol)
  @is_watchlisted = current_user.watchlist_items.exists?(asset_id: @asset.id)   # <- not through Trading's door
  ```
- **Why it matters:** `market_controller.rb:32` is the clearest instance — the two lines above and the line below it go through the supplier's public API exactly as ADR-002 prescribes, with a comment saying so, and the watchlist read simply doesn't. That is not a boundary decision, it is an oversight, and it is the line a reader will copy. The rest are lower-stakes but the same shape: `admin/errors_controller.rb:22` performs a **model write** (`destroy!`) directly; `SettingsController#show` reads three contexts' models to render one hub page.
- **Recommendation:** `market_controller.rb:32` → `Trading::UseCases::IsWatchlisted` or fold the boolean into `LoadAssetPosition`'s return (it already takes `user:` and `asset:`). The rest: batch into `Load*` use cases per screen when each screen is next touched — this is not worth a dedicated sweep, but it should stop growing.

---

### [CTRL-09] `FxRatesController` is an FX pricing endpoint with the pricing rule inline
- **Severity:** P1
- **Effort:** M
- **Where:** `app/controllers/fx_rates_controller.rb:7-24`
- **Evidence:**
  ```ruby
  base = params[:currency].to_s.upcase
  reference = Trading::Domain::ExecutionRate::REFERENCE
  date = parsed_date
  quote   = FxRateHistory.quote_on(base: base, quote: reference, date: date)
  divisor = FxRateHistory.rate_on(base: current_user.preferred_currency, quote: reference, date: date)
  render json: { rate: quote&.rate&.to_f, ..., display_divisor: divisor&.to_f, ... }
  ```
- **Why it matters:** the distinction this endpoint encodes — *the stored rate is always against the reference, never against the preference; the preference only supplies a display divisor* — is the ADR-009 rule that the whole multi-currency correctness story rests on, and it lives in a controller with no use case and no unit spec. Consequence: the CSV importer, which has exactly the same "what FX applied on the trade's date" problem, cannot reuse it, so the rule will be re-derived a second time and the two can drift. Two direct model calls into `FxRateHistory` from the controller compound it.
- **Recommendation:** `Trading::UseCases::QuoteExecutionRate.call(user:, currency:, date:)` returning the payload hash. The controller becomes `render json: ...`. `parsed_date`'s silent fallback to `Date.current` on a malformed date (`:28-32`) should move with it and be an explicit decision in the use case, not a rescue in a private controller method — a backdated trade priced at today's rate because the date param was garbled is the exact failure ADR-009 exists to prevent.

---

### [CTRL-10] No concerns layer at all: 7 copies of the same rescue, 2 copies of the flash-stream helper
- **Severity:** P2
- **Effort:** M
- **Where:** `app/controllers/concerns/` (contains only `.keep`); `rescue ActiveRecord::RecordNotFound` in `assets_controller.rb:68, 90`, `alerts_controller.rb:61, 71`, `watchlist_items_controller.rb:46`, `admin/errors_controller.rb:17, 24`, `profiles_controller.rb:49` (RecordInvalid). `FLASH_PARTIAL` + turbo flash prepend duplicated in `trades_controller.rb:2, 124-127` and `watchlist_items_controller.rb:2, 14-16, 24-25, 32-33`.
- **Evidence:**
  ```ruby
  # the same three lines, seven times, differing only in path and key
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: t("alerts.flash.no_encontrada")
  ```
  ```ruby
  # trades_controller.rb:124                     # watchlist_items_controller.rb:24
  turbo_stream.prepend("flash_messages",         turbo_stream.prepend("flash_messages",
    partial: FLASH_PARTIAL,                        partial: FLASH_PARTIAL,
    locals: { type: type, message: message })      locals: { type: "alert", message: message })
  ```
- **Why it matters:** there is no `rescue_from` anywhere in `app/`, and `concerns/` has never been used. `TradesController` already extracted `respond_with_alert` for itself (`:117-122`, with the comment "six call sites differed only in the message") — `WatchlistItemsController` needed the same thing and re-derived it inline three times instead. The seven rescue blocks are the canonical 404 path ADR-006 explicitly designs for; they are correct, just copy-pasted.
- **Recommendation:** one `TurboFlash` concern carrying `flash_stream`/`respond_with_alert`, and either a `RescuesNotFound` concern taking a fallback path or a `rescue_from ActiveRecord::RecordNotFound` in `AuthenticatedController` with a per-controller `not_found_path`. Small, mechanical, and it makes ADR-006's `find!` pattern free at the call site — which is the thing that would get the remaining `find_by` + nil-check sites converted.

---

### [CTRL-11] Controllers publish Identity domain events directly
- **Severity:** P2
- **Effort:** S
- **Where:** `app/controllers/sessions_controller.rb:25, 51`; `app/controllers/two_factor_controller.rb:40-42, 53-55`
- **Evidence:**
  ```ruby
  EventBus.publish(Identity::Events::UserLoggedIn.new(user_id: user.id, ip_address: request.remote_ip, user_agent: request.user_agent.to_s))
  ```
- **Why it matters:** four publish sites for two events, spread across two controllers, while `Identity::UseCases::Login` — which already knows whether the credentials were valid — publishes neither. Consequence: `UserLoggedIn` fires from two places that must be kept in agreement (a plain login and a 2FA completion), and `UserLoginFailed` fires from two more; add a third entry point (an API token, a recovery flow) and the security event log silently misses it. The `request.remote_ip`/`user_agent` argument is real — those are HTTP facts a use case shouldn't invent — but that is what a params hash is for.
- **Recommendation:** pass `ip_address:`/`user_agent:` into `Login` / `VerifyTotpCode` / `ConsumeRecoveryCode` and let them `publish` (they are already `ApplicationUseCase`s, so `publish` is in hand). Controllers keep `start_session` and the redirect.

> **C7 Fadia Haddad:** login-success and login-failure are the two events an intrusion timeline is built from. Having four publishers and zero of them inside the use case that decides the outcome means the timeline's completeness is a property of the controller layer, which is the layer most likely to grow a new entry point. Move them in.

---

### [HELP-01] FX conversion — including a fallback policy — runs in view helpers
- **Severity:** P1
- **Effort:** M
- **Where:** `app/helpers/market_helper.rb:57-65`; `app/helpers/assets_helper.rb:16-24`
- **Evidence:**
  ```ruby
  # market_helper.rb:57
  def approximate_in_preferred(asset, user)
    return nil if asset.current_price.blank? || asset.currency == user.preferred_currency
    rate = FxRateHistory.rate_on(base: asset.currency, quote: user.preferred_currency, date: Date.current) ||
           FxRate.find_by(base_currency: asset.currency, quote_currency: user.preferred_currency)&.rate
    return nil if rate.blank?
    format_currency_mx(asset.current_price * rate, currency: user.preferred_currency, precision: 0)
  end

  # assets_helper.rb:16
  def position_amount(position, declared)
    ...
    [ position.portfolio.convert(native, from: from, to: declared), declared ]
  rescue Trading::Domain::MissingFxRate
    [ native, from ]
  end
  ```
- **Why it matters:** the helper layer is deciding **money policy**. Concretely and verifiably: `Trading::UseCases::LoadAssets#by_market_value` (`load_assets.rb:60-67`) rescues `MissingFxRate` by dropping the *entire list* back to alphabetical order — "one unreachable rate invalidates the comparison for every row" — while `position_amount` rescues the same exception *per row* by showing the native currency. Same missing rate, two different answers, decided in two layers. The result is a list ordered by a rule the rows themselves contradict. `approximate_in_preferred` separately hardcodes a two-tier source fallback (`FxRateHistory` then `FxRate`) that exists nowhere else in the codebase — a rate-resolution policy invented in a helper.
- **Recommendation:** the converted amount and its currency belong in what `LoadAssets` returns (it already converts every row for sorting; returning the value costs nothing). The helper formats what it is handed. `approximate_in_preferred` → a `Queries::`-shaped resolver, so there is one answer to "which FX row applies today".

> **C2 Hiroto Watanabe:** a `rescue Trading::Domain::MissingFxRate` in `app/helpers/` is the boundary violation stated out loud — the view layer is catching a domain exception, which means it is making the domain's decision. The fix is not to move the rescue; it is that the use case should never hand a view something the view has to decide about.

---

### [HELP-02] Financial interpretation thresholds live in a view helper
- **Severity:** P1
- **Effort:** S
- **Where:** `app/helpers/fundamentals_helper.rb:8-16`
- **Evidence:**
  ```ruby
  METRIC_CHIPS = {
    beta: ->(v) { return :volatil if v > 1.3; return :defensivo if v < 0.7; :como_el_mercado },
    payout_ratio: ->(v) { :sobre_utilidades if v > 1.0 },
    current_ratio: ->(v) { v < 1.0 ? :liquidez_corta : :cubre_corto_plazo }
  }.freeze
  ```
- **Why it matters:** these are judgements about financial instruments — "beta above 1.3 is volatile", "a payout above 100% pays more than it earns" — expressed as lambdas in `app/helpers/`. The D36 comment above them is a careful piece of domain reasoning about *when a threshold is defensible*, which is exactly the argument that should be sitting next to `MarketData::Domain::MetricDefinitions` where the metrics themselves are defined. Consequence: the thresholds are untestable except through a view spec, and an alert rule or an observation detector that wants the same judgement has to duplicate the numbers.
- **Recommendation:** `MarketData::Domain::MetricChip.for(key, value)` returning the chip key or nil; the helper keeps `CHIP_TONES` (genuinely presentation) and the `t()` lookup. `remaining_metrics_by_category` (`:100-108`) can follow later — it is presenter logic, lower stakes.

---

### [HELP-03] Database queries issued from helpers
- **Severity:** P2
- **Effort:** S
- **Where:** `app/helpers/alerts_helper.rb:142-149`; `app/helpers/market_helper.rb:40-44, 208`; `app/helpers/notifications_helper.rb:6-14`
- **Evidence:**
  ```ruby
  # alerts_helper.rb:142 — per rules-table row
  @alert_rule_assets[symbol] = Asset.find_by(symbol: symbol)

  # market_helper.rb:208 — a query inside a caption formatter
  source = MarketData::Queries::PriceSeries.for(asset).latest(1).first&.source

  # market_helper.rb:41 — per tracked-list row (rendered from _tracked_row.html.erb:49)
  DataSourceRegistry.for_capability(:prices, market: asset.market, asset_type: asset.asset_type).first&.integration_name
  ```
- **Why it matters:** none of these are hot enough to be a P1 (I checked the render sites: `asset_data_source_caption` runs once per asset-detail page, not per row), but they put the query count of a screen outside the use case that is supposed to own it, so `LoadDashboard`/`LoadTrackedAssets` cannot preload for them. `alert_rule_asset` memoises per request, which works, and is also the tell that someone already hit the N+1.
- **Also here:** `navbar_notifications` (`:6-9`) has **zero callers** — dead code. And `CLAUDE.md` states `AuthenticatedController` "loads notifications for navbar"; it does not — there is no such `before_action` (`authenticated_controller.rb:1-23`), the navbar count comes from `navbar_unread_count` in the view. Fix the doc or the code, but they currently disagree.
- **Recommendation:** delete `navbar_notifications`; correct the `CLAUDE.md` line. Fold the three lookups into the use case payloads when their screens are next touched.

---

### [HELP-04] Domain classification by regex in `AlertsHelper`
- **Severity:** P2
- **Effort:** S
- **Where:** `app/helpers/alerts_helper.rb:52-75, 156-163`
- **Evidence:**
  ```ruby
  def kind_label_from_symbol(symbol)
    case symbol
    when /\ACETES?_/i, /\ACETE\b/i then asset_type_label_es(:fixed_income)
    when /\.MX\z/i                 then "#{asset_type_label_es(:stock)} MX"
    when "BMV", "IPC", /\AIPC\b/i  then asset_type_label_es(:index)
    else                                asset_type_label_es(:stock)
    end
  end
  ```
- **Why it matters:** "what kind of instrument is this symbol" is an Alerts/MarketData domain question answered by regex in the view layer, and `alert_condition_summary` (`:52-75`) separately restates what all nine alert conditions mean — vocabulary the evaluator and the contract also own. The fallback path is legitimate (rules can outlive their asset, per the comment at `:32-34`), the placement is not. Consequence: adding a tenth condition means editing the contract, the evaluator, and a view helper, with nothing linking them.
- **Recommendation:** `Alerts::Domain::RuleDescription` (or extend the existing evaluator surface) owning the summary and the symbol heuristic; helper keeps the label tables.

---

### [HELP-05] Four independent es-MX relative-time implementations, three identical timestamp formatters
- **Severity:** P2
- **Effort:** S
- **Where:** relative: `market_helper.rb:90-101`, `alerts_helper.rb:83-95`, `admin/integrations_helper.rb:103-113`, `admin/settings_helper.rb:39-45`, `notifications_helper.rb:88-102`. Absolute `DD MMM YYYY · HH:MM`: `admin/logs_helper.rb:49-54`, `admin/errors_helper.rb:10-16`, `admin/settings_helper.rb:25-30`, `market_helper.rb:197-202`.
- **Evidence:**
  ```ruby
  # admin/settings_helper.rb:39 and admin/integrations_helper.rb:103 — same ladder, different bucket labels
  return "hace #{seconds} s" if seconds < 60
  return "hace #{seconds / 60} min" if seconds < 3600
  return "hace #{seconds / 3600} h" if seconds < 86_400
  "hace #{seconds / 86_400} d"
  ```
- **Why it matters:** the buckets already disagree — `observation_when` says `"hace un instante"` under 60s and `"días"` in full, `integration_last_check_label` says `"hace N s"` and `"d"` abbreviated. So the same elapsed time reads differently on two admin screens. `DatetimeEsHelper` (8 lines, `MONTHS_ES`/`WEEKDAYS_ES`) is the shared piece that exists; the formatting on top of it was never pulled up.
- **Recommendation:** move both ladders into `DatetimeEsHelper` (`relative_es(time)`, `absolute_es(time, seconds: false)`), keep the one deliberate variant (`alert_event_when`'s "hoy · 14:42 CDMX" is a different design, not drift) and delete the rest.

---

### [HELP-06] `PriceChartHelper` hardcodes hex colours, which ADR-012 forbids
- **Severity:** P2
- **Effort:** S
- **Where:** `app/helpers/price_chart_helper.rb:36-37`
- **Evidence:**
  ```ruby
  line_color = trend_up ? "#10b981" : "#ef4444"
  fill_color = trend_up ? "#10b981" : "#ef4444"
  ```
- **Why it matters:** ADR-012 is explicit — views and components reference roles, "never a raw hex and never a value" — and every sibling helper honours it (`assets_helper.rb:53` returns `text-positive`/`text-negative`, `portfolios_helper.rb:2` uses `var(--color-chart-n)`). These two hexes are light-mode emerald/rose baked into the SVG, so the price chart does not follow the theme. `fill_color` is also just `line_color` under a second name.
- **Recommendation:** return the token names (`--color-positive` / `--color-negative`) the way `chart_series_json` and `price_series_json` already do, and collapse the duplicate.

---

## Summary table

| ID | Severity | Effort | Title |
|---|---|---|---|
| CTRL-01 | P1 | M | `Admin::SettingsController#update` is a use case in a controller (audit trail included) |
| CTRL-02 | P1 | S | Two admin index actions render nil on a failure branch that is dead anyway |
| CTRL-03 | P1 | M | Result-consumption drift — 9 `if result.success?`, 2 `.value!`, 1 hybrid |
| CTRL-04 | P1 | M | `DiscoverController#show` assembles a screen (and writes telemetry) with no use case |
| CTRL-05 | P1 | M | Trading domain rules in `TradesController#held_position` |
| CTRL-06 | P1 | M | `TradeImportsController` recomputes the batch split and consults the catalogue |
| CTRL-07 | P1 | S | `ProfilesController` duplicates a contract rule; sidebar queries three contexts |
| CTRL-08 | P1 | M | Direct AR reads where the use case layer exists (`market_controller.rb:32` the clearest) |
| CTRL-09 | P1 | M | `FxRatesController` holds the ADR-009 pricing rule inline |
| CTRL-10 | P2 | M | Empty `concerns/`: 7 duplicated rescues, 2 copies of the flash-stream helper |
| CTRL-11 | P2 | S | Controllers publish Identity domain events directly |
| HELP-01 | P1 | M | FX conversion + fallback policy in view helpers, contradicting the use case |
| HELP-02 | P1 | S | Financial interpretation thresholds in `FundamentalsHelper` |
| HELP-03 | P2 | S | DB queries in helpers; `navbar_notifications` dead; `CLAUDE.md` claim false |
| HELP-04 | P2 | S | Asset-type classification by regex in `AlertsHelper` |
| HELP-05 | P2 | S | Four relative-time implementations, three timestamp formatters |
| HELP-06 | P2 | S | `PriceChartHelper` hardcodes hex, breaking ADR-012 |

**9 P1, 8 P2, 0 P0.** No security defect, no IDOR, no correctness bug that is live today. The closest to a correctness risk is HELP-01 (two layers disagreeing about the same missing FX rate) and CTRL-02 (a nil-render path guarded by a branch that cannot fire).

---

## Cross-cutting reading

Three things explain almost every finding above.

1. **The admin surface never adopted the pattern the app screens did.** `admin/integrations` (4× `if result.success?`), `admin/errors` and `admin/logs` (guard-with-no-else + `.value!`), `admin/settings` (a use case written inline). Meanwhile `/dashboard`, `/portfolio`, `/positions`, `/assets` are textbook. This reads as a surface that was built before the convention settled and never revisited — which is defensible history, but it now teaches the wrong pattern to anyone reading `admin/` first.

2. **`app/helpers/` has become a second domain layer.** FX conversion with its own fallback policy, financial-metric thresholds, symbol classification, alert-condition semantics. Individually each is small; together it means a meaningful amount of the domain is only reachable from a rendered template and only testable through a view spec.

3. **The concerns layer was never opened.** `TradesController` extracted `respond_with_alert` for its own six call sites and stopped at the file boundary; `WatchlistItemsController` re-derived it. Seven copies of the ADR-006 rescue. The absence of any `rescue_from` in the whole app is the same story.

> **C3 Sven Kowalski:** if only two things get done, do CTRL-01 and CTRL-03. The first is the one with a real operational consequence (an audit trail with a bypass), the second is cheap and stops the `admin/` namespace from spreading a pattern that fails in the UI rather than at the call site. CTRL-02 rides along with CTRL-03 for free.

> **C2 Hiroto Watanabe:** and HELP-01, before the next money screen. Two layers holding different opinions about a missing exchange rate is not a style problem — it is the multi-currency invariant this project spent a sprint getting right, quietly re-decided in `app/helpers/`.
