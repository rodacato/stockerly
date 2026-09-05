# Audit 04 — Cross-context boundaries & the event system

**Scope:** ADR-002 compliance (Trading↔MarketData and the undeclared pairs), model ownership,
cross-context writes, EventBus health, event payload serializability, controller/job/view bypasses.
**Method:** exhaustive grep of every AR model constant across `app/contexts/`, `app/controllers/`,
`app/jobs/`, `app/helpers/`, `app/views/`, `app/shared/`, `app/mailers/`; full read of the EventBus,
`BaseEvent`, `ProcessEventJob`, `event_subscriptions.rb`, all 22 event classes and all 30 handlers.
**Date:** 2026-08-30. **Read-only** — nothing in the repo was modified.

---

## Headline

The **namespace** boundary (`Foo::Bar` calls) is in good shape — the `Queries::*` read API landed and
Trading no longer reads a single MarketData AR model. The **model** boundary is not: every remaining
violation is a *bare ActiveRecord constant* or an *association traversal*, and both are invisible to
the one guard that exists (`script/audit-entropy.sh`). It reports 8 "leaks", of which 6 are
ADR-002-sanctioned, and misses the two clauses ADR-002 explicitly forbids.

The inverse leak that ADR-002 §Context declared dead in 2026-05 ("MarketData no longer reads from
Trading anywhere") **is back**, in two places.

---

### [BND-01] MarketData reads Trading aggregates directly — the inverse leak ADR-002 declared dead
- **Severity:** P1
- **Effort:** M
- **Where:**
  - `app/contexts/market_data/use_cases/notify_approaching_earnings.rb:35` (`WatchlistItem`)
  - `app/contexts/market_data/use_cases/notify_approaching_earnings.rb:36` (`Position` + `joins(:portfolio)` → `portfolios.user_id`)
  - `app/contexts/market_data/domain/market_sentiment.rb:57` (`user.watchlist_items.pluck(:asset_id)`)
- **Evidence:**
  ```ruby
  # notify_approaching_earnings.rb:34-38
  def users_watching(asset)
    user_ids = WatchlistItem.where(asset: asset).pluck(:user_id)
    position_user_ids = Position.where(asset: asset, status: :open).joins(:portfolio).pluck("portfolios.user_id")
    User.where(id: (user_ids + position_user_ids).uniq)
  end
  ```
- **Why it matters:** ADR-002 §Forbidden, verbatim: *"MarketData reading Trading ActiveRecord models
  or domain services. No `Portfolio.find`, no `Trading::Domain::*` call from
  `app/contexts/market_data/`."* Line 36 doesn't just read `Position` — it reaches through to the
  `portfolios` table by raw SQL string, so a rename or a schema change inside Trading breaks a
  MarketData use case with no compile-time or grep-time signal. Worse, `MarketSentiment.for_user` is
  the class ADR-002 **grandfathered as Trading's read API**: the sanctioned door into MarketData is
  implemented by reaching back out through Trading's watchlist. The dependency is now bidirectional,
  which is exactly what the customer/supplier pattern exists to prevent.
- **Recommendation:** Two doors, both Trading-owned. `Trading::Queries::HoldersOf.call(asset:)`
  (or `Trading::UseCases::OwnedSymbols`, which already exists and already frames itself as
  "the screen asks through this door" — extend it) returns user ids for an asset;
  `Trading::Queries::WatchedAssetIds.call(user:)` returns the watchlist ids `MarketSentiment` needs.
  That inverts the direction correctly: Trading exposes, MarketData consumes — which is a *new*
  supplier relationship and needs its own ADR, per ADR-002's "each adopter pair gets its own ADR".
  If Adrian would rather not open that door at all, the honest alternative is moving
  `NotifyApproachingEarnings` into Trading (where `NotifyApproachingMaturities` already lives, doing
  the identical job over Trading's own data — see `notify_approaching_maturities.rb:5`, which names
  the earnings use case as its own model).

> **C2 Hiroto:** *The ADR's own Context section says the inverse leak disappeared. It came back
> within three months, through a use case nobody thought of as a boundary crossing because it never
> types `Trading::`. That is the lesson: a boundary policed by namespace greps is a boundary against
> `::`, not against coupling. And `MarketSentiment` is the ugly one — the class the ADR named as the
> sanctioned door is itself the leak. Grandfathering is fine; grandfathering something you never
> read the body of is not.*

---

### [BND-02] `Identity::CreateFirstAdmin` writes four other contexts' aggregates directly
- **Severity:** P1
- **Effort:** M
- **Where:** `app/contexts/identity/use_cases/create_first_admin.rb:28-93` — `bootstrap_platform!`
  - `:37` `SiteConfig.find_or_create_by!` (Administration)
  - `:49` `Integration.find_or_create_by!` (Administration)
  - `:71` `MarketIndex.find_or_create_by!` (MarketData)
  - `:88` `FxRate.find_or_create_by!` (MarketData)
- **Evidence:**
  ```ruby
  user = yield persist(attrs)
  bootstrap_platform!                                        # 4 foreign aggregate writes
  _ = yield publish(Events::FirstAdminCreated.new(...))      # the event exists, right below
  ```
  ```ruby
  { base_currency: "USD", quote_currency: "MXN", rate: 17.25 }
  ```
- **Why it matters:** This is the single largest cross-context **write** in the codebase, and it
  bypasses the event it publishes on the very next line. `Identity::Events::FirstAdminCreated`
  already has two handlers (`CreatePortfolioOnRegistration`, `CreateAlertPreferencesOnRegistration`)
  — the pattern is right there and this code walks past it. Consequences beyond purity: the seed
  data for MarketData and Administration lives in Identity, so the six market indices and three FX
  pairs a MarketData maintainer needs to change are in a file about user creation. The hardcoded
  `17.25` USD/MXN is a MarketData fact frozen in an Identity file — and `MarketData::Domain::ProviderDefaults::ALL`
  at `:46` shows the correct shape already exists for integrations but was not applied to indices or FX.
- **Recommendation:** Three handlers on the existing event, each owned by the context it writes:
  `Administration::Handlers::SeedInstanceDefaultsOnFirstAdmin` (SiteConfig + Integration, reading
  `ProviderDefaults`), `MarketData::Handlers::SeedIndicesOnFirstAdmin`,
  `MarketData::Handlers::SeedFxPairsOnFirstAdmin`. Keep them **synchronous** — first-boot ordering
  matters and the setup response is not latency-critical. `bootstrap_platform!` and its four private
  methods then delete outright.

> **C3 Sven:** *Mechanically this is 40 minutes: three handler files, three `EventBus.subscribe`
> lines, delete the private block. The one thing that must not change is that the writes stay in the
> synchronous path — if you mark these handlers `async? = true` the setup wizard redirects to a
> `/onboarding` screen whose Integration rows do not exist yet.*

---

### [BND-03] `ProcessEventJob` doesn't rehydrate the event — 12 handlers carry dual-signature glue
- **Severity:** P1
- **Effort:** M
- **Where:** `app/jobs/process_event_job.rb:6`; `app/shared/events/event_bus.rb:11-17,29-33`.
  The glue appears in 12 handlers, ~28 lines:
  `market_data/handlers/backfill_history_on_asset_creation.rb:9`,
  `sync_asset_on_creation.rb:9`, `recalculate_trend_score_on_price_update.rb:7`,
  `broadcast_price_update.rb:5`, `broadcast_fundamentals_update.rb:7`,
  `recalculate_fundamentals_on_statements_synced.rb:5-6`, `record_price_history.rb:76-80`,
  `alerts/handlers/create_notification_on_alert.rb:7-10`,
  `evaluate_alerts_on_price_update.rb:7-9`, `create_alert_event_on_trigger.rb:5-9`,
  `trading/handlers/rebuild_snapshots_on_backdated_trade.rb:14`, `adjust_positions_on_split.rb:7`,
  `recalculate_avg_cost_on_trade.rb:5`,
  `notifications/handlers/broadcast_notification.rb:5-6`, `send_urgent_email.rb:10`,
  `send_push_notification.rb:10`
- **Evidence:**
  ```ruby
  # event_bus.rb — sync gets the object, async gets a Hash
  ProcessEventJob.perform_later(handler.name, serialize(event))   # async
  handler.call(event)                                             # sync

  # every handler then pays for it, four times over in the worst case
  user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
  symbol  = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol
  price   = event.is_a?(Hash) ? event[:triggered_price] : event.triggered_price
  rule_id = event.is_a?(Hash) ? event[:alert_rule_id] : event.alert_rule_id
  ```
- **Why it matters:** The bus has two calling conventions and pushed the reconciliation onto every
  handler author. Three concrete costs. (1) It is 28 lines of pure ceremony that must be repeated
  correctly in every new handler — anti-pattern #3 with a maintenance tail. (2) It is a **silent**
  failure mode: `RecordPriceHistory#field` (`:76-80`) returns `nil` for an attribute the event does
  not respond to, so if an event gains a field and a handler reads it, the async path quietly writes
  `nil` where the sync path writes the value, and the spec that exercises the handler synchronously
  passes. (3) `serialize` (`:29-33`) only coerces `DateTime`/`Time` at the **top level** — a nested
  temporal inside `Types::Hash` payloads (`Trading::Events::TradeUpdated#changes`,
  `Alerts::Events::AlertRuleTriggered#context`) goes to ActiveJob raw. It survives today only
  because `UpdateTrade#extract_previous` happens to call `.iso8601` itself
  (`update_trade.rb:40`) — an accident, not a contract.
- **Recommendation:** Pass the event class name alongside the handler name and rehydrate in the job:
  `ProcessEventJob.perform_later(handler.name, event.class.name, serialize(event))` →
  `handler.call(event_class.constantize.new(data.symbolize_keys))`. Dry::Struct coerces the
  ISO8601 strings back through its own `Types`, which is what it is for. Then delete all 28 glue
  lines and give handlers one signature. Note this needs a deploy-ordering plan: in-flight
  Solid Queue rows carry the 2-arg shape, so keep a 2-arg fallback for one release.

> **C2 Hiroto:** *An event is a value object. The moment it crosses the queue as a bare Hash it stops
> being one, and every handler becomes a parser. Rehydrate at the edge — that is the whole job of
> `ProcessEventJob`, and right now it does `constantize` and nothing else.*

---

### [BND-04] `EventBus.publish` has no error isolation — one raising handler drops the rest
- **Severity:** P1
- **Effort:** S
- **Where:** `app/shared/events/event_bus.rb:10-18`
- **Evidence:**
  ```ruby
  def publish(event)
    @handlers[event.class.name].each do |handler|
      if handler.respond_to?(:async?) && handler.async?
        ProcessEventJob.perform_later(handler.name, serialize(event))
      else
        handler.call(event)
      end
    end
  end
  ```
- **Why it matters:** No `rescue`, no logging, no continue. `MarketData::Events::AssetPriceUpdated`
  has four subscribers dispatched in a documented, load-bearing order
  (`config/initializers/event_subscriptions.rb:19-23`). If `RecordPriceHistory` raises anything it
  does not already swallow, `BroadcastPriceUpdate` and `RecalculateTrendScoreOnPriceUpdate` never
  run and the exception surfaces in `SyncSingleAssetJob` as a job failure — after the `Asset` row was
  already updated. Same shape on `TradeExecuted`: `RecalculateAvgCostOnTrade` takes a row lock
  (`recalculate_avg_cost_on_trade.rb:10`) and is subscribed **first**; a lock timeout there means
  `LogTradeActivity` never writes the audit row and `ExecuteTrade` raises to the controller *after*
  the trade committed. The user sees a 500 for a trade that was saved.
- **Recommendation:** Wrap each sync dispatch: `rescue => e` → `Rails.error.report(e, context: {event: event.class.name, handler: handler.name})` and continue. The
  `Rails.error` subscriber already exists (`config/initializers/error_reporting.rb:5` →
  `Administration::Handlers::RecordUnhandledError`), so the failure lands in `/admin/errors`
  (ADR-020) instead of being thrown at whoever published. Deliberate exceptions — none exist today —
  would need an opt-out, but "handlers never break the publisher" is the correct default for a bus
  whose subscribers are all logging, broadcasting and derived-data work.

> **C3 Sven:** *Five lines. And put the ordering contract in the wiring spec while you are there —
> `spec/integration/event_subscription_wiring_spec.rb` asserts `include`, not order, so the comment
> at `event_subscriptions.rb:19-20` that calls the order "load-bearing" is enforced by nothing but
> good manners.*

---

### [BND-05] Synchronous handler publishes another event — an uninstrumented cascade
- **Severity:** P2
- **Effort:** S
- **Where:** `app/contexts/market_data/handlers/recalculate_fundamentals_on_statements_synced.rb:42`
- **Evidence:**
  ```ruby
  # inside a sync handler, after ~8 queries, a calculation and an update!
  EventBus.publish(Events::AssetFundamentalsUpdated.new(asset_id: asset.id, ...))
  ```
- **Why it matters:** `FinancialStatementsSynced` (sync) → this handler (8 queries, TTM math,
  `AssetFundamental#update!`) → publishes `AssetFundamentalsUpdated` → two more sync handlers, one of
  which renders an ERB partial and pushes a Turbo broadcast
  (`broadcast_fundamentals_update.rb:14`). All of it inside `SyncStatementsJob`'s call stack, all of
  it on the publisher's thread, with no depth guard and (per BND-04) no error isolation. It works
  because the graph happens to be shallow; nothing prevents the next handler from making it deeper,
  and a cycle would recurse until the stack blows.
- **Recommendation:** Either mark the handler `self.async? = true` (it has no ordering constraint —
  nothing downstream of `FinancialStatementsSynced` depends on it completing inline), or move the
  recalculation into `MarketData::UseCases::RecalculateFundamentals` and let the handler be a
  one-line enqueue like `SyncAssetOnCreation` is. The second is more consistent with the rest of the
  handler layer, where every handler that does real work delegates to a job or a use case.

---

### [BND-06] Two published events have zero subscribers
- **Severity:** P2
- **Effort:** S
- **Where:**
  - `MarketData::Events::MarketIndicesUpdated` — published `app/jobs/sync_market_indices_job.rb:23`; defined `app/contexts/market_data/events/market_indices_updated.rb`; **no** subscription (`event_subscriptions.rb:50-51` has a bare `# Market Indices` comment with nothing under it)
  - `Trading::Events::TradesImported` — published `app/contexts/trading/use_cases/import_trades.rb:210`; defined `app/contexts/trading/events/trades_imported.rb`; **no** subscription
- **Evidence:** `event_subscriptions.rb`
  ```ruby
  # Market Indices

  # Sentiment
  EventBus.subscribe(MarketData::Events::FearGreedUpdated, ...)
  ```
- **Why it matters:** Every other sync event has a `Log*Sync` handler writing a `SystemLog` row —
  `LogNewsSync`, `LogEarningsSync`, `LogCetesSync`, `LogDividendsSync`, `LogFearGreedUpdate`. The
  indices sync is the one that does not, so `/admin/logs` shows CETES, news, earnings, dividends and
  sentiment syncing, and is silent about indices. That is not a missing feature, it is an
  inconsistency that reads as "indices never ran". `TradesImported` is worse: `ImportTrades#after_commit`
  goes out of its way to publish it outside the transaction with a comment explaining why
  (`import_trades.rb:203-204`), and the fact is broadcast to nobody. The empty `# Market Indices`
  header is a subscription that was deleted or never written.
- **Recommendation:** For indices, add `MarketData::Handlers::LogMarketIndicesSync` mirroring
  `LogFearGreedUpdate` — that is what the empty header is asking for. For `TradesImported`, either
  subscribe `Trading::Handlers::LogTradeActivity`'s import equivalent (an `AuditLog` row for a bulk
  import is the obvious consumer, and today an import of 200 trades leaves no audit trail while a
  single manual trade leaves one), or delete the event and the publish. Do not leave it published
  into the void.

---

### [BND-07] `MarketData::Queries::UpcomingDividends` has zero callers but is cited as the live example of the read contract
- **Severity:** P2
- **Effort:** S
- **Where:** `app/contexts/market_data/queries/upcoming_dividends.rb`; cited in `CLAUDE.md:141` and
  `docs/architecture/adr/0002-trading-marketdata-boundary.md:195`. Only other reference is its spec.
- **Evidence:** ADR-002's 2026-08-29 amendment: *"The live examples of the read contract are the
  `MarketData::Queries::*` objects — `CurrentFearGreed`, `NotableObservations`, `PriceSeries`,
  `UpcomingDividends` and the rest."* Caller census: `PriceSeries` 14, `RecentNews` 2,
  `AssetMarketContext` / `CetesReinvestedReturn` / `CurrentFearGreed` / `NotableObservations` /
  `RsiOnDates` 1 each, **`UpcomingDividends` 0**.
- **Why it matters:** `design/V2_REMAINING.md:362` records that `UpcomingDividendsPresenter` "lost
  its only caller when Historial replaced `/positions`" — the presenter was noticed, the query
  behind it was not. It is now dead code that two governing documents point at as the exemplar. The
  screen that *should* consume it reads the data a different way instead (BND-08).
- **Recommendation:** Delete it and its spec, and drop the name from `CLAUDE.md:141` and the ADR's
  amendment — or wire it into `AssembleHistorial`, which is the caller it was written for. Do not
  keep a zero-caller class as documentation of a pattern; that is how the pattern rots.

---

### [BND-08] `DividendPayment` is an undeclared shared-kernel model with its only writer in a job
- **Severity:** P2
- **Effort:** M
- **Where:**
  - Written: `app/jobs/sync_dividends_job.rb:85-91` (inside `create_payments`), keyed on
    `portfolios_trading_before` (`:97-102`) which reads `Trade.kept` and `Portfolio`
  - Read: `app/contexts/trading/use_cases/assemble_historial.rb:22` — `portfolio.dividend_payments.recent.includes(dividend: :asset)`
  - Rendered: `app/views/positions/index.html.erb:38,41,43,47` — `payment.dividend.asset.symbol`, `payment.dividend.pay_date`, `payment.dividend.currency`
  - Model: `app/models/dividend_payment.rb:2-3` — `belongs_to :portfolio` (Trading) + `belongs_to :dividend` (MarketData)
- **Evidence:**
  ```ruby
  # sync_dividends_job.rb:97-102 — a MarketData sync job querying Trading's ledger
  def portfolios_trading_before(dividend)
    Portfolio.where(id: Trade.kept.where(asset: dividend.asset)
                              .where(executed_at: ..dividend.ex_date.end_of_day)
                              .select(:portfolio_id))
  end
  ```
- **Why it matters:** `DividendPayment` is the one model that structurally belongs to both contexts,
  and no document says so. Its only writer is a job (which ADR-002 §Gray-zone exempts from the rule,
  reasonably), but the exemption was written for jobs *calling* gateways and use cases — not for a
  job holding the entire derivation of a cross-context aggregate in its private methods, including
  the `shares_held_on` snapshot semantics. Trading then reads it back through an association and the
  view walks two hops into MarketData (`payment.dividend.asset`), which is a boundary crossing the
  entropy script structurally cannot see. If dividend-payment derivation ever needs to change, the
  logic is in `app/jobs/`, unowned, untestable at the use-case level, and 60 lines from the
  `UpcomingDividends` query nobody calls.
- **Recommendation:** Move the derivation into `Trading::UseCases::RecordDividendPayments.call(dividend:)`
  — Trading owns `Portfolio` and `Trade`, so the read is local, and the job becomes
  `MarketData::Events::DividendsSynced` → `Trading::Handlers::RecordPaymentsOnDividendsSync`, which
  is the event-driven write ADR-002 asks for. The `DividendsSynced` event already exists and
  already fires (`sync_dividends_job.rb:25`); today it only writes a log line.

---

### [BND-09] Two writers to `portfolio_snapshots` with different semantics for `total_value`
- **Severity:** P2
- **Effort:** S
- **Where:** `app/jobs/take_snapshots_job.rb:21-26` and `app/contexts/trading/use_cases/rebuild_snapshots.rb:31-34`
- **Evidence:**
  ```ruby
  # TakeSnapshotsJob (nightly, today only)
  total_value: portfolio.total_value(currency: currency),
  invested_value: portfolio.invested_value(currency: currency)

  # RebuildSnapshots (backfill, any past date)
  snapshot.update!(currency: currency, invested_value: invested, total_value: invested)
  ```
- **Why it matters:** Two paths write the same row and disagree about what `total_value` means. It is
  benign *today* only because `Portfolio#total_value` (`app/models/portfolio.rb:18-20`) currently
  delegates to `invested_value` — so the two agree by coincidence, not by contract. The moment
  `total_value` becomes a real market valuation (which is what the name promises and what a
  performance chart needs), the nightly job and the backfill produce different numbers for adjacent
  days on the same chart, and the discontinuity lands exactly at whatever date a backdated trade
  triggered a rebuild. A boundary consequence, not a coincidence: the job is top-level glue writing
  a Trading aggregate directly instead of going through the use case that owns it.
- **Recommendation:** `TakeSnapshotsJob#take_snapshot` becomes
  `Trading::UseCases::RebuildSnapshots.call(portfolio:, from: Date.current)` — the use case is
  already idempotent on `(portfolio_id, date)` and already reads `preferred_currency` the same way.
  One writer, one definition. `RebuildSnapshots`'s own `total_value: invested` question then becomes
  a single decision in a single place rather than a divergence.

---

### [BND-10] The entropy guard checks namespaces; every real violation is a bare constant
- **Severity:** P2
- **Effort:** M
- **Where:** `script/audit-entropy.sh:39-53`
- **Evidence:** the regex greps only `Trading::|MarketData::|Alerts::|Identity::|Administration::|Notifications::`.
  Current output: `Cross-context leaks (greps): 8`. Those 8 are:
  | Hit | Verdict |
  |---|---|
  | `identity/use_cases/create_first_admin.rb:46` `MarketData::Domain::ProviderDefaults` | benign (a constant); the **real** violation is 40 lines below it and invisible — BND-02 |
  | `alerts/domain/alert_evaluator.rb:52` `MarketData::Domain::DayChange` | marked `@api public` — sanctioned |
  | `administration/.../map_provider_symbol.rb:39` `MarketData::Gateways::ApiKeyNotConfiguredError` | rescuing a supplier's error class |
  | `administration/.../create_asset.rb:10`, `delete_asset.rb:12` `MarketData::Events::Asset*` | real, known — BND-12 |
  | `trading/.../load_tracked_assets.rb:17` `MarketData::Domain::FundamentalsBudget` | unmarked — BND-11 |
  | `trading/.../load_assets.rb:17`, `assemble_panorama.rb:21` `DayChange.by_asset` | unmarked overload — BND-11 |
  Not counted, because they contain no `::`: BND-01 (×3), BND-02's four writes, BND-09's
  `MarketHoliday`/`Asset`, the `Notification` reads in Trading and MarketData, and every association
  traversal in BND-08.
- **Why it matters:** ADR-002 §Mitigations says *"The `audit-entropy.sh` script can be extended to
  count direct AR model reads from Trading into MarketData. Establish a baseline at #33 close and
  watch for regressions."* It was never extended. The result is a guard that measures the dimension
  the codebase already fixed and is blind to the dimension it regressed on — and a number
  (8) that looks like a leak count while being mostly sanctioned traffic.
- **Recommendation:** Add a second metric: a declared `MODEL_OWNERS` map (see Appendix) and a grep
  for each model constant inside every non-owning context directory, with an explicit allowlist for
  the shared kernel (`Asset`, `User`, `FxRate`, `FxRateHistory`, `SystemLog`, `AuditLog`,
  `Notification`, `Integration`). That map is the artifact this codebase is missing more than any
  refactor — six contexts, 36 models, and nothing anywhere says which owns which.

---

### [BND-11] Two MarketData domain services are called from Trading without the `@api public` mark ADR-002 requires
- **Severity:** P2
- **Effort:** S
- **Where:**
  - `app/contexts/market_data/domain/day_change.rb:30` — `by_asset` is unmarked; the mark at `:18` sits on `from_closes`
    - callers: `trading/use_cases/load_assets.rb:17`, `trading/use_cases/assemble_panorama.rb:21`
  - `app/contexts/market_data/domain/fundamentals_budget.rb:17` — `today`, no mark at all
    - caller: `trading/use_cases/load_tracked_assets.rb:17`
- **Evidence:**
  ```ruby
  # day_change.rb — the mark is on the method Alerts calls, not the one Trading calls
  # @api public — read by Alerts (ADR-002 read API)
  def self.from_closes(closes) ... end

  # {asset_id => [closes]} → {asset_id => percent or nil}.     ← no marking
  def self.by_asset(closes_by_asset) ... end
  ```
- **Why it matters:** ADR-002 §Allowed makes the marking the *whole* mechanism: *"Trading may call
  `MarketData::Domain::*` services that are explicitly marked as part of the read API (a YARD
  `@api public` tag or a comment block stating 'Cross-context read API')."* Without it there is no
  way to tell an intentional supplier surface from a shortcut — and the entropy script's allowlist
  is a hardcoded single name (`MarketSentiment`, `audit-entropy.sh:50`) rather than a scan for the
  tag, so the marking convention is documented and enforced by nothing. `FundamentalsBudget` is the
  sharper case: it is called from Trading and internally reads `Integration`
  (`fundamentals_budget.rb:18`), which is **Administration's** model. So a Trading use case reaches,
  through an unmarked MarketData service, into Administration — a three-context hop nothing records.
- **Recommendation:** Add the tag to `DayChange.by_asset` (it is genuinely read API — two Trading
  callers, and it is just `from_closes` mapped). For `FundamentalsBudget`, either mark it and accept
  the Administration read as shared-kernel (`Integration` is already read from five places, Appendix),
  or move the budget figure into the `LoadTrackedAssets` response via a
  `MarketData::Queries::FundamentalsBudget` wrapper. Then change `audit-entropy.sh:50` to allowlist
  by scanning for the tag instead of hardcoding one class name.

---

### [BND-12] Administration publishes MarketData's events — the deferral ADR-002 admits was never written
- **Severity:** P2
- **Effort:** M
- **Where:** `app/contexts/administration/use_cases/assets/create_asset.rb:10`,
  `app/contexts/administration/use_cases/assets/delete_asset.rb:12`
- **Evidence:**
  ```ruby
  _ = yield publish(MarketData::Events::AssetCreated.new(asset_id: ..., symbol: ..., admin_id: ...))
  ```
  Subscribers: `Administration::Handlers::CreateAuditLogOnAssetCreation`,
  `MarketData::Handlers::SyncAssetOnCreation`, `MarketData::Handlers::BackfillHistoryOnAssetCreation`
  (`event_subscriptions.rb:11-14`).
- **Why it matters:** An event is a statement by the context that owns the fact. Here Administration
  asserts a MarketData fact about an `Asset` that Administration itself created
  (`create_asset.rb:40` — `Asset.new(...)`), and MarketData reacts by syncing it. Functionally it
  works; structurally it means `Asset` is owned by nobody: written by Administration, evented by
  Administration on MarketData's behalf, synced by MarketData, read by everyone. ADR-002's 2026-08-27
  amendment names this explicitly as still open and un-numbered: *"`Administration::UseCases::Assets::*`
  still publishes `MarketData::Events::Asset*`. Neither has been decided — only un-numbered."*
- **Recommendation:** This is the ADR that should be written before any of the refactors above,
  because it decides who owns `Asset` — and that answer changes BND-11 and half the Appendix.
  Two coherent options: (a) `Asset` is MarketData's, Administration calls
  `MarketData::UseCases::TrackAsset` which creates and publishes; or (b) `Asset` is declared shared
  kernel and `AssetCreated` moves to a neutral namespace. Given D9 moved the catalogue to `/tracked`
  and `Trading::UseCases::LoadTrackedAssets` now owns that screen, (a) with Trading — not
  Administration — as the caller may be the honest reading of where the work went.

> **C2 Hiroto:** *This is the one to decide first. Four of the findings above are arguments about
> where a read belongs, and all four resolve differently depending on whether `Asset` is MarketData's
> aggregate or the shared kernel. Right now the codebase answers "both", which is why
> `Administration::UseCases::Assets::CreateAsset` can write a row and then speak in another
> context's voice about it.*

---

### [BND-13] Alerts reads MarketData and Trading models with no ADR covering either pair
- **Severity:** P2
- **Effort:** S
- **Where:**
  - `app/contexts/alerts/domain/date_based_alert_evaluator.rb:52,84` — `MarketHoliday` (MarketData)
  - `app/contexts/alerts/domain/date_based_alert_evaluator.rb:31`, `alerts/use_cases/evaluate_rules.rb:5` — `Asset`
- **Evidence:**
  ```ruby
  holiday = MarketHoliday.find_by(market: :BMV, date: target_date)
  candidate += 7 while MarketHoliday.holiday?(market: :Banxico, date: candidate)
  ```
- **Why it matters:** `MarketHoliday` is read from exactly one place outside its own model, and that
  place is another context. ADR-002 is scoped strictly to Trading↔MarketData
  (*"This ADR is scoped strictly to Trading↔MarketData"*), so Alerts→MarketData is governed by
  nothing — yet Alerts already does it correctly for prices (`alert_evaluator.rb:47,56` go through
  `Queries::PriceSeries`). One evaluator uses the read API, its sibling reaches for the model. That
  inconsistency inside a single directory is the strongest evidence that the convention is
  understood but unenforced.
- **Recommendation:** `MarketData::Queries::MarketCalendar` with `.holiday?(market:, date:)` and
  `.holiday_on(market:, date:)`, mirroring what `PriceSeries` already does for prices. Cheap, and it
  makes the Alerts→MarketData pair consistent with itself. `Asset` stays as shared-kernel reads
  per ADR-002 §Gray-zone.

---

### [BND-14] `Notification` is read directly from Trading and MarketData for dedup
- **Severity:** P2
- **Effort:** S
- **Where:** `app/contexts/trading/use_cases/notify_approaching_maturities.rb:60`,
  `app/contexts/market_data/use_cases/notify_approaching_earnings.rb:41`
- **Evidence:**
  ```ruby
  # trading — bulk, correct shape
  Notification.where(notifiable_type: "Position", notification_type: :maturity_reminder)
              .where(notifiable_id: positions.map(&:id)).where(created_at: Date.current.all_day).pluck(:notifiable_id)

  # market_data — per-user-per-event, inside a nested loop
  Notification.where(user: user, notifiable: event, notification_type: :earnings_reminder).exists?
  ```
- **Why it matters:** Notifications exposes a write API (`CreateNotification`, called correctly from
  three contexts) and no read API, so "have I already sent this?" — a question every notifier asks —
  is answered by reaching into its table. Two callers, two different implementations of the same
  idempotency rule, and the MarketData one is an N+1 inside `upcoming_events.each { users_watching(...).each { ... } }`.
  The dedup rule is Notifications' invariant and it currently lives, twice, outside Notifications.
- **Recommendation:** `Notifications::Queries::AlreadySent.call(type:, notifiable_ids:, on: Date.current)`
  returning the set of ids already notified — the Trading shape, which is the right one. Both
  callers collapse to one line and the N+1 goes away with them.

---

### [BND-15] `Administration::Handlers::RecordUnhandledError` is in `handlers/` but is not an event handler
- **Severity:** P2
- **Effort:** S
- **Where:** `app/contexts/administration/handlers/record_unhandled_error.rb`; subscribed at
  `config/initializers/error_reporting.rb:5` via `Rails.error.subscribe`
- **Evidence:** It is the only file under any `*/handlers/` directory with no `EventBus.subscribe`
  line in `event_subscriptions.rb`.
- **Why it matters:** Small, but it is the single exception to an otherwise perfect invariant —
  "everything in `handlers/` is wired in `event_subscriptions.rb`" is a property you can check in
  one grep, and this file costs you that. Anyone auditing for dead handlers (as this audit did) hits
  it first and has to go find out why.
- **Recommendation:** Either move it to `app/contexts/administration/subscribers/` (it is a
  `Rails.error` subscriber, a different port), or leave it and add one line to
  `event_subscriptions.rb` documenting that it is wired elsewhere. Do not leave it silently
  exceptional.

---

## What is actually holding

Worth stating plainly, because the findings above are a list of problems and the picture is not all bad:

- **Trading → MarketData reads are clean.** Zero MarketData AR models are read from
  `app/contexts/trading/` — `NewsArticle`, `MarketIndex`, `FearGreedReading`, `TechnicalObservation`,
  `AssetPriceHistory`, `Dividend`, `TrendScore`, `CetesRateHistory` all appear **only** inside
  MarketData. The #33 refactor landed and held. This was the original violation ADR-002 was written
  about and it is gone.
- **No gateway is instantiated from Trading.** `MarketData::Gateways::*.new` appears only in
  `app/contexts/market_data/` and `app/jobs/` (the latter sanctioned by ADR-002 §Gray-zone). The
  "known leak" comment the ADR quoted no longer exists anywhere.
- **Views and helpers are clean.** Four AR constant references across `app/views/` + `app/helpers/`
  total, all shared-kernel (`Asset.find_by` ×2, `Asset.asset_types`, `FxRateHistory.rate_on`). No
  view reaches into a context's internals.
- **Event payloads are all scalars.** Every one of the 22 events carries `Types::Integer` /
  `Types::String` ids and primitives — not a single AR object. Async dispatch is safe on that axis;
  the only serialization risk is the nested-Hash one in BND-03.
- **Controllers dispatch to use cases.** 71 cross-context references from `app/controllers/`, all
  `UseCases::` or `Domain::` — one apparent handler call turned out to be a comment
  (`market_controller.rb:42`).

---

## Appendix A — model → contexts that touch it

Ownership is **inferred** (no mapping file exists — that absence is BND-10). "Owner" = the context
that writes it and holds its invariants. Counts are grep hits over `app/`, excluding `app/models/`.

| Model | Inferred owner | Contexts touching | Top-level (jobs/controllers/views/helpers/shared) | Note |
|---|---|---|---|---|
| **`Asset`** | **contested** | trading 15, administration 15, market_data 13, alerts 3, notifications 1, identity 1 | jobs 21, views 7, controllers 6, shared 3, helpers 3 | **6/6 contexts.** Written by Administration, evented by Administration as MarketData's, read everywhere. ADR-002 §Gray-zone calls it shared kernel and defers. BND-12. |
| **`User`** | Identity | identity 9, notifications 3, market_data 2, administration 1 | views 5, controllers 5, jobs 2, helpers 1 | **4 contexts.** Shared kernel de facto; ADR-002 says User↔Portfolio is "too entangled to ADR-002-ify". |
| **`SystemLog`** | Administration | market_data 7, administration 6 | jobs 9, shared 8 | **2 contexts + 17 top-level.** Written by 4 shared services (`CircuitBreaker`, `DataFreshness`, `HealthMetrics`, `SourceChange`) and 9 jobs. Effectively infrastructure, not a context's aggregate. |
| **`Integration`** | Administration | administration 11, market_data 5, identity 1 | jobs 5, controllers 5, shared 3 | **3 contexts.** Written by Identity at first boot (BND-02) and by Administration; read by MarketData (`FundamentalsBudget`, `ProviderDirectory`) and `ApiKeyResolver`. |
| **`AuditLog`** | Administration | identity 4, trading 3, administration 3 | — | **3 contexts.** Every writer is an event handler, which is the correct shape — this is the one shared model whose sharing is disciplined. |
| **`Notification`** | Notifications | notifications 6, trading 1, market_data 1 | helpers 1 | **3 contexts.** Foreign reads are dedup checks. BND-14. |
| **`AlertRule`** | Alerts | alerts 5, trading 3, notifications 1 | helpers 4, controllers 2, views 1, jobs 1 | **3 contexts.** Foreign uses are the `PRICE_THRESHOLD_CONDITIONS` constant + `notifiable` polymorphism — constant reads, not queries. Tolerable. |
| **`Position`** | Trading | trading 9, notifications 1, market_data 1 | jobs 3, helpers 1 | **3 contexts.** MarketData hit is BND-01; Notifications hit is `ASSET_OWNING_NOTIFIABLES` polymorphism. |
| **`FxRate` / `FxRateHistory`** | MarketData | market_data 4, trading 4, identity 1 | controllers 2, helpers 2 | **3 contexts.** Explicitly tolerated shared kernel per ADR-002 §Allowed + the 2026-08-29 amendment. Identity write is BND-02. |
| **`WatchlistItem`** | Trading | market_data 1 | views 1 | Sole foreign read is BND-01. |
| **`MarketHoliday`** | MarketData | alerts 2 | — | Read **only** from Alerts, never from its owner. BND-13. |
| **`DividendPayment`** | **contested** | — | jobs 1 (write) | Written only in `SyncDividendsJob`; read via `portfolio.dividend_payments` association from Trading; joins Portfolio↔Dividend. BND-08. |
| **`Portfolio`** | Trading | trading 8 | jobs 2, views 1, helpers 1 | Job writes are BND-09 / BND-08. |
| **`PortfolioSnapshot`** | Trading | trading (via `portfolio.snapshots`) | jobs 1 (write) | Two writers, divergent semantics. BND-09. |
| **`MarketIndex` / `MarketIndexHistory`** | MarketData | market_data 2, identity 1 | jobs 5 | Identity hit is BND-02. |
| **`SiteConfig` / `SiteConfigChange`** | Administration | identity 1 | controllers 9, views 1, jobs 1, mailers 1 | Read from controllers as global config; Identity write is BND-02. |
| `Trade` | Trading | trading 14 | jobs 1, views 1 | Job hit is `SyncDividendsJob` (BND-08). |
| `EarningsEvent` | MarketData | market_data 1, notifications 1 | helpers 1 | Notifications hit is polymorphism. |
| `AssetPriceHistory` | MarketData | market_data 5 | jobs 2, views 1 | Clean — all Trading reads go through `Queries::PriceSeries`. |
| `TechnicalObservation` / `TechnicalReading` | MarketData | market_data 7 | views 1 | Clean — Trading goes through `Queries::NotableObservations`. |
| `NewsArticle` | MarketData | market_data 5 | — | Clean. The `Identity::GlobalSearch` leak ADR-002 flagged is gone with the use case. |
| `FearGreedReading` | MarketData | market_data 5 | jobs 1 | Clean — Trading goes through `Queries::CurrentFearGreed`. |
| `TrendScore` | MarketData | market_data 4 | jobs 2 | Clean. |
| `Dividend` | MarketData | market_data 3 | — | Clean at the constant level; reached via association (BND-08). |
| `CetesRateHistory` | MarketData | market_data 4 | — | Clean — Trading goes through `Queries::CetesReinvestedReturn`. |
| `AssetFundamental` / `FinancialStatement` | MarketData | market_data 2 | jobs 3, views 1 | Clean. |
| `StockSplit` | MarketData | trading 1 | — | Read by `AdjustPositionsOnSplit` from a `SplitDetected` payload id. Note: `SplitDetected` is a **Trading** event about a MarketData model, published from `SyncSplitsJob` — a smaller instance of BND-12. |
| `AlertEvent` / `AlertPreference` | Alerts | alerts 3 | — | Clean. |
| `ErrorEvent` | Administration | administration 4 | controllers 3, views 2 | Clean. |
| `PushSubscription` / `OtpRecoveryCode` | Notifications / Identity | 1 / 0 | — | Clean. |

**The declared shared kernel should be:** `Asset`, `User`, `FxRate`, `FxRateHistory`, `SystemLog`,
`AuditLog`, `Integration`, `Notification` — eight models, touched by 3+ contexts each, none of them
written down as shared anywhere. Everything else is single-owner and should be enforced as such.

---

## Appendix B — event → publishers → subscribers

| Event | Publishers | Subscribers | Verdict |
|---|---|---|---|
| `MarketData::AssetPriceUpdated` | 4 jobs (`sync_single_asset:82`, `sync_bulk_stocks:55`, `sync_bulk_crypto:48`, `sync_bulk_bmv:81`) | 4 (1 sync-critical, ordered) | healthy; ordering unenforced (BND-04) |
| `MarketData::AssetCreated` | `administration/.../create_asset.rb:10` | 3 | foreign publisher (BND-12) |
| `MarketData::AssetDeleted` | `administration/.../delete_asset.rb:12` | 1 | foreign publisher (BND-12) |
| `MarketData::AssetFundamentalsUpdated` | `sync_fundamental_job:42`, `recalculate_fundamentals_on_statements_synced.rb:42` | 2 | cascade (BND-05) |
| `MarketData::FinancialStatementsSynced` | `sync_statements_job:41` | 1 (sync, heavy) | BND-05 |
| `MarketData::MarketIndicesUpdated` | `sync_market_indices_job:23` | **0** | **dead** (BND-06) |
| `MarketData::{News,Earnings,Cetes,Dividends}Synced`, `FearGreedUpdated`, `AllGatewaysFailed` | 1 each | 1 log handler each | healthy |
| `Trading::TradeExecuted` | `execute_trade.rb:20` | 3 | healthy; first subscriber takes a lock (BND-04) |
| `Trading::TradeUpdated` / `TradeDeleted` | 1 each | 2 each | healthy; `changes` is a `Types::Hash` on an async path (BND-03) |
| `Trading::TradesImported` | `import_trades.rb:210` | **0** | **dead** (BND-06) |
| `Trading::SplitDetected` | `sync_splits_job:28` | 1 | Trading event published from a MarketData sync job |
| `Alerts::AlertRuleTriggered` | `evaluate_rules.rb:22`, `evaluate_date_based_rules.rb:20` | 2 | healthy |
| `Notifications::NotificationCreated` | `create_notification.rb:16` | 3 | healthy |
| `Identity::{FirstAdminCreated,PasswordChanged,ProfileUpdated,UserLoggedIn,UserLoginFailed}` | 1-2 each | 1-2 each | healthy; `FirstAdminCreated` under-used (BND-02) |
| `Administration::{CsvExported,Integration*}` | 1 each | 1 each | healthy |

**Handlers with no EventBus subscription:** 1 — `Administration::Handlers::RecordUnhandledError`
(wired to `Rails.error` instead; BND-15). **Events defined but never published:** none.
**Subscriptions to events nobody publishes:** none.

---

## Priority order

1. **BND-12** — decide who owns `Asset`. Four other findings resolve differently depending on the answer. Write the ADR ADR-002 has been deferring since 2026-05.
2. **BND-04** — five lines, removes a class of silent partial dispatch.
3. **BND-01** — the inverse leak. It is what the ADR was written to prevent.
4. **BND-02** — largest cross-context write, and the event to fix it already exists.
5. **BND-03** — deletes 28 lines of glue and closes a silent async/sync divergence.
6. **BND-10** — without it, everything above regresses unnoticed. Ship it with the ADR from #1.
7. The rest, in severity order.
