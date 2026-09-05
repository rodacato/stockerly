# Audit 05 — External integration layer (MarketData gateways + shared resilience)

**Scope:** `app/contexts/market_data/gateways/` (14 files), `app/shared/domain/` (gateway-related),
`config/initializers/data_sources.rb`. Read-only audit, 2026-08-30, branch `fix/capture-daily-volume`.
No network calls made. Line numbers verified against working tree.

**Headline:** the layer is *conceptually* right — one failure vocabulary (`GatewayFailure`), a
registry-driven fallback chain, a circuit breaker that distinguishes permanent from transient
denial, one key per provider per ADR-015. Every one of those ideas is sound and several are
better than what most hobby projects ship. What is wrong is that the ideas are **applied
unevenly**: two gateways bypass the rate limiter, two bypass the breaker entirely, the breaker's
recovery path is unreachable through the chain that is supposed to use it, and the base classes
are 54 lines of `NotImplementedError` while ~200 lines of identical HTTP plumbing sit copy-pasted
across nine adapters.

---

## Findings

### [GW-01] The circuit breaker can never close again when driven through `GatewayChain`
- **Severity:** P0
- **Effort:** S (<1h)
- **Where:** `app/shared/domain/gateway_chain.rb:18`, `:52`, `:83`, `:112`, `:158` vs
  `app/shared/domain/circuit_breaker.rb:40-46`
- **Evidence:**
  ```ruby
  # gateway_chain.rb:18
  if breaker && breaker.state == :open
    attempted << gateway.class.name
    next                       # <- never reaches breaker.call
  end
  ```
  ```ruby
  # circuit_breaker.rb:40-46 — the ONLY place half_open is entered
  when :open
    if timeout_elapsed?
      transition_to(:half_open)
      execute(block)
  ```
- **Why it matters:** `state` is a plain `attr_reader` (`circuit_breaker.rb:13`); it does not
  consult `timeout_elapsed?`. The chain reads it, sees `:open`, and skips — so the recovery
  transition inside `#call` is unreachable from the chain. The breaker is memoized in a process-
  lifetime hash (`gateway_chain.rb:185`), so **an opened breaker stays open until the process
  restarts**.

  This is not theoretical. `record_permanent_failure` (`circuit_breaker.rb:84-90`) opens the
  breaker on the **first** failure whose tag is in `GatewayFailure::PERMANENT`
  (`gateway_failure.rb:10`), which includes `:not_supported` and `:invalid_request` — exactly the
  two tags `PythonRunner` returns for a missing script (`python_runner.rb:25`) or a symbol that
  fails `SAFE_ARGUMENT` (`python_runner.rb:29`). One dividend sync for one asset whose Yahoo
  symbol contains an out-of-charset character permanently removes YfinanceGateway from the
  `:dividends`, `:splits` **and** `:prices` chains — silently, for every asset, for the life of
  the container.

  Providers reached *only* through the chain and therefore unrecoverable: **Finnhub, FMP,
  Yahoo Finance**. Alpaca / CoinGecko / DataBursatil / Alpha Vantage / Alternative.me happen to
  recover because a bulk job calls `breaker.call` directly on the same memoized breaker
  (`sync_bulk_stocks_job.rb:18`, `sync_bulk_crypto_job.rb:15`, `sync_bulk_bmv_job.rb:21`,
  `sync_statements_job.rb:26`, `refresh_fear_greed_job.rb:17`). That is luck, not design.
- **Recommendation:** delete the pre-check. `CircuitBreaker#call` already returns
  `Failure([:circuit_open, ...])` for a genuinely open breaker, which is the same outcome the
  pre-check produces, minus the bug. If a cheap "skip without invoking" is wanted, expose
  `breaker.open?` that folds `timeout_elapsed?` into the answer.

---

### [GW-02] `FxRatesGateway` and `BanxicoGateway` declare a circuit breaker key that nothing ever uses
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `config/initializers/data_sources.rb:127` (`circuit_breaker_key: "fx"`), `:141`
  (`"banxico"`, also `:173`); `app/jobs/refresh_fx_rates_job.rb:14`;
  `app/contexts/market_data/use_cases/sync_fx_history.rb:12`;
  `app/contexts/market_data/use_cases/sync_cetes.rb:10`
- **Evidence:**
  ```ruby
  # refresh_fx_rates_job.rb:14 — no breaker, no chain
  result = MarketData::Gateways::FxRatesGateway.new.refresh_rates
  ```
  ```ruby
  # sync_cetes.rb:10
  result = Gateways::BanxicoGateway.new.fetch_auctions(term: term)
  ```
  Grep confirms `GatewayChain.breaker_for` is called for exactly five keys — `alpha_vantage`,
  `databursatil`, `crypto`, `crypto_fear_greed`, `alpaca` — and neither `fx` nor `banxico` is
  among them. `:fx_current`, `:fx_history` and `:cetes` are never passed to `for_capability`
  either, so the chain never builds one.
- **Why it matters:** Banxico is the single provider where a breaker matters most, and the
  gateway's own comment says why (`banxico_gateway.rb:63-65`): *"Banxico allows twenty series per
  call and blocks an abusing token for a full calendar day — and this token serves FX as well."*
  A hammering retry loop against Banxico costs the FX FIX **and** CETES for 24 hours, and that FX
  FIX is the input to the historical-rate cost basis the whole multi-currency story rests on.
  Meanwhile the registry advertises protection that does not exist, so the Integraciones screen
  and any future reader are misled.
- **Recommendation:** wrap both direct call sites in `GatewayChain.breaker_for(key).call { ... }`
  — that is the pattern `sync_bulk_*_job` already uses and it is three lines each. Or remove the
  `circuit_breaker_key` from those registrations so the config stops lying.

---

### [GW-03] The only provider with a hard, exhaustible monthly budget is the only one that skips `RateLimiter`
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/contexts/market_data/gateways/data_bursatil_gateway.rb` — zero occurrences of
  `RateLimiter.check!` in 193 lines; contrast `finnhub_gateway.rb:20,51,77,100,123`,
  `coingecko_gateway.rb:58,81,105`, `banxico_gateway.rb:41,68,107`
- **Evidence:**
  ```ruby
  # data_bursatil_gateway.rb:150 — the only guard is Faraday
  def get(path, params)
    response = connection.get(path) do |req|
      req.params.update(params.transform_keys(&:to_s).merge("token" => @token))
    end
  ```
  Its own header comment (`:7-10`) states the stakes: *"Quota is metered in transmitted bytes
  rather than requests — one credit per KiB, rounded up, out of 200,000 a month."*
- **Why it matters:** every other gateway burns a counted call; DataBursatil burns an *uncounted*
  variable-size one. A runaway `SyncBulkBmvJob` or a wide `fetch_historical` can eat the monthly
  allowance with nothing in the system able to say stop. `SourceCatalogue#quota_for`
  (`source_catalogue.rb:122-124`) papers over it by asking the provider for its own balance — but
  that read is cached for an hour (`data_bursatil_gateway.rb:121`), costs a credit itself, and is
  *reporting*, not *enforcement*.

  Secondary defect at the same place: `Rails.cache.fetch` caches `nil` by default, so one failed
  `/v2/creditos` call pins "unknown balance" for a full hour.
- **Recommendation:** add `RateLimiter.check!(PROVIDER)` to `#get` (one place — the gateway
  already funnels every request through it, unlike its siblings). Pass `skip_nil: true` on the
  credits cache. Longer term the byte-metered unit needs its own budget type; ADR-015's
  Consequences already flag this as open.

---

### [GW-04] `fetch_historical` has two incompatible signatures and three incompatible return shapes; the caller uses reflection to guess
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `app/jobs/backfill_price_history_job.rb:61-74` and `:84-101`;
  `alpaca_gateway.rb:71`, `coingecko_gateway.rb:54`, `data_bursatil_gateway.rb:80`,
  `yfinance_gateway.rb:48`, `finnhub_gateway.rb:50`
- **Evidence:**
  ```ruby
  # backfill_price_history_job.rb:61-74
  if accepts_days?(gateway)
    gateway.fetch_historical(symbol, days: DAYS)
  else
    gateway.fetch_historical(symbol, DAYS.days.ago.to_date, Date.current)
  end
  ...
  def accepts_days?(gateway)
    gateway.method(:fetch_historical).parameters.any? { |_type, name| name == :days }
  end
  ```
  Return shapes, all under one registered `:historical` capability:
  | Gateway | shape |
  |---|---|
  | Alpaca `:209-218`, Finnhub `:167-176`, Yahoo `:49-60` | `{date:, open:, high:, low:, close:, volume:}` |
  | CoinGecko `:163-172` | same keys, but `open == high == low == close` and `volume: nil` |
  | DataBursatil `:86-93` | **`{date:, close:, amount:}`** — no `open`/`high`/`low`/`volume` |
- **Why it matters:** the comment at `:70-71` (*"ask the method rather than branch on the class"*)
  is honest about the smell and then ships it anyway — introspecting a method signature to decide
  how to call it is the caller special-casing per provider with extra steps. Worse is the return
  side: `upsert_bars` (`:89-99`) reads `bar[:open]`, `bar[:high]`, `bar[:low]`, `bar[:volume]`,
  which are all `nil` for every BMV asset. `AssetPriceHistory` only validates `close`
  (`app/models/asset_price_history.rb:8`) and the OHLC columns are nullable
  (`db/schema.rb:77-84`), so **BMV backfills write close-only rows and silently drop `:amount`**
  with no log line and no failure. Any candle chart or volatility calculation over a BMV asset is
  reading NULLs it cannot distinguish from "market was closed".

  `BackfillPriceHistoryJob#attempt` (`:38-53`) is also a **third** hand-rolled fallback loop —
  after `GatewayChain` and after the per-job `breaker.call` pattern — and this one has no circuit
  breaker at all.
- **Recommendation:** settle one signature — `fetch_historical(symbol, from:, to:)` — and adapt
  `days:` inside the two gateways that prefer periods. Add `fetch_historical` to `GatewayChain`
  (it is the missing sixth method) and delete `attempt`/`accepts_days?`. Make the bar shape
  explicit: either DataBursatil fills `open/high/low` with `close` the way CoinGecko does, or the
  contract declares them optional and `upsert_bars` stops pretending it got a candle.

---

### [GW-05] The base classes carry nothing; ~200 lines of identical plumbing are copy-pasted across nine adapters
- **Severity:** P1
- **Effort:** L (>4h)
- **Where:** `market_data_gateway.rb:19-25`, `fundamentals_gateway.rb:9-23` (the whole of both);
  `resolve_api_key` at `alpaca:251`, `alpha_vantage:207`, `banxico:82`, `coingecko:208`,
  `data_bursatil:184`, `finnhub:239`, `fmp:172`, `fx_rates:63`
- **Evidence:** eight `resolve_api_key` definitions, byte-identical modulo indentation
  (md5 of the body is the same for six of them, and the other two differ only by leading spaces):
  ```ruby
  def resolve_api_key
    key = ApiKeyResolver.for(PROVIDER)
    raise ApiKeyNotConfiguredError.new(PROVIDER) if key.blank?
    key
  rescue ActiveRecord::Encryption::Errors::Decryption
    raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "decryption failed")
  end
  ```
  Nine near-identical `def connection` Faraday builders (only `TIMEOUT` and the auth header vary).
  Two identical `safe_decimal` methods (`alpha_vantage:200-205`, `fmp:126-131`). **22**
  `rescue Faraday::Error => e; Failure([:gateway_error, e.message])` sites, and **21**
  `GatewayFailure.from(response, PROVIDER) unless response.success?` sites.

  Meanwhile `MarketDataGateway` is 28 lines that provide `source_id` and two
  `NotImplementedError` stubs, and `FundamentalsGateway` is 26 lines of pure
  `NotImplementedError` with exactly one subclass — while `FmpGateway`, which implements
  `fetch_overview` (`fmp_gateway.rb:18`), inherits from **`MarketDataGateway`**
  (`fmp_gateway.rb:5`), not from the fundamentals port it actually implements.

  The fix already exists in-repo and was applied twice: `AlpacaGateway#get`
  (`alpaca_gateway.rb:182-191`) and `DataBursatilGateway#get`
  (`data_bursatil_gateway.rb:150-160`) collapse request + status mapping + `Faraday::Error`
  rescue into one private method. Those two gateways have **1** rescue site each; Finnhub has 6.
- **Why it matters:** it is not aesthetic. Every one of the inconsistencies in this report lives
  in a block that would be one shared method: `AlphaVantageGateway` is the only gateway that
  catches `Faraday::TimeoutError` distinctly (`:37-38`), so nine others report a timeout as a
  generic `:gateway_error`. `DataBursatilGateway` is the only one missing `RateLimiter` [GW-03]
  because the check is pasted per-method rather than centralised. Adding an eleventh provider
  means pasting the block again and hoping.
- **Recommendation:** move `resolve_api_key`, `safe_decimal`, and a `request(path, params)` that
  does `RateLimiter.check!` → HTTP → `GatewayFailure.from` → `rescue Faraday::TimeoutError /
  Faraday::Error` into `MarketDataGateway`, with `connection` built from declared
  `BASE_URL`/`TIMEOUT`/auth-strategy constants. Fold `FundamentalsGateway` into it or delete it —
  one abstract class with one subclass and a sibling that implements its port without inheriting
  it is not a port, it is a file.

---

### [GW-06] `FinnhubGateway#fetch_bulk_prices` swallows every failure and returns `Success([])`
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/contexts/market_data/gateways/finnhub_gateway.rb:37-46`
- **Evidence:**
  ```ruby
  def fetch_bulk_prices(symbols)
    results = symbols.filter_map do |symbol|
      result = fetch_price(symbol)
      result.value! if result.success?      # every failure discarded
    end

    Success(results)
  end
  ```
- **Why it matters:** rate-limited, unauthorized, circuit-open and "no such ticker" all become the
  same empty array wrapped in `Success`. The caller cannot tell "these symbols have no data" from
  "the provider is refusing us", the circuit breaker never sees a failure to count, and the daily
  budget is spent one call per symbol on the way to reporting success. Compare
  `YfinanceGateway#fetch_index_quotes` (`:108-125`), which does the same per-symbol loop but at
  least returns `Failure([:not_found, ...])` when nothing survived; and `AlpacaGateway#fetch_bulk_prices`
  (`:98`), which returns `Failure` on an empty result.
- **Recommendation:** return `Failure` when every symbol failed, and propagate the first
  `:rate_limited` / `:unauthorized` immediately rather than continuing to spend quota. Better:
  drop the method — Finnhub has no batch endpoint, and the `:prices` chain already reaches it
  through `fetch_price`.

---

### [GW-07] `BanxicoGateway#parse_date` turns an unparseable date into today
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `app/contexts/market_data/gateways/banxico_gateway.rb:192-196`
- **Evidence:**
  ```ruby
  def parse_date(fecha_str)
    Date.strptime(fecha_str, "%d/%m/%Y")
  rescue Date::Error
    Date.current
  end
  ```
- **Why it matters:** this is used by both `auctions_from` (`:151`) and `parse_fixes` (`:168`).
  A malformed or unexpected `fecha` does not raise, does not log, and does not skip the row — it
  **relabels someone else's rate as today's**. `SyncFxHistory` then upserts that as the USD/MXN
  FIX for the current date, and the FIX is the input to the historical cost basis that ADR-010's
  multi-currency correctness depends on. Every sibling parse path does the opposite and drops the
  row: `alpaca_gateway.rb:118` (`rescue Date::Error; next`), `fmp_gateway.rb:146`,
  `data_bursatil_gateway.rb:91`.
- **Recommendation:** `rescue Date::Error; nil` and `next if date.nil?` in both callers, matching
  the three gateways that already do it.

---

### [GW-08] `RateLimiter` is counted in the wrong place, so the budget is wrong in both directions
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/shared/domain/rate_limiter.rb:16-35`; `app/models/integration.rb:9-16`;
  every gateway's `RetryPolicy.options(max: 2, ...)` (e.g. `finnhub_gateway.rb:142`)
- **Evidence:**
  ```ruby
  # rate_limiter.rb:30-33 — increment happens BEFORE the HTTP call
  integration.increment_minute_calls! if integration.max_requests_per_minute.present?
  integration.increment_api_calls!

  Success(:allowed)
  ```
- **Why it matters:** two opposite errors at once. **Undercount:** Faraday's retry middleware is
  configured `max: 2` on eight gateways, so one accepted `check!` can produce **three** real HTTP
  requests against the provider's quota while our counter records one. **Overcount:** the counter
  is spent even when the request is never made or fails locally, and a `GatewayChain` walk of
  three gateways bills three providers for one price. On a 25-call/day Alpha Vantage key (ADR-015
  removed the pooling that used to hide this) a 3× undercount is the difference between "budget
  remaining" and a hard 429 day.

  Cost note: `check!` does `find_by` + `update_counters` + `reload` per call
  (`integration.rb:13-14`) — three or four queries per outbound HTTP request. Irrelevant at
  single-user volume, but it is the reason the limiter is skipped in hot paths.
- **Recommendation:** move the increment to after the response (or to a Faraday middleware, which
  also fixes the retry undercount), and have `check!` reserve rather than consume.

---

### [GW-09] Our own rate-limit refusals feed the circuit breaker
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `app/shared/domain/circuit_breaker.rb:64-66`; `app/shared/domain/gateway_failure.rb:10`
- **Evidence:** `RateLimiter.check!` returns `Failure([:rate_limited, ...])`, gateways return it
  verbatim (e.g. `finnhub_gateway.rb:21-22`), and `CircuitBreaker#execute` counts any
  `Dry::Monads::Result` failure:
  ```ruby
  if result.is_a?(Dry::Monads::Result) && result.failure?
    GatewayFailure.permanent?(failure_tag(result)) ? record_permanent_failure : record_failure
  ```
- **Why it matters:** five refusals from *our own* limiter — a condition where no request left the
  machine and the provider is perfectly healthy — open the breaker. Combined with [GW-01], a
  quota-exhausted Finnhub or FMP is removed from its chain for the life of the process, and the
  next day's fresh quota never gets used. The breaker exists to detect *provider* health; a local
  budget decision is not evidence of it.
- **Recommendation:** short-circuit `:rate_limited` and `:circuit_open` in `execute` — return the
  failure without recording it. Alternatively check the limiter outside `breaker.call`.

---

### [GW-10] `GatewayChain` is 222 lines of which ~110 are the same loop written five times
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/shared/domain/gateway_chain.rb:12-142` vs `:150-172`
- **Evidence:** `fetch_price` (12), `fetch_overview` (44), `fetch_news` (75), `fetch_earnings`
  (104) and `fetch_index_quotes` (133) each spell out: iterate, look up breaker, skip if open,
  call through breaker, return on success, accumulate `attempted`. `first_answer` (`:150`) is that
  loop, generically, and its own comment concedes the point:
  > `# The five methods above each spell this loop out; these two share it. The`
  > `# older five differ in what they stamp on the value, which is why they stay.`

  The stated justification does not hold for three of the five: `fetch_news` (`:94-96`) and
  `fetch_earnings` (`:123-125`) stamp **nothing** and are `first_answer` verbatim.
  `fetch_index_quotes` (`:133-142`) is worse — it silently **drops breaker support entirely**,
  which is why `SyncMarketIndicesJob` (`sync_market_indices_job.rb:15-18`) builds a chain with no
  breakers and nobody noticed.
- **Why it matters:** this is the object where [GW-01] hides, and it hides in five places instead
  of one. Five copies of a loop is five places to forget the breaker — and one of them already
  did. Verdict on the "is it over-engineered?" question: **`GatewayChain`'s size is duplication,
  not sophistication.** The chain concept earns its keep (registry-driven fallback across ten
  providers is exactly what this app needs); ~90 lines would deliver it.
- **Recommendation:** reduce to `first_answer(method, *args)` plus a per-method post-processing
  hook for the two that stamp `data_source`/`source`. Add the missing `fetch_historical` [GW-04]
  while collapsing.

---

### [GW-11] `GatewayChain::BREAKERS` is an unsynchronised mutable class constant, scoped to one process
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/shared/domain/gateway_chain.rb:185-189`
- **Evidence:**
  ```ruby
  BREAKERS = {}

  def self.breaker_for(key)
    BREAKERS[key] ||= CircuitBreaker.new(name: "#{key}_gateway", threshold: 5, timeout: 60)
  end
  ```
- **Why it matters:** `Hash#[]=` under `||=` is not atomic across Puma's threads, so two threads
  racing the same key can each build a breaker and one set of failure counts is discarded. More
  materially, the breaker is **per-process**: `config/deploy.yml` runs a `web` role and a `job`
  role as separate containers, and `CircuitBreaker` holds `@state`/`@failure_count` in instance
  variables. The `job` container's knowledge that Yahoo is down is invisible to the `web`
  container, and vice versa. It also means every deploy silently resets every breaker — which is
  currently the *only* recovery mechanism for the providers in [GW-01].
- **Recommendation:** at this scale the honest fix is small: back the breaker state with
  `Rails.cache` (Solid Cache is already the store) keyed by breaker name, and guard the registry
  with a `Mutex`. That makes the state shared, survivable, and inspectable from `/admin`.

---

### [GW-12] Dead code across gateways, capabilities and base classes
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** verified by grep over `app/` and `lib/` excluding the gateways directory itself
- **Evidence:**
  | Symbol | Where | Callers outside gateways |
  |---|---|---|
  | `CoingeckoGateway#fetch_market_data` | `coingecko_gateway.rb:101` | 0 — and `:market_data` (`data_sources.rb:52`) is never passed to `for_capability` |
  | `DataBursatilGateway#fetch_intraday` | `data_bursatil_gateway.rb:103` | 0 — `:intraday` (`:70`) never requested |
  | `BanxicoGateway#fetch_all_terms` | `banxico_gateway.rb:67` | 0 — despite the comment at `:62-65` arguing it is the call that saves the token |
  | `FinnhubGateway#fetch_historical` | `finnhub_gateway.rb:50` | 0 — and `data_sources.rb:36-37` records that `/stock/candle` is premium and answers 403 forever |
  | `FinnhubGateway#search_tickers`, `AlphaVantageGateway#search_tickers` | `:122`, `:63` | 0 — `SearchTickers` (`search_tickers.rb:12`) hardcodes `YfinanceGateway`; capability `:search` (`data_sources.rb:38`) never requested |
  | `CircuitBreaker::STATES` | `circuit_breaker.rb:11` | 0 anywhere |
  | `FundamentalsGateway` | whole file | one subclass; `FmpGateway` implements the same port from a different parent — see [GW-05] |
- **Why it matters:** three registered capabilities (`:market_data`, `:intraday`, `:search`) and
  four unregistered ones (`:sentiment`, `:indices`, `:fx_current`, `:fx_history`, `:cetes`) are
  never resolved through `for_capability`, so `data_sources.rb` reads as a richer contract than
  the code honours. `FinnhubGateway#fetch_historical` is a method the project has documented
  cannot work.
- **Recommendation:** delete `fetch_historical` and `search_tickers` from Finnhub, `search_tickers`
  from Alpha Vantage, `STATES`. Keep `fetch_intraday`/`fetch_market_data`/`fetch_all_terms` only
  if a discovery card names the consumer — otherwise they are anti-pattern #1 in
  `IDENTITY.md`'s list. Strip capability keys nobody resolves, or route the consumers through
  the registry so the declaration becomes true.

---

### [GW-13] Timestamp handling is inconsistent, and two gateways derive dates in the system zone
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `coingecko_gateway.rb:165`, `finnhub_gateway.rb:169`, `crypto_fear_greed_gateway.rb:43`,
  `alpaca_gateway.rb:211`, `:230`
- **Evidence:** four different idioms for the same job:
  ```ruby
  coingecko:165           date: Time.at(timestamp_ms / 1000).to_date          # system zone
  finnhub:169             date: Time.at(body["t"][i]).to_date                 # system zone
  finnhub:194             published_at: Time.at(item["datetime"]).in_time_zone
  crypto_fear_greed:43    fetched_at: Time.at(data["timestamp"].to_i)         # system zone, no zone
  alpaca:211              date: Time.parse(bar["t"]).to_date                  # Ruby Time, not Time.zone
  data_bursatil:146       as_of: Time.zone.parse(venue["f"])                  # correct
  yfinance:163            Time.zone.parse(value)                              # correct
  ```
- **Why it matters:** `Time.at(...).to_date` resolves in the process's system zone, not
  `Time.zone`. A UTC epoch near midnight lands on the previous day for a container running
  `TZ=America/Mexico_City` and the current day for one running UTC — so the same CoinGecko bar
  gets a different `date` depending on the host, and `AssetPriceHistory` is uniquely keyed on
  `(asset_id, date, interval)`. Self-hosters run in whatever zone their box has. No RuboCop
  `Rails/TimeZone` cop is enabled to catch it (`.rubocop.yml` has no `Rails/` section).
- **Recommendation:** one idiom — `Time.zone.at` / `Time.zone.parse` everywhere — and enable
  `Rails/TimeZone` so the eleventh gateway cannot reintroduce it.

---

### [GW-14] `fetch_price` returns five different shapes under one capability
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `finnhub_gateway.rb:154-158`, `coingecko_gateway.rb:149-153`,
  `data_bursatil_gateway.rb:141-147`, `yfinance_gateway.rb:37-43`, `alpaca_gateway.rb:31-33`
- **Evidence:**
  | Gateway | keys returned |
  |---|---|
  | Finnhub | `symbol, price, volume(always nil)` |
  | CoinGecko | `symbol, price, market_cap` — no `volume`, no `as_of` |
  | DataBursatil | `symbol, source, price, volume, as_of` |
  | Yahoo | `symbol, price, change_percent, volume, as_of` |
  | Alpaca | always `Failure([:no_entitlement, ...])` |
- **Why it matters:** `SyncSingleAssetJob#update_asset` (`sync_single_asset_job.rb:62-70`) copes
  by defaulting everything — `data[:volume] || asset.volume`, `data[:market_cap] || asset.market_cap`
  — which means "the provider does not report volume" and "volume did not change" are the same
  input. That is precisely the confusion the current branch (`5cacab1 Stop the day's half-finished
  bar from skewing volume`) is fighting downstream. `GatewayChain#fetch_price:33-34` only
  normalises `data_source` and `source`; nothing normalises the rest. No shape carries a
  `currency`, in an app whose stated differentiator is currency correctness — it works only
  because `Asset#currency` is trusted, which silently assumes CoinGecko's `QUOTE_CURRENCY = "usd"`
  (`coingecko_gateway.rb:18`) matches the asset row.
- **Recommendation:** define the quote contract once (`symbol, price:BigDecimal, currency,
  volume|nil, as_of|nil, source`) in `MarketDataGateway`, and have each adapter fill it — with an
  explicit `nil` where the provider genuinely does not report, so absent stays distinguishable
  from unchanged.

---

### [GW-15] Secrets: clean, with two structural notes
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `app/contexts/market_data/gateways/fx_rates_gateway.rb:23`;
  `app/shared/domain/api_key_resolver.rb`; `config/initializers/filter_parameter_logging.rb:7`
- **Evidence:** grep for hardcoded credentials across `app/`, `lib/`, `config/` (`.rb`, `.yml`,
  `.py`) found **none**. Every gateway resolves through `ApiKeyResolver.for(PROVIDER)` →
  `Integration#active_api_key`, backed by `encrypts :api_key_encrypted`
  (`app/models/integration.rb:4`). No `logger`/`inspect`/`SystemLog` call site interpolates a key.
  `ApiKeyNotConfiguredError` messages carry the provider name and a reason, never a value.
  All ten gateways set both `timeout` and `open_timeout` — no gateway is missing a timeout.

  Two notes:
  1. `fx_rates_gateway.rb:23` places the credential in the **URL path**:
     ```ruby
     response = connection.get("/v6/#{@api_key}/latest/#{base}")
     ```
     exchangerate-api requires this, so it is not a code choice — but it means the key is in every
     request line. There is no redaction layer, so adding `f.response :logger` or a Faraday
     instrumentation subscriber to that connection would write the key to the log immediately.
     `filter_parameter_logging.rb` filters `:_key` and `:token` on Rails params; it does not touch
     Faraday.
  2. Finnhub, Alpha Vantage, FMP and DataBursatil pass the key as a **query parameter**
     (`finnhub_gateway.rb:25`, `alpha_vantage_gateway.rb:26`, `fmp_gateway.rb:23`,
     `data_bursatil_gateway.rb:152`) — again provider-mandated. Alpaca, Banxico and CoinGecko use
     headers, which is the safer half of the split.
- **Why it matters:** the current state is genuinely safe; the exposure is that nothing *keeps* it
  safe. `Administration::Handlers::RecordUnhandledError` (`config/initializers/error_reporting.rb:5`)
  stores raw exception messages for `/admin/errors`, and a Faraday exception class that
  interpolates the request URL would land the FX key there in plaintext.
- **Recommendation:** add a shared Faraday URL-redaction step in the base-class `connection`
  builder [GW-05] so any future logger or error path is safe by construction. Do not restructure
  the calls — the providers dictate them.

---

### [GW-16] `PythonRunner` is justified, correct, and used — but the yfinance bridge spawns one interpreter per symbol
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/shared/domain/python_runner.rb`; `app/contexts/market_data/gateways/yfinance_gateway.rb:108-125`, `:145-150`
- **Evidence:** usage verified — `PythonRunner.call` is invoked from exactly one production site
  (`yfinance_gateway.rb:149`), which serves prices, history, dividends, splits, earnings, search
  and index quotes: seven of the app's data flows. `lib/python/yahoo.py` and `probe.py` are
  tracked; `requirements.txt` pins `yfinance==1.7.0` + `curl_cffi==0.16.2`; the `Dockerfile:32-37`
  builds the venv and sets `PYTHON_BIN`. The runner passes argv (no shell), validates arguments
  against `SAFE_ARGUMENT` (`:17`), enforces a 25s timeout with a real `Process.kill`, and maps the
  script's own JSON error kind back to a monad tag (`:65-70`). This is the best-implemented file
  in the audited scope.

  The one problem is at the call site:
  ```ruby
  # yfinance_gateway.rb:109-111
  quotes = symbols.filter_map do |yahoo_symbol|
    result = fetch_price(yahoo_symbol)   # one PythonRunner.call -> one interpreter
  ```
- **Why it matters:** `fetch_index_quotes` defaults to six symbols (`INDEX_SYMBOL_MAP`, `:22-29`),
  so `SyncMarketIndicesJob` spawns **six** Python processes per run, each paying the yfinance
  import cost, each taking a `RateLimiter` DB round-trip (`:146`), with a worst case of 150s of
  worker time. Yahoo is also the one provider with **no retry at all** — `RetryPolicy` never
  reaches it, so a single hiccup is a hard failure.
- **Verdict on "is Python from Ruby justified here?":** yes, unambiguously. The header comment is
  accurate — Yahoo blocks on TLS fingerprint and `curl_cffi` impersonation is the only maintained
  way through. ADR-017 quarantines the bridge to what no sanctioned provider serves, which is the
  right containment. This is boring tech solving a real pain, not novelty.
- **Recommendation:** add a `quotes` subcommand to `yahoo.py` taking a symbol list, so
  `fetch_index_quotes` is one process. Consider one retry inside `run`.

---

## Appendix — gateway matrix

| Gateway | Base class | CircuitBreaker | RateLimiter | RetryPolicy | GatewayChain | Auth | Timeout | Primary return shape |
|---|---|---|---|---|---|---|---|---|
| **Alpaca** | `MarketDataGateway` | ✅ chain (`:news/:dividends/:splits`) + direct `breaker_for("alpaca")` | ✅ 3 sites | ✅ max 2 | ✅ | header `APCA-API-KEY-ID`/`-SECRET-KEY`, key stored `ID:SECRET` | 8s | bars `{date,open,high,low,close,volume}`; `fetch_price` always `Failure(:no_entitlement)` |
| **Finnhub** | `MarketDataGateway` | ⚠️ chain only → **never recovers** [GW-01] | ✅ 5 sites | ✅ max 2 | ✅ | query `token` | 5s | `{symbol, price, volume(nil)}` |
| **CoinGecko** | `MarketDataGateway` | ✅ chain + direct `breaker_for("crypto")` | ✅ 3 sites | ✅ max 2 | ✅ | header `x-cg-demo/pro-api-key` | 5s | `{symbol, price, market_cap}` |
| **DataBursatil** | `MarketDataGateway` | ✅ chain + direct `breaker_for("databursatil")` | ❌ **none** [GW-03] | ✅ max 2 | ✅ | query `token` | 8s | `{symbol, source, price, volume, as_of}`; history `{date, close, amount}` |
| **Yahoo Finance** | `MarketDataGateway` | ⚠️ chain only → **never recovers**; `SyncMarketIndicesJob` builds a chain with **no** breakers | ✅ 1 site (`#run`) | ❌ n/a — subprocess, **no retry at all** | ✅ | none (public via yfinance) | 25s (PythonRunner) | `{symbol, price, change_percent, volume, as_of}` |
| **Alpha Vantage** | `FundamentalsGateway` | ✅ chain + direct `breaker_for("alpha_vantage")` | ✅ 3 sites | ✅ max 1 | ✅ | query `apikey` | 10s | overview: 33-key hash of `BigDecimal|nil`; statements `{symbol, annual_reports, quarterly_reports}` |
| **FMP** | `MarketDataGateway` ⚠️ (implements the fundamentals port) | ⚠️ chain only → **never recovers** | ✅ 3 sites | ✅ max 2 | ✅ | query `apikey` | 10s | overview: same 33 keys, **19 hardcoded `nil`** (`fmp_gateway.rb:97-121`) |
| **Banxico** | ❌ **none** (no `source_id`) | ❌ **none** — key declared, never used [GW-02] | ✅ 3 sites | ✅ max 2 | ❌ direct only | header `Bmx-Token` | 10s | `{term, yield_rate:Float, price:Float, auction_date}` / `{date, rate:Float}` — **Float, not BigDecimal** |
| **ExchangeRate** (`FxRatesGateway`) | ❌ **none** (no `source_id`) | ❌ **none** — key declared, never used [GW-02] | ✅ 1 site | ✅ max 2 | ❌ direct only | **key in URL path** [GW-15] | 5s | `Success(:rates_refreshed)` — writes `FxRate` rows itself |
| **Alternative.me** (`CryptoFearGreedGateway`) | ❌ **none** (no `source_id`) | ✅ direct `breaker_for("crypto_fear_greed")` | ❌ none (free, unauthenticated) | ✅ max 2, no `retry_statuses` | ❌ direct only | none | 5s | `{value:Integer, classification, fetched_at, component_data}` |

**Shape notes.** All money is `BigDecimal` (`.to_d` / `BigDecimal()`) **except Banxico**, which
returns `Float` for `yield_rate` and `price` (`banxico_gateway.rb:144`, `:150`, `:167`) — the one
gateway feeding fixed-income and FX. Keys are symbols everywhere; response bodies are strings
everywhere. `nil` vs `Failure` on missing data is inconsistent: Finnhub bulk returns
`Success([])` [GW-06], CoinGecko bulk returns `Success([])` for unknown symbols
(`coingecko_gateway.rb:79`), Alpaca and DataBursatil return `Failure(:not_found)`.

Three gateways (Banxico, ExchangeRate, Alternative.me) inherit from nothing and therefore have no
`source_id`. `GatewayChain#fetch_price:34` calls `gateway.source_id` unconditionally — latent
`NoMethodError` if any of the three is ever registered for a chained capability.

---

## Expert panel

**S2 — Adriana Cienfuegos (data engineer; gateways, rate limits, sync jobs):**
"The breaker that cannot close [GW-01] is the finding. Everything else here costs you a bad row or
an ugly diff; that one costs you a provider, silently, until someone redeploys — and for a
self-hosted box that runs untouched for a month, 'until redeploy' means 'forever'. Fix it before
you touch anything cosmetic. Second: DataBursatil is your only byte-metered source and your only
unmetered gateway [GW-03]. That is not an oversight you can leave in a product other people run on
their own 200,000 credits. And stop counting quota before the call [GW-08] — with `max: 2` retries
you are undercounting by up to 3× on exactly the free tiers where the ceiling is real."

**C3 — Sven Kowalski (Rails 8 / dry-rb):**
"Eight byte-identical `resolve_api_key` bodies and nine identical Faraday builders is not a style
complaint — you already wrote the fix twice. `AlpacaGateway#get` and `DataBursatilGateway#get`
are the correct shape, and those two gateways have one rescue site each while Finnhub has six.
Promote that method into `MarketDataGateway`, which today is 28 lines of `NotImplementedError`
earning nothing. And `backfill_price_history_job.rb:73` — introspecting `Method#parameters` to
decide how to call your own port — is the code telling you the port has two signatures. Fix the
port, delete the reflection. On `GatewayChain`: the file's own comment admits the five loops are
the generic one; two of the five stamp nothing at all, so the stated reason does not even cover
them."

**C7 — Fadia Haddad (security):**
"Secrets are in good shape and I want that on the record: no hardcoded credentials anywhere in
`app/`, `lib/` or `config/`, single resolution path through `ApiKeyResolver` onto an encrypted
column, no key in any log or error message, every gateway with both timeouts set. My concern is
durability, not the current state. The ExchangeRate key rides in the URL path
(`fx_rates_gateway.rb:23`) and four more ride in query strings — provider-mandated, so leave the
calls alone — but there is no redaction layer, and `RecordUnhandledError` persists raw exception
messages to a screen a browser renders. When you extract the shared `connection` builder [GW-05],
put URL redaction in it. That way the safety is structural instead of a property of nobody having
added a logger yet."

---

## Overall verdict

The design is better than its execution. `GatewayFailure`'s permanent/transient vocabulary,
`DataSourceRegistry`'s capability routing, `CircuitBreaker`'s permanent-failure branch and
`PythonRunner`'s argv-plus-timeout containment are all deliberate answers to real incidents, and
the comments explaining them are unusually honest. Neither shared object is over-engineered *in
concept*: the breaker earns its 127 lines, and a fallback chain across ten providers is exactly
what this app needs. `GatewayChain`'s 222 lines are not sophistication though — half of them are
one loop written five times, and that duplication is where the P0 hides.

The consistent failure mode is **uneven application**: a protection is invented, applied to seven
gateways, and quietly skipped by the two or three where it matters most. Fixing [GW-01] through
[GW-05] is roughly a day and removes the entire class.
