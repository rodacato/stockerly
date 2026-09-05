# Stockerly — Quality Metrics & Test Suite Audit

**Scope:** objective tooling numbers (Part A) + test-suite quality (Part B).
**Run date:** 2026-08-30 (UTC), commit `5cacab14040cc5c0e6e03fab86ea105321263fb7`, branch `fix/capture-daily-volume`.
**Mode:** read-only. No repo file was created, modified or deleted. Only `coverage/` (gitignored) was regenerated — see the note under "Measured numbers".

---

## Measured numbers

### RubyCritic — `bin/quality app lib`

Ran clean. RubyCritic (flog + reek + flay + churn), 379 modules analysed.

```
Score: 84.71
```

| Rating | Modules |
|---|---|
| A | 263 |
| B | 59 |
| C | 40 |
| **D** | **8** |
| **F** | **9** |

**The 17 D/F modules:**

| Module | Rating | Churn | Complexity | Duplication | Smells |
|---|---|---|---|---|---|
| TrendScoreCalculator | D | 9 | 334.14 | 0 | 20 |
| AlpacaGateway | F | 10 | 280.24 | 72 | 37 |
| ImportTrades | D | 7 | 269.02 | 0 | 31 |
| FinnhubGateway | F | 8 | 268.97 | 158 | 37 |
| FundamentalCalculator | F | 2 | 264.44 | 192 | 10 |
| AlphaVantageGateway | F | 13 | 239.40 | 97 | 29 |
| CoingeckoGateway | F | 11 | 204.61 | 52 | 28 |
| TradesController | D | 15 | 201.73 | 94 | 16 |
| DataBursatilGateway | F | 8 | 177.56 | 70 | 23 |
| FmpGateway | F | 10 | 173.75 | 281 | 26 |
| BanxicoGateway | F | 12 | 160.39 | 29 | 11 |
| MarketHelper | D | 16 | 158.03 | 46 | 24 |
| AlertsController | D | 11 | 134.02 | 64 | 6 |
| AssetsController | D | 9 | 130.81 | 88 | 7 |
| UpdateTrade | D | 3 | 83.17 | 41 | 7 |
| LogsHelper (Admin::) | D | 3 | 77.98 | 81 | 7 |
| FxRatesGateway | F | 8 | 43.43 | 70 | 5 |

**Churn/complexity hotspots (top 8 by churn):**

| Module | Rating | Churn | Complexity |
|---|---|---|---|
| MarketController | B | 35 | 79.70 |
| SyncSingleAssetJob | C | 21 | 131.29 |
| LoadAssetDetail | C | 21 | 130.72 |
| ProfilesController | C | 19 | 102.71 |
| DashboardController | A | 18 | 13.60 |
| MarketHelper | **D** | 16 | 158.03 |
| SessionsController | C | 16 | 71.71 |
| TradesController | **D** | 15 | 201.73 |

`MarketHelper` and `TradesController` are the only files in the top-8 churn list that are also D-rated — high change rate on top of high complexity.

**Duplication:** 56 distinct duplicate-code groups repo-wide. 9 of them span two or more gateway files; the largest is an **8-node identical block across every keyed gateway**.

**Highest smell counts (not D/F):** `GatewayChain` C, 45 smells, complexity 189.19.

### RuboCop — `bin/rubocop --format offenses`

```
973 files inspected, no offenses detected
```

RuboCop 1.88.0. **There is no `.rubocop_todo.yml`** (verified: `ls -a | grep -i rubocop` returns only `.rubocop.yml`) — so no offenses are suppressed there. `.rubocop.yml` is 8 lines: `inherit_gem: { rubocop-rails-omakase: rubocop.yml }` plus commented examples, no house rules.

**However:** `rubocop --show-cops` reports **791 cops available, 45 enabled, 751 disabled**. Omakase is a formatter-only ruleset. "0 offenses" measures whitespace and string quoting, not `Metrics/*`, `Rails/*` correctness cops, `Lint/*`, or `Style/*`. See QA-04.

### Brakeman — `bin/brakeman --no-pager`

```
Brakeman 8.0.6 | Rails 8.1.3.1 | Scan Date: 2026-08-30 03:57:10 +0000 | Duration: 2.13s
Checks Run: 79
Controllers: 34 | Models: 38 | Templates: 144 | Errors: 0
Security Warnings: 0
No warnings found
```

Zero warnings at any confidence level. No `brakeman.ignore` file exists, so nothing is being silently waived.

### bundler-audit — `bin/bundler-audit`

```
No vulnerabilities found
```

`config/bundler-audit.yml` ignore list contains only the placeholder `CVE-THAT-DOES-NOT-APPLY` — nothing real is waived.

### i18n-tasks — `bundle exec i18n-tasks health`

```
es-MX has 959 keys. ✓ no missing ✓ no unused ✓ no inconsistent interpolations
✓ no reserved interpolations ✓ all data normalized
```

### RSpec

`bundle exec rspec --dry-run`:

```
3069 examples, 0 failures
Finished in 0.14296 seconds (files took 2.48 seconds to load)
```

All 408 spec files load with zero errors — **no spec references a deleted constant** (a dead spec would raise at load time).

`bundle exec rspec` (full suite, run to restore the coverage artifact — see note):

```
3069 examples, 0 failures
Finished in 1 minute 53.78 seconds (files took 2.6 seconds to load)
Line coverage:   7630 / 7963 (95.81%)
Branch coverage: 2225 / 2769 (80.35%)
```

- 383 tracked files; **279 at 100% line coverage**.
- 408 spec files vs 377 `app/*.rb` files.
- Documented count in `CLAUDE.md` and `CONTRIBUTING.md` is **3,007** — stale by 62 (QA-13).
- Coverage matches `coverage/.last_run.json` as it stood before this audit (95.81 / 80.35) exactly.

> **Disclosure — coverage artifact.** `bundle exec rspec --dry-run` **regenerated `coverage/coverage.json` and `coverage/.last_run.json`** with meaningless load-time-only figures (36.35% line / 0.00% branch). SimpleCov starts and writes its report even in dry-run mode. I restored the artifact by running the full suite. The first restore attempt failed environmentally — 245 examples in the first 39 spec files raised `ActiveRecord::ConnectionNotEstablished` / `PG::ConnectionBad` ("Cannot assign requested address" to postgres at 172.18.0.2:5432) because I was running heavy tooling concurrently; those were **not code failures**. The second, isolated run is the one reported above and is clean. `coverage/` is gitignored (`.gitignore:46`), so no tracked file changed. The dry-run clobbering is itself a finding — QA-09.

### Dead dependencies — verified

**None found.** Every gem in the `Gemfile` has a verified consumer. The ones that look dead by name-grep but are not:

| Gem | Verified use |
|---|---|
| `dry-struct` / `dry-types` | `Dry::Struct` in `app/shared/events/base_event.rb`; `Dry::Types` in `app/shared/types/types.rb` |
| `faraday-retry` | `f.request :retry, RetryPolicy.options(...)` in 8 gateways |
| `mission_control-jobs` | `config/routes.rb:140` mounts the engine; `config/initializers/mission_control.rb` |
| `stimulus-rails` | `config/importmap.rb:5-6`, `app/javascript/controllers/*.js` |
| `tailwindcss-rails` | `Procfile.dev:2` (`bin/rails tailwindcss:watch`) |
| `yabeda-*` | `config/initializers/yabeda.rb`, `config/puma.rb`, `lib/middleware/metrics_endpoint.rb` |
| `solid_cache` / `solid_cable` | `config/environments/production.rb:64`, `config/cable.yml` |
| `rqrcode` | `app/helpers/totp_helper.rb:5` |
| `web-push` | `app/contexts/notifications/domain/web_push_delivery.rb` |
| `dotenv-rails` | No explicit reference — loads via railtie by design; `.env` is documented in `GETTING_STARTED.md` |

---

## Findings

### [QA-01] Real brokerage data sits un-gitignored in the repo root
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `/workspaces/stockerly/alpaca-trades.csv` (verified untracked), `/workspaces/stockerly/.gitignore` (verified: no `*.csv`, no `.DS_Store`)
- **Evidence:**
  ```
  $ git check-ignore -v alpaca-trades.csv .DS_Store
  NOT IGNORED
  $ head -2 alpaca-trades.csv
  asset_symbol,side,shares,price_per_share,fee,currency,executed_at,external_id,gross_amount,net_amount,settle_date,cusip,source_file
  VT,buy,0.070436076,141.972700,0.0,USD,2025-12-08T06:57:37-05:00,23d9d4e1-…,-10.00,-10.00,2025-12-09,922042742,64cd9bcb-….pdf
  ```
  50 rows: real symbols, real execution timestamps, real CUSIPs, real Alpaca execution UUIDs, real amounts, and the source statement PDF filenames.
- **Why it matters:** this is a **public open-source repo**. One `git add -A` (or `git add .` in the root) commits Adrian's personal brokerage history permanently into a public history. `bin/pre-commit` will not catch it — its `PATTERNS` array matches key/token/password strings, not a CSV of trades. `.gitignore` already anticipates exactly this class of risk elsewhere ("Pencil design system: device captures with real user data — local only"), so the omission is an oversight, not a decision.
- **Recommendation:** add `*.csv` (with a `!` exception for any fixture CSV the repo genuinely needs) and `.DS_Store` to `.gitignore`, and move the file to `.local/`. Optionally add a `cusip|executed_at.*external_id` header pattern to `bin/pre-commit`.

### [QA-02] The suite has never run in random order — the whole RSpec config block is commented out
- **Severity:** P1
- **Effort:** S (<1h)
- **Where:** `spec/spec_helper.rb:49` (`=begin`) through `spec/spec_helper.rb:93` (`=end`); `config.order = :random` is at line 86, inside the block
- **Evidence:**
  ```
  $ grep -n "=begin\|=end\|config.order\|profile_examples\|example_status_persistence\|disable_monkey_patching" spec/spec_helper.rb
  49:=begin
  60:  config.example_status_persistence_file_path = "spec/examples.txt"
  65:  config.disable_monkey_patching!
  80:  config.profile_examples = 10
  86:  config.order = :random
  93:=end
  ```
  Nothing re-enables it: `.rspec` contains only `--require spec_helper`, and no CI workflow passes `--order` or `--seed` (`ci.yml:66`, `deploy.yml:80`, `quality.yml:64` all run a bare `bundle exec rspec`).
- **Why it matters:** 3,069 examples run in the same defined (file-glob) order on every machine and in CI, forever. Order dependencies are structurally invisible. This is not theoretical here — `spec/support/data_source_registry_isolation.rb` documents a real one that was only found because someone happened to run `--seed 111`:
  > *"Under `--seed 111` four unrelated specs then failed with `NotImplementedError` raised from inside GatewayChain, which reads like a routing bug and is not one."*

  That leak was fixed. The next one will not be found, because nothing randomizes by default. The suite also has 348 `let!` declarations and 47 `travel_to` calls — both classic sources of cross-example bleed.
- **Recommendation:** uncomment `config.order = :random` and `Kernel.srand config.seed` (lines 86 and 92). Run it a few times, fix what falls out, then leave it on. Expect breakage on the first pass — that is the point.

### [QA-03] `lib/tasks/import.rake` is the one rake file with no spec, and it is the destructive one
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `lib/tasks/import.rake` (whole file, 56 lines) — no corresponding `spec/tasks/import_spec.rb`
- **Evidence:** measured coverage from the clean run:
  ```
  lib/tasks/import.rake    30.3% line (23 of 33 uncovered)    0.0% branch (0 of 17 hit)
  ```
  Every other rake file has a spec — `spec/tasks/` holds `data_backfill_spec.rb`, `fx_rate_backfill_spec.rb`, `reset_password_spec.rb`, `resolve_bmv_symbols_spec.rb`, `sync_rake_spec.rb`. `import.rake` is the gap. Its contents:
  ```ruby
  task :import_trades, [ :path ] => :environment do |_t, args|
    rows = ImportTradesCli.read(args[:path])
    dry_run = ENV["COMMIT"] != "1"
    ...
  task :undo_import, [ :path ] => :environment do |_t, args|
    ids = ImportTradesCli.read(args[:path]).filter_map { |row| row[:external_id].presence }
    abort "No external_id column in #{args[:path]} — nothing to undo by." if ids.empty?
    result = Trading::UseCases::UndoImport.call(portfolio: ImportTradesCli.user.portfolio, external_ids: ids)
  ```
- **Why it matters:** 0 of 17 branches means **none of the guards has ever executed in a test**: the `path.blank?` abort, the `File.exist?` abort, the `MissingHeader` rescue, the `User.first or abort`, the `Success`/`Failure` dispatch, and — critically — `dry_run = ENV["COMMIT"] != "1"`. If that comparison inverts, a dry run writes trades. And `undo_import` **deletes trades and rebuilds snapshots** with its only guard (`ids.empty?`) untested. The underlying `ImportTrades` (208-line spec) and `UndoImport` (66-line spec) use cases *are* tested; the CLI wrapper that decides whether to commit is not. This is also precisely the path `alpaca-trades.csv` (QA-01) feeds.
- **Recommendation:** add `spec/tasks/import_spec.rb` following the existing `spec/tasks/sync_rake_spec.rb` pattern (`Rails.application.load_tasks`, `Rake::Task[...].reenable`). Minimum four examples: dry run writes nothing; `COMMIT=1` writes; a CSV missing `external_id` aborts `undo_import` without deleting; a missing file aborts before touching the DB.

### [QA-04] "0 RuboCop offenses" measures 45 of 791 cops
- **Severity:** P1
- **Effort:** M (1-4h)
- **Where:** `.rubocop.yml` (8 lines, `inherit_gem: rubocop-rails-omakase`)
- **Evidence:**
  ```
  $ bundle exec rubocop --show-cops | grep -c "^  Enabled: true"   →  45
  $ bundle exec rubocop --show-cops | grep -c "^  Enabled: false"  → 751
  ```
- **Why it matters:** there is no `.rubocop_todo.yml`, so the honest read is *not* "no hidden debt" — it is "the ruleset was never asked the questions whose answers would be debt". Omakase deliberately disables `Metrics/*`, most `Lint/*`, and the `Rails/*` correctness cops. That is why RuboCop reports a perfectly clean repo while RubyCritic independently finds 9 F-rated files, `TrendScoreCalculator#macd_signal` at flog 49, and `AssetsController` with 17 instance variables. Two tools, one codebase, opposite verdicts — because one of them is only looking at formatting. Reporting "rubocop: clean" as a quality signal in a PR gate is misleading.
- **Recommendation:** keep omakase as the base (it is the right call for formatting), and add a small, opinionated layer on top of the cops RubyCritic is already flagging by hand: `Metrics/AbcSize`, `Metrics/MethodLength`, `Metrics/ClassLength`, `Rails/OutputSafety`, `Rails/SkipsModelValidations`, `Lint/DuplicateBranch`. Set `Max:` to just above the current worst value per cop so the repo stays green on day one, then ratchet. That is a real todo file with a purpose, unlike an auto-generated one.

### [QA-05] Eight gateways are F-rated on the same copy-pasted block, while their base class sits nearly empty
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/contexts/market_data/gateways/alpaca_gateway.rb:251`, `alpha_vantage_gateway.rb:207`, `banxico_gateway.rb:82`, `coingecko_gateway.rb:208`, `data_bursatil_gateway.rb:184`, `finnhub_gateway.rb:239`, `fmp_gateway.rb:172`, `fx_rates_gateway.rb:63` — all verified
- **Evidence:** RubyCritic reports one duplicate-code group spanning all eight. The block is byte-identical:
  ```ruby
  def resolve_api_key
    key = ApiKeyResolver.for(PROVIDER)
    raise ApiKeyNotConfiguredError.new(PROVIDER) if key.blank?
    key
  rescue ActiveRecord::Encryption::Errors::Decryption
    raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "decryption failed")
  end
  ```
  Meanwhile `app/contexts/market_data/gateways/market_data_gateway.rb` (the base class, 26 lines) declares only `source_id`, `fetch_price` and `fetch_bulk_prices`. A second group of 4 duplicates the Faraday `connection` builder across `data_bursatil`, `finnhub`, `fmp`, `fx_rates`.
- **Why it matters:** this is why 8 of the 9 F ratings are gateways. It is a **security-relevant** method — decryption failure handling for stored API keys — duplicated eight times. Changing how a decryption failure is reported means finding and editing eight files, and missing one leaves a gateway that raises a raw `ActiveRecord::Encryption::Errors::Decryption` out of a sync job instead of the domain error. `FmpGateway` alone carries a duplication mass of 281.
- **Recommendation:** move `resolve_api_key` to `MarketDataGateway` (it already reads `PROVIDER` via `const_get`, so the pattern is established) and extract the shared Faraday builder into a `build_connection(url:, timeout:, **)` helper there. This one change should retire most of the 8 F ratings without touching provider-specific parse logic.

### [QA-06] `MarketHelper` is the worst churn × complexity × coverage intersection in the repo
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/helpers/market_helper.rb` (252 lines) — smells at `:107`, `:141`, `:169`, `:181`, `:185`, `:197`, `:243`, `:247`, `:248`, `:249`
- **Evidence:** three independent signals converge on this one file:
  - RubyCritic: **D**, churn **16** (2nd-highest in the repo), complexity 158.03, duplication 46, **24 smells**
  - Coverage: **78.5% line** (20 uncovered of 93) and **58.5% branch — 27 of 65 branches never executed**, the largest absolute branch gap in `app/`
  - Reek: `asset_detail_tabs` is a ControlParameter on three separate boolean arguments (`has_fundamentals`, `has_dividends`, `has_statements`); `short_date_es` and `short_date_upper_es` both take a `BooleanParameter include_year`
- **Why it matters:** it changes constantly (churn 16), it is branch-dense, and **41% of its branches have never run**. It renders the asset-detail screen — the surface the 2.0 redesign is actively rewriting. Every edit here is an edit to untested conditional logic in the highest-traffic view helper.
- **Recommendation:** before the next redesign slice touches it, cover the 27 unhit branches (`spec/helpers/market_helper_spec.rb` and `market_helper_source_caption_spec.rb` already exist — extend them). Then split `asset_detail_tabs` to take a single tab-availability object instead of three booleans, which kills three ControlParameter smells and most of the branch surface at once.

### [QA-07] `TrendScoreCalculator` is the single most complex file in the repo
- **Severity:** P2
- **Effort:** L (>4h)
- **Where:** `app/contexts/market_data/domain/trend_score_calculator.rb` — hot methods at `:19` (`calculate`, flog 38), `:44` (`rsi_14`, flog 49), `:71` (`compute_ema_series`, flog 27), `:86` (`macd_signal`, flog 49), `:112` (`volume_trend`, flog 44), `:127` (`ema_crossover`, flog 40), `:146` (`blend_5_factor`, flog 45)
- **Evidence:** RubyCritic: **D**, complexity **334.14** (highest of 379 modules), 20 smells, churn 9. Coverage is decent — 84.1% branch (10 of 63 unhit) — and the spec is 192 lines against a 182-line source.
- **Why it matters:** 182 lines carrying 334 complexity means seven separate indicator algorithms (RSI, MACD, EMA, volume trend, crossover, blend) live as private class methods in one namespace. Each is independently testable maths, but the current shape forces every test to go through `calculate`. Note the file it duplicates nothing with — this is pure complexity, not copy-paste. It is also adjacent to `TechnicalIndicators` (C, complexity 136.82), which does similar work.
- **Recommendation:** not urgent — it is tested and it works. But the next time it is touched, extract each indicator into its own small object under `MarketData::Domain::Indicators::` with its own spec. Do not do this speculatively; do it on the next real change to the scoring logic.

### [QA-08] Three specs stub the object under test's own internals
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `spec/jobs/calculate_trend_scores_job_spec.rb:24`, `spec/jobs/resolve_tracked_symbols_job_spec.rb:46-47`, `spec/jobs/sync_index_history_job_spec.rb:10` and `:47`
- **Evidence:**
  ```ruby
  # calculate_trend_scores_job_spec.rb:23-26
  it "logs sync success with count" do
    expect_any_instance_of(described_class).to receive(:log_sync_success).with("TrendScores: 1 assets scored")
    described_class.perform_now
  end
  ```
  ```ruby
  # resolve_tracked_symbols_job_spec.rb:46-47
  expect(described_class).to receive(:set).with(wait: described_class::RETRY_IN).and_return(described_class)
  expect(described_class).to receive(:perform_later).with([ "ALAB" ], user.id, [], [])
  ```
  ```ruby
  # sync_index_history_job_spec.rb:10
  allow_any_instance_of(MarketData::Gateways::YfinanceGateway).to receive(:fetch_historical).and_return(...)
  ```
- **Why it matters:** all three assert choreography instead of outcome, and all three **suppress the real call**.
  - The first stubs the job's own `log_sync_success`, so it proves a method was called with a string — not that a `SystemLog` row was written. The `SyncLogging` concern it belongs to has its own spec, so this example adds a coupling to a private method name and nothing else.
  - The second stubs `set`/`perform_later` on the class under test, so the re-enqueue is never actually enqueued. `have_enqueued_job(described_class).with(...)` asserts the same intent against the real ActiveJob test adapter.
  - The third bypasses the project's own `stub_yfinance_*` helpers (`spec/support/webmock_helpers.rb:684-734`), so the gateway's parse layer is skipped rather than exercised.
- **Recommendation:** replace with outcome assertions — `expect { described_class.perform_now }.to change(SystemLog, :count)` with a message match; `have_enqueued_job`; and the existing `stub_yfinance_*` helper (adding a `stub_yfinance_historical` if one does not fit).

  **Context, in fairness:** the suite is otherwise remarkably mock-light — **228 mock/stub lines across 408 spec files**, and only one file above 15 (`spec/shared/domain/gateway_chain_spec.rb`, 59 lines, where mocking collaborator gateways *is* the contract under test). `spec/contexts/notifications/domain/web_push_delivery_spec.rb` is a model of the house style: it stubs `WebPush.payload_send` and `ENV` and nothing else, then asserts on real `PushSubscription` rows. The gateway specs use WebMock against the real gateway object and assert both parsed output and request shape. These three are outliers, not a pattern.

### [QA-09] `rspec --dry-run` silently overwrites the coverage report — and it is the documented command
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `spec/rails_helper.rb:11` (`SimpleCov.start 'rails' do`) — no dry-run guard; `CLAUDE.md:234` documents `bundle exec rspec --dry-run` as the way to count examples
- **Evidence:** measured directly during this audit. Before:
  ```json
  { "result": { "line": 95.81, "branch": 80.35 } }
  ```
  After a single `bundle exec rspec --dry-run`:
  ```json
  { "result": { "line": 36.35, "branch": 0.0 } }
  ```
  with `coverage/coverage.json` rewritten to match.
- **Why it matters:** `sonar-project.properties` points `sonar.ruby.coverage.reportPaths` at `coverage/coverage.json`. Anyone who runs the documented example-count command and then triggers a local Sonar scan ships 36% line / 0% branch. CI is safe today only because `quality.yml:64` runs the full `bundle exec rspec` before the scan — a coincidence of ordering, not a guard. The failure is silent: the dry run prints the bogus number in its own output and nobody reads it as a warning.
- **Recommendation:** guard the SimpleCov start:
  ```ruby
  SimpleCov.start 'rails' do
    ...
  end unless ARGV.include?("--dry-run")
  ```
  Cheaper alternative: change the documented command in `CLAUDE.md` and `CONTRIBUTING.md` to `bundle exec rspec --dry-run --no-color 2>/dev/null` — but that still clobbers the file. Guard it.

### [QA-10] The same commented block also disables `--only-failures` and slow-spec profiling
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `spec/spec_helper.rb:55, 60, 65, 80` — all inside the `=begin`/`=end` block from QA-02
- **Evidence:**
  ```
  55:  config.filter_run_when_matching :focus
  60:  config.example_status_persistence_file_path = "spec/examples.txt"
  65:  config.disable_monkey_patching!
  80:  config.profile_examples = 10
  ```
- **Why it matters:** distinct from QA-02 because the fix is the same edit but the cost is developer-loop friction rather than correctness. Without `example_status_persistence_file_path`, `rspec --only-failures` and `--next-failure` do not work — after a red run you re-run the whole 1m54s suite or copy-paste paths by hand. Without `profile_examples`, there is no data on which examples are slow, so the suite's runtime can only be diagnosed by bisection. Both are one-line enables the Rails generator ships commented and nobody uncommented.
- **Recommendation:** uncomment lines 55, 60, 65 and 80 alongside the QA-02 fix. Add `/spec/examples.txt` to `.gitignore` in the same change.

### [QA-11] The `trade` factory carries a dead `total_amount` and omits `fx_rate_at_execution`
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `spec/factories/trades.rb`
- **Evidence:**
  ```ruby
  factory :trade do
    portfolio; asset
    side { :buy }
    shares { 10.0 }
    price_per_share { 150.0 }
    total_amount { 1_500.0 }     # never survives create
    currency { "USD" }
    executed_at { Time.current }
  end                             # no fx_rate_at_execution
  ```
  `app/models/trade.rb:12` runs `before_validation :calculate_total_amount, on: :create`, which sets `shares * price_per_share`. 18 call sites pass `shares:`/`price_per_share:` without `total_amount:`.
- **Why it matters:** two separate small problems.
  - `total_amount { 1_500.0 }` is dead on `create` (overwritten) but **live on `build`**, so a `build(:trade, shares: 5, price_per_share: 10)` carries a `total_amount` of 1500 rather than 50. It reads as authoritative and is not.
  - The missing `fx_rate_at_execution` is the more interesting one. NULL is a legitimate production state (documented at `execute_trade.rb:36-40` — a fresh instance whose FX history has not synced yet), but `ExecuteTrade` normally *does* store a rate. So the factory's default is the exceptional state, and `Trading::Domain::ExecutionRate.multiplier` raises `MissingFxRate` on it (`execution_rate.rb:26`). Every currency-conversion spec therefore has to remember to set the rate, and the happy path is opt-in while the fail-loud path is the default. That is inverted for a codebase whose central invariant is currency correctness.
- **Recommendation:** drop `total_amount` from the factory (the model computes it). Add `fx_rate_at_execution { 17.0 }` as the default and a `trait :fx_unknown do fx_rate_at_execution { nil } end` for the backfill-pending case. Then the default record matches what production writes, and the exceptional case is named at the call site where it is actually being tested.

### [QA-12] The admin helpers are the least-tested branch surface in `app/`
- **Severity:** P2
- **Effort:** M (1-4h)
- **Where:** `app/helpers/admin/settings_helper.rb`, `app/helpers/admin/logs_helper.rb`, `app/helpers/admin/integrations_helper.rb`, `app/helpers/alerts_helper.rb`
- **Evidence:** measured branch coverage, clean run:
  ```
  app/helpers/admin/settings_helper.rb        21.4% branch (11 of 14 unhit)   61.5% line
  app/helpers/admin/logs_helper.rb            31.2% branch (11 of 16 unhit)   68.2% line
  app/helpers/admin/integrations_helper.rb    42.9% branch ( 8 of 14 unhit)   88.9% line
  app/helpers/alerts_helper.rb                56.2% branch (14 of 32 unhit)   79.4% line
  ```
  None of the three `admin/` helpers has a spec file (`spec/helpers/` contains no `admin/` directory). `Admin::LogsHelper` is separately **D-rated** (duplication 81) with duplicate blocks shared across `admin/errors_helper.rb:3`, `admin/logs_helper.rb:3`, `admin/errors_helper.rb:15`, `admin/logs_helper.rb:53`, `admin/settings_helper.rb:29`.
- **Why it matters:** these render `/admin/logs`, `/admin/settings` and `/admin/integrations` — the screens a self-hoster hits when something is already broken. A nil-handling bug in `admin_logs_filter_active?` (which Reek flags for both FeatureEnvy and a NilCheck at `logs_helper.rb:78`) surfaces as a 500 on the diagnostics page. The duplication across the three helpers means the same untested formatting logic exists in triplicate.
- **Recommendation:** add `spec/helpers/admin/logs_helper_spec.rb` and `settings_helper_spec.rb` covering the filter and label branches, then extract the three duplicated blocks into a shared `Admin::FormattingHelper`. The extraction is only safe once the tests exist — do them in that order.

### [QA-13] The documented example count is 62 short
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `CLAUDE.md:234`, `CONTRIBUTING.md:42`
- **Evidence:**
  ```
  CLAUDE.md:234      **3,007 examples** (`bundle exec rspec --dry-run`, measured 2026-08-29).
  CONTRIBUTING.md:42 bundle exec rspec    # Full suite (3,007 examples as of 2026-08-29)
  ```
  Measured today: **3,069 examples**. `CLAUDE.md:234` also quotes coverage "last measured 2026-08-27" as 95.33% line / 79.27% branch; the current figures are 95.81% / 80.35%.
- **Why it matters:** minor on its own, but `CLAUDE.md` explicitly instructs "re-measure rather than quoting this figure once it ages" and it has already aged in one day. Both numbers are the kind that get quoted into a PR description as evidence.
- **Recommendation:** update both to 3,069 / 95.81% / 80.35% (dated 2026-08-30). Better: stop hardcoding it — the instruction to re-measure is the useful half.

### [QA-14] Two small drift artifacts from the pre-2.0 era
- **Severity:** P2
- **Effort:** S (<1h)
- **Where:** `spec/factories/audit_logs.rb`, `spec/integration/phase7_events_spec.rb`
- **Evidence:**
  ```ruby
  # spec/factories/audit_logs.rb
  factory :audit_log do
    user
    action { "admin.users.suspend" }   # the multi-user surface this names was deleted in the 2.0 cleanup
    ip_address { "127.0.0.1" }
  end
  ```
  `spec/integration/phase7_events_spec.rb` — "phase7" refers to the pre-2.0 phase-numbered planning scheme that ADR-0010 and the sprint protocol replaced.
- **Why it matters:** neither breaks anything. Both are the kind of stale name that makes a reader go looking for a feature that no longer exists — `admin.users.suspend` in particular reads as evidence that user suspension is still a thing. `CLAUDE.md` is explicit that the multi-user surface was "deleted in place".
- **Recommendation:** change the factory default to a surviving action (`admin.integrations.connect`) and rename the spec to what it actually tests (`event_bus_wiring_spec.rb` — though note `spec/integration/event_subscription_wiring_spec.rb` already exists, so check for overlap before renaming rather than after).

---

## What is genuinely good — stated plainly

The audit found less than I expected to, and the reasons are worth recording so nobody "fixes" them:

- **Zero security findings** across Brakeman (79 checks, 0 warnings, no ignore file) and bundler-audit (no waivers). No dead gems.
- **Suite runs in 1m54s for 3,069 examples.** That is fast enough that the missing `--only-failures` (QA-10) is an annoyance rather than a blocker.
- **Mock discipline is real, not claimed.** 228 mock lines across 408 files. The gateway specs stub HTTP at the WebMock boundary and assert on both parsed output and outgoing request shape. `web_push_delivery_spec.rb` stubs exactly two things it does not own and asserts on real records.
- **Test isolation is engineered, not accidental.** `spec/support/webmock.rb` disables net connect; `spec/support/no_subprocess_network.rb` closes the hole WebMock cannot see (the Python yfinance bridge shells out and would call Yahoo for real from CI) with a raising stub and a `:real_subprocess` opt-out; `spec/support/data_source_registry_isolation.rb` snapshots and restores global registry state. Each carries a comment explaining the specific incident that produced it.
- **`EventBus.clear!` is confirmed** at `spec/rails_helper.rb` in `config.before(:each)`, alongside `GatewayChain.reset_breakers!` and `SiteConfig` resets — CLAUDE.md's claim is accurate.
- **Zero `sleep` calls in `spec/`.** Bullet is enabled with `Bullet.raise = true`, and there is a purpose-built `make_queries` matcher for N+1 regressions.
- **Factories are shallow and trait-based.** No object-graph explosions, sequences everywhere uniqueness matters, and the two issues found (QA-11) are small.
- **No dead specs.** All 408 spec files load clean, so nothing describes a deleted constant.

---

## Expert panel

**S8 Mehmet Karadeniz — QA / Testing (RSpec, factories, system specs)**

> Your mock hygiene is better than most paid teams I audit — 228 stub lines across 408 files, and the ones that exist are at boundaries you genuinely do not own. I would not spend an hour on QA-08; three outliers is noise, fix them when you are next in those files.
>
> QA-02 is the one that keeps me up. You have 3,069 examples, 348 `let!`, 47 `travel_to`, and a support file that documents a real order-dependency someone found *by accident* with `--seed 111`. You fixed that one leak. You have no mechanism to find the next. A suite that has never been shuffled is not a suite that has no order dependencies — it is a suite whose order dependencies have not been asked about yet.
>
> On QA-11: inverting that factory default is the highest ratio of correctness-per-keystroke in this whole report. Right now your default trade is in the *exceptional* state and every currency spec opts into the normal one. For a codebase whose entire thesis is "the number shown to the user must be true", that default is backwards.

**S7 Soo-ah Park — Developer Experience (dev loop, tests, flakiness)**

> 1m54s for 3,069 examples is a good loop. Do not let anyone tell you the suite is slow — it isn't, and you have no data saying which examples are, because `profile_examples` is commented out along with everything else in that block.
>
> QA-09 is my favourite finding here and it is the kind nobody catches: your own `CLAUDE.md` tells a developer to run `--dry-run` to count examples, and that command silently rewrites the artifact Sonar reads. It fails quietly, it fails in the direction of looking worse than you are, and CI only escapes it because `quality.yml` happens to run the real suite first. That is luck, not design. Four words — `unless ARGV.include?("--dry-run")` — and it is closed forever.
>
> Lines 49 to 93 of `spec_helper.rb` are the single cheapest change in this report: one block comment removal buys you random ordering, `--only-failures`, and slow-spec profiling. It has been sitting there since `rails generate rspec:install`.

**C3 Sven Kowalski — Rails 8 Backend (AR, dry-rb, contracts, Use Cases)**

> QA-04 is the finding I would put in front of Adrian first, because it reframes the other numbers. "RuboCop: 0 offenses across 973 files" reads like a clean bill of health and it is 45 cops out of 791 — formatting. RubyCritic independently finds nine F-rated files in the same tree. Both tools are honest; only one of them was asked a hard question.
>
> QA-05 is where I would actually spend the afternoon. `resolve_api_key` copy-pasted into eight adapters, with `MarketDataGateway` sitting right there declaring three methods — that base class already does `const_get(:PROVIDER)`, so the seam is built and unused. It is not an abstraction I am inventing to look clever; it is the one the code already reaches for and then declines to use. Eight identical copies of a decryption-failure rescue is one missed edit away from a raw `ActiveRecord::Encryption::Errors::Decryption` escaping a sync job.
>
> On QA-07 — leave `TrendScoreCalculator` alone. 334 complexity, yes, and also 84% branch coverage and a spec longer than the source. Refactoring tested working maths because a tool printed a D is exactly the ceremony this project's own anti-pattern list warns about. Touch it when the scoring logic changes, not before.

---

## Ranked summary

| ID | Severity | Effort | Finding |
|---|---|---|---|
| QA-01 | P1 | S | Real brokerage CSV un-gitignored in a public repo root |
| QA-02 | P1 | S | `config.order = :random` commented out — suite never shuffled |
| QA-03 | P1 | M | `lib/tasks/import.rake`: 0% branch, no spec, destructive `undo_import` |
| QA-04 | P1 | M | RuboCop "0 offenses" = 45 of 791 cops enabled |
| QA-05 | P2 | M | `resolve_api_key` duplicated across 8 gateways; base class unused |
| QA-06 | P2 | M | `MarketHelper`: D-rated, churn 16, 58.5% branch |
| QA-07 | P2 | L | `TrendScoreCalculator` complexity 334 (highest in repo) — defer |
| QA-08 | P2 | S | 3 specs stub the SUT's own internals |
| QA-09 | P2 | S | `rspec --dry-run` clobbers `coverage/coverage.json` |
| QA-10 | P2 | S | `--only-failures` and `profile_examples` disabled in the same block |
| QA-11 | P2 | S | `trade` factory: dead `total_amount`, inverted FX default |
| QA-12 | P2 | M | Admin helpers: 21–43% branch coverage, no specs, D-rated duplication |
| QA-13 | P2 | S | Documented example count stale (3,007 vs 3,069) |
| QA-14 | P2 | S | Pre-2.0 drift in `audit_log` factory and `phase7_events_spec.rb` |
