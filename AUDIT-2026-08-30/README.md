# Stockerly — Maintainability Audit

**Date:** 2026-08-30 · **Commit:** `5cacab1` · **Branch:** `fix/capture-daily-volume`
**Method:** eight parallel read-only agents, one per layer, each consulting the expert panel
(`docs/research/experts.md`). No file in `app/`, `lib/`, `db/`, `config/` or `spec/` was modified.
**Result:** 130 findings — 7 P0, 59 P1, 64 P2. By effort: 68 S (<1h), 54 M (1-4h), 8 L (>4h).

This report is organised around one question: **what makes this codebase hard to understand and
hard to change?** Correctness and security are real and get their own section, but they are not
the organising axis — the drift that produced them is.

Detail files carry the evidence, with every line number verified:

| File | Layer | Findings |
|---|---|---|
| [01-controllers.md](01-controllers.md) | Controllers + helpers | 17 |
| [02-use-cases.md](02-use-cases.md) | Use cases, contracts, domain | 16 |
| [03-models.md](03-models.md) | Models + schema | 16 |
| [04-boundaries.md](04-boundaries.md) | Context boundaries + events | 15 |
| [05-gateways.md](05-gateways.md) | Gateways + shared resilience | 16 |
| [06-jobs.md](06-jobs.md) | Background jobs | 19 |
| [07-views.md](07-views.md) | Views, helpers, I18n, Stimulus | 17 |
| [08-quality-tests.md](08-quality-tests.md) | Tooling metrics + test suite | 14 |

---

## Progress — updated 2026-08-30, after six batches

| Batch | Issue / PR | Landed |
|---|---|---|
| 0 — five one-line defects | #490 / #491 | `.kept` in `UpdateTrade`, the FX sync's log column, the ETF schedule, breaker recovery through the chain, `.gitignore` |
| 1 — random spec order | #492 / #493 | The `=begin` block in `spec_helper.rb`; green on five seeds |
| 2 — the currency unit | #496 / #497 | `recalculate_avg_cost!` converts, `ExecuteTrade` refuses an unpriceable mixed trade, the importer requires a currency, the sheet asks for one |
| 3 — one decision, one home | #498 / #499 | `resolve_api_key` ×8 → one module; `recalculate_position` ×2 → `Position#resync_from_trades!` |
| 5 — resilience actually applied | #505 + #506 / #509 | One `fetch_historical` signature; a close-only bar stops blanking real OHLC and stops raising in `widen`; DataBursatil counted against its byte budget; Banxico and ExchangeRate run under their declared breaker; breakers reset between specs |
| 4 — jobs tell the truth | #501 + #502 / #503 | Splits idempotent under Mission Control retry; monitor names match producers; absence alerts; two swallowed-failure jobs report; backfill rescues per bar; dead `retry_on` removed |
| 3 — the rest of §1's read side | #500 / #511 | `format_currency_mx` out of the dashboard's helper and into `MoneyHelper`, 20 hand-written money sites through it, the literal `MXN` and the ambiguous `$` gone; one `format_shares` for five copies; `relative_age` and `absolute_stamp` for three and four |
| 1b — worktrees stop colliding | #486 / #508 | Database names derive from the checkout directory, so a migration in one worktree no longer rewrites another's schema; `db:worktrees` and `db:worktrees:prune` for the strays |
| crypto fundamentals wired | #488 + #514 / #515 | Five pieces of one feature were written and unconnected; `SyncCryptoFundamentalsJob` writes the `CRYPTO_MARKET` row the coin's page actually reads, and both syncs share `StoreFundamentals` |
| §1's blocker, decided | #494 / #517 | [ADR-023](../docs/architecture/adr/0023-a-missing-rate-absents-the-figure.md): a missing rate absents the figure, never fabricates it. `Trading::Domain::FxDegradation` replaces nine `rescue` blocks, two invented zeros and three unguarded paths that 500'd `/portfolio` |
| 6 — the map, first half | (untracked) / #518 | Six false claims in CLAUDE.md corrected against the tree; `navbar_notifications` deleted |

Open, carried forward: **#495** (the `invested_value` naming, see correction below), **#504** (US price syncing has no health monitor — a gap #503 named rather than papered over), **#507** (volume alerts on BMV issuers evaluate against volume no provider supplies), **#510** (the import summary sums amounts across currencies and labels the total with none), **#513** (an alert threshold on a CETE is read as dollars).

### Corrections — findings that did not survive verification

Recorded because an audit nobody corrects becomes a document people cite. Each of these was reported here with more confidence than the code supported.

**UC-05 — the last of §1 is smaller than it looks.** `consolidated_summary` was reported as three drifted copies. What the three shared was `rescue MissingFxRate → nil`, and #494 extracted exactly that into `FxDegradation`. What remains is a three-line warm-up of a lazy `PortfolioSummary`, with two deliberate differences (`load_assets` skips `day_gain`; two of three need a nil guard). The real finding underneath is not duplication: `PortfolioSummary` must be warmed before a view touches it or the exception surfaces in the template, and nothing enforces that — the same shape as the three unguarded conversions #494 fixed.

**MODEL-05 / JOB-10 / BND-09 — the snapshot claims were wrong.** This report said `RebuildSnapshots` overwrites market value with invested value, and that switching preferred currency mixes units in one series. Neither holds. `Portfolio#invested_value` sums `position_market_value_in` — it *is* market value, and `Portfolio#total_value` is a one-line delegation to it. `HistoricalValuation#invested_on` likewise returns market value on a past date. Both writers put market value in `total_value`, which is what it should hold, and all four readers convert from each snapshot's own stored currency. What is actually there is three names that say "invested" and return market value, plus a column no production code reads — naming debt, not data loss. Rewritten as #495.

**UC-05 — `consolidated_summary` is not drift.** Reported here as three copies with one already diverged. Both differences are deliberate: `assemble_consolidado` needs no nil guard because line 29 returns early, and `load_assets` skips the `day_gain` warm-up because only the dashboard and portfolio views render it. What the three share is `rescue MissingFxRate → nil`, which is #494's decision to make. Excluded from batch 3 on that basis.

**VIEW-06 — the 144 figure is a matter of criteria.** Re-measured on the same tree: 36 raw hex literals and 21 raw Tailwind palette classes across views, helpers and Stimulus. The audit's 144 used a broader definition. Neither number is wrong; the discrepancy belongs in #489's terms, which analyses the adjacent opacity-modifier problem properly.

**A note on method.** The pattern behind all three: a real mechanism was confirmed and its consequence assumed. `RebuildSnapshots` really does fire automatically on backdated trades and imports — verifying that says nothing about what the columns hold. Treat every finding below as a lead with a file and line, not as a verified defect, until someone reads the methods involved.

---

## Measured baseline

Objective numbers, measured on this commit — not estimates.

| Metric | Value |
|---|---|
| RubyCritic score (`bin/quality app lib`) | **84.71** — 379 modules: 263 A / 59 B / 40 C / 8 D / 9 F |
| Duplicate-code groups | 56 |
| Worst-rated | `TrendScoreCalculator` (D, cx 334) · `AlpacaGateway` (F, 280) · `ImportTrades` (D, 269) · `FinnhubGateway` (F, 269) — **8 of 9 F's are gateways** |
| RuboCop 1.88.0 | **0 offenses**, no `.rubocop_todo.yml` — but only **45 of 791 cops enabled** |
| Brakeman 8.0.6 | **0 security warnings**, 79 checks, no ignore file |
| bundler-audit | **0 vulnerabilities** |
| RSpec | **3,069 examples, 0 failures**, 1m53s · line **95.81%**, branch **80.35%** |
| i18n-tasks health | green — 959 keys, 0 missing, 0 unused |
| Dead gem dependencies | none |
| Highest churn (12mo, live files) | `MarketController` 35 · `dashboard/show` 24 · `SyncSingleAssetJob` 20 · `MarketHelper` 15 |

**Read this table honestly.** Every gate this project runs is green. The 130 findings below are
all in the space those gates do not measure — which is the actual finding about maintainability:
the safety net catches formatting and CVEs, and nothing else.

---

## The diagnosis

**The dominant defect is not bad code. It is the same decision written down in more than one
place, and the copies drifting apart.**

Eight agents audited eight different layers with no knowledge of each other's work, and seven of
them independently reported the same shape. The views agent phrased it best:

> Every defect below has a correct implementation already in the repo, sitting next to an
> incorrect one.

This matters more than any individual bug, because it is a *rate*: the codebase is not degrading
because anyone writes badly, it is degrading because a change to a rule requires finding N sites
and getting all of them right, with nothing to tell you what N is. Every one of the seven P0s is
downstream of it — none is a design error, all are copies that fell out of sync.

Three consequences, in the order they cost you:

1. **Flexibility** — changing a rule means changing it in several places (§1).
2. **Discoverability** — the documented rules are not the enforced rules, so the map misleads (§2).
3. **Consistency** — the same concept has several representations, so every consumer special-cases (§3).

---

## §1 — Flexibility: decisions that live in more than one place

Each row is one decision the project has made, and every place that decision is currently
written. The "drifted?" column is not hypothetical — it records copies that have **already**
diverged.

| Decision | Written in | Drifted? | IDs |
|---|---|---|---|
| ~~Remaining shares after a trade change~~ | **Fixed** — `Position#resync_from_trades!` (#499). `portfolio.rb:70` was a different method, not a third copy | Was: `update_trade` lost `.kept` → P0 | UC-01, MODEL-03 |
| "A missing FX rate degrades the figure, not the page" | 9 `rescue` sites across 5 use cases, none in `domain/` | Not yet — 9 chances to | UC-06 |
| FX fallback when history misses | `portfolio.rb:95`, `load_assets.rb:60`, `assets_helper.rb:16` | **Yes** — the list sorts by one rule, its rows render by another | HELP-01 |
| `consolidated_summary` | `assemble_panorama.rb:39`, `assemble_consolidado.rb:71`, `load_assets.rb:40` | **No — corrected.** Both differences are deliberate; the shared part is #494's decision | UC-05 |
| Money formatting | `format_currency_mx` (defined once) vs 44 raw `number_*` calls | **Yes** — bare `$` on a screen mixing BMV and NASDAQ · tracked in #500 | VIEW-01 |
| Share precision | 5 sites, `delimiter: ","` omitted in 3 | **Yes** — `1,234.5678` and `1234.5678` on two screens | VIEW-12 |
| Percent sign convention | `signed_percent` (12 sites) vs `number_to_percentage` (6 sites) | **Yes** — two minus glyphs coexist | VIEW-03 |
| Relative time in es-MX | **5** implementations under 5 different names | **Yes** — divergent thresholds · tracked in #500 | HELP-05, VIEW-09 |
| Absolute timestamp `DD MMM YYYY · HH:MM` | 4 identical copies | Not yet | HELP-05 |
| ~~API key resolution~~ | **Fixed** — one `ResolvesApiKey` module (#499); a base class could not hold it, the eight share none | Not yet | GW-05, QA-05 |
| Faraday connection setup | 9 near-identical builders; 2 gateways extracted the right helper, 7 didn't | Partially | GW-05 |
| Theme + currency picker | `settings/_appearance` and `profiles/_preferences_tab` | **Yes** — `/profile` still has the submit-button bug `/settings` documents as removed | VIEW-02 |
| Portfolio snapshot valuation | `take_snapshots_job.rb` and `rebuild_snapshots.rb` | **No — corrected.** Both write market value; see Corrections | JOB-10, BND-09 |
| Trend score writing | `CalculateTrendScoresJob:9` inlines a verbatim copy of a handler | **Yes** — two overlapping writers | JOB-13 |
| Spanish date copy in notifications | `notify_approaching_maturities` vs `notify_approaching_earnings` | **Yes** | UC-14 |
| `executed_at` guard | `execute_trade` and `update_trade` guard it differently; shared helper is dead | **Yes** | UC-13 |

**This table is the report.** Seventeen decisions, each with 2-9 homes, seven already diverged.
Collapsing each of these to one home is the single change that most improves your ability to
modify this app — and it is mostly `S` and `M` work.

Panel — **C2 Hiroto Watanabe (DDD):** *"Every row here is a domain concept that has no object.
`RemainingShares`, `FxDegradation`, `ConsolidatedSummary` — these already have names, they are
written in your own comments. The copies exist because there was no place to put the rule, so
each caller kept its own. That is the whole finding."*

Panel — **C3 Sven Kowalski (Rails):** *"Resist the urge to build an abstraction layer. Nine of
these are one Ruby object or one helper away. Extract the seven that already drifted first —
those are proven, not speculative."*

---

## §2 — Discoverability: where the map disagrees with the territory

Someone opening this repo — you in three months, or the technical self-hoster ADR-0010 targets —
learns rules the code does not follow.

| The map says | The territory is | ID |
|---|---|---|
| ADR-006: `ApplicationUseCase` when you need `yield`/`validate`/`publish` | **24 of 50** subclasses use none of the three; 11 never return a `Failure`, leaving four jobs with unreachable error branches | UC-03 |
| CLAUDE.md: "`AuthenticatedController` loads notifications for navbar" | It does not; `navbar_notifications` is dead code | CTRL (detail) |
| CLAUDE.md §Cross-Context + ADR-002: `Queries::UpcomingDividends` is the live example of the read contract | **Zero callers** | BND-07 |
| `script/audit-entropy.sh` guards the ADR-002 boundary | It greps `Foo::` only. Reports 8 leaks, **6 of them sanctioned**, and misses every real one — which are bare constants. ADR-002 §Mitigations asked for this extension; it was never built | BND-10 |
| ADR-012: colours come from the token contract | 144 raw palette/hex sites. The price chart draws falling prices `#ef4444` while `--color-negative` is `#F43F5E` | VIEW-06 |
| ADR-011: lazy `t(".key")` lookups | 5 surfaces lazy, 6 using absolute keys against §4, 6 untouched, ~60 labels hidden in `statements_helper.rb` where i18n-tasks cannot see them | VIEW-10 |
| ADR-0010 killed the closed beta | 5 user-facing strings still promise it, including a mailer telling a self-hoster their bug goes to beta support | VIEW-07 |
| CLAUDE.md: 3,007 examples | 3,069 | QA-13 |
| The suite guards against order dependencies | `config.order = :random` is inside a `=begin`/`=end` block. **3,069 examples have never been shuffled** — and `spec/support/data_source_registry_isolation.rb` documents a real order leak found only by an accidental seed | QA-02 |
| `.rubocop.yml` enforces style | 45 of 791 cops. That is why RubyCritic finds 9 F's in a tree RuboCop calls clean | QA-04 |
| `AdaptiveScheduling` tunes sync cadence | Write-only abstraction — nothing reads the multiplier | JOB-16 |

Plus the ownership question nobody has answered: **`Asset` is touched by all six contexts and
owned by none.** `Administration` writes it and publishes `MarketData`'s events on its behalf.
The undeclared shared kernel is `Asset`, `User`, `FxRate(History)`, `SystemLog`, `AuditLog`,
`Integration`, `Notification`, `DividendPayment`. ADR-002 admits this deferral under a burned
number; it has been deferred since 2026-05, and **four other findings resolve differently
depending on the answer** (BND-08, BND-12, BND-13, BND-14).

Panel — **C6 Esther Mwangi (scope discipline):** *"A documented convention nobody enforces is
worse than no convention: it costs the reader trust in everything else the document says. Either
enforce ADR-006 or amend it to describe what you actually do. Both are fine. The current state is
not."*

---

## §3 — Consistency: one concept, several representations

Where a consumer is forced to special-case because the producer is not uniform.

- **`Failure([:validation, …])` carries five different payload types** — Hash, AR record, String,
  Symbol. `assets_controller.rb:100` carries a normalising shim to survive it. Failure *tags* are
  consistent; payloads are not. (UC-08)
- **Result consumption in controllers**: 9 `if result.success?`, 2 bare `.value!`, 1 hybrid, the
  rest pattern-matching. `result.failure.last` assumes a tuple shape — a payload-less `Failure`
  renders `"not_found"` to the user or raises `NoMethodError`. (CTRL-03)
- **`fetch_price` returns five shapes under one capability**; **`fetch_historical` has two
  signatures and three return shapes**, and `backfill_price_history_job.rb:73` introspects
  `Method#parameters` to guess which. DataBursatil's shape means **every BMV backfill writes NULL
  OHLC/volume**, silently. (GW-04, GW-14)
- **Three event-publishing styles** across use cases: `_ = yield publish(...)`, bare `publish`,
  direct `EventBus.publish`. (UC-16)
- **`ProcessEventJob` never rehydrates the event**, so 12 handlers carry ~28 lines of
  `event.is_a?(Hash) ? event[:x] : event.x`, with a silent-nil failure mode. (BND-03)
- **Contracts restate model validations** — six overlaps in one pair alone. (UC-07)

---

## §4 — Correctness

Seven P0s. Every one is a drift, not a design error.

| ID | What breaks | Verified |
|---|---|---|
| **MODEL-01** | Nothing at any layer requires `trade.currency == asset.currency`. The form preselects the *user's preferred* currency (`trades_controller.rb:9` → `new.html.erb:53`), the contract only checks membership in `SUPPORTED_CURRENCIES`, `execute_trade.rb:14` lets the param win over the asset, and `position.rb:54` sums `shares * price_per_share` across the mix into `avg_cost` — a column with no currency of its own. That number feeds `PositionBreakdown#from_asset`/`#from_fx`, **the product's differentiator**. `import_trades.rb:234` defaults to literal `"USD"`. The FX capture is impeccable; the number loses its unit upstream of it | ✅ by hand |
| **UC-01** | `update_trade.rb:60` omits `.kept`; its twin and `Position#recalculate_avg_cost!` have it. Edit a trade on a position that ever had a deletion → `shares` counts discarded rows, `avg_cost` doesn't. Permanently incoherent, and it freezes into that day's snapshot | ✅ by hand |
| **UC-02** | `create_first_admin.rb:82` seeds USD→MXN = **17.25**. `portfolio.rb:95` falls back to it on a history miss. A fresh instance values USD holdings at a fabricated number instead of raising `MissingFxRate` and showing the `fx_unavailable` banner built for exactly this. *Nuance:* the window is before the first successful FX sync — which is precisely first-run for a self-hoster | ✅ by hand |
| **GW-01** | `CircuitBreaker` enters `half_open` only inside `#call` (`:40-42`). `GatewayChain:18` `next`s when `state == :open`, **before** reaching `#call`, so the timeout check never runs. `record_permanent_failure` opens on the *first* `:not_supported` failure — what `PythonRunner` returns for an out-of-charset symbol. One bad ticker removes Yahoo from the dividends, splits and prices chains until process restart, silently | ✅ by hand |
| **JOB-01** | `sync_fx_history_job.rb:29` writes `message:`; `system_logs` has `error_message`. `UnknownAttributeError` on every run. *Nuance the agent missed:* the use case runs on line 12, **before** the log — so the FIX data does land; what breaks is logging and job status. The Banxico sync has never written a log row and reports failed every run. It is the one sync job with no spec | ✅ by hand |
| **JOB-02** | `CheckSyncHealthJob` matches exact task names; producers log successes as `"Bulk Crypto Sync: 3 assets"` and failures as `"Bulk Crypto Sync"`. A success can never cure an error → one transient blip falsely alerts *"tus criptomonedas no se han actualizado"* every 6h for a day. Its spec fabricates the log rows, validating the consumer against itself | agent |
| **JOB-03** | `recurring.yml` schedules `"stock"` and `"crypto"` only. The seeded catalogue ships 9 ETFs (VOO, SPY, QQQ…). They get one price at creation and freeze | agent |

Notable P1s in the same family: `SplitAdjuster` is non-idempotent with no transaction and is
reachable from Mission Control's retry button — **one retry doubles the portfolio** (JOB-07,
UC-12); two sync jobs swallow every gateway failure then log `:success` — the audit said three, verified two (JOB-05);
`retry_on Faraday::Error` is dead config since every gateway rescues it, while the errors that do
escape get no retry (JOB-06); `EventBus.publish` has no rescue, so one raising sync handler drops
the remaining subscribers and throws at the publisher *after* the state committed (BND-04);
`BanxicoGateway#parse_date` turns an unparseable date into today, in the money path (GW-07);
"one open position per asset" is enforced by a `find_by`, not an index (MODEL-02).

---

## §5 — Security and privacy

Brakeman: 0 warnings. bundler-audit: 0 vulnerabilities. Secrets: no hardcoded credentials, one
resolution path, no key in any log, timeouts on every gateway. Auth and 2FA were called the
best-reasoned code in the controller layer. No IDOR.

Two real items:

- **QA-01 (do this first).** `alpaca-trades.csv` sits in the repo root: 50 rows of real brokerage
  data — CUSIPs, execution UUIDs, amounts — **untracked and un-gitignored**, in a public repo.
  `.gitignore` has no `*.csv` and no `.DS_Store` (which is also sitting there). `bin/pre-commit`
  will not catch it. One `git add -A` publishes it. *Verified by hand.*
- **MODEL-09.** `users.consents_data_processing_at` is never written. LFPDPPP consent is not
  actually being recorded — the column exists and nothing fills it. Compliance-relevant given
  ADR-0008.

Minor: `save_api_keys` takes `to_unsafe_h` with no contract (UC-15).

---

## §6 — What is already good

Do not touch these, and read them as the reference shape when fixing the rest.

- **The `Assemble*` screens** (dashboard, portfolio, positions, assets) — exemplary use case →
  thin controller. `SyncFxHistory` is the reference use case shape.
- **Multi-currency FX capture** — `fx_rate_at_execution`, `FxRateHistory`/`ExecutionRate`,
  currency-coherent snapshots, fail-loud on missing rate. Called "impeccable" and "excellent code"
  by two independent agents. MODEL-01 is upstream of it, not a flaw in it.
- **Auth / 2FA** — the best-reasoned code in the controller layer.
- **Test discipline** — 228 stub lines across 408 files, engineered isolation (subprocess-network
  guard, registry snapshots), zero `sleep`, shallow factories, no dead specs, no dead gems.
- **Only 3 callbacks in 37 models**, none doing domain work — side effects genuinely go through
  EventBus. The 2.0 subtraction reached the schema (8 drop migrations).
- **`PythonRunner`** — the best file in the gateway scope; Python-from-Ruby is fully justified here.
- **`GatewayFailure`, the registry, the breaker's permanent/transient split** — sound design. The
  failure is uneven application, not the design.
- **i18n-tasks green**, accessibility above average, no English leaking into es-MX copy.

---

## §7 — Recommended sequencing

Ordered by flexibility bought per hour, not by severity.

**Batch 0 — DONE (#491).** `.gitignore` the CSV and `.DS_Store` (QA-01) ·
`.kept` in `update_trade.rb:60` (UC-01) · `message:` → `error_message:` in
`sync_fx_history_job.rb:29` (JOB-01) · add `"etf"` to `recurring.yml` (JOB-03) · move the
`state == :open` check inside `breaker.call` (GW-01). Five one-line-ish fixes, three of them P0.

**Batch 1 — DONE (#493).** Uncomment `spec_helper.rb:49-93` (QA-02). Separate because it is the only item that
may *surface* failures rather than fix them — the isolation file documents a real order leak. Do
it on its own branch and see what falls out. If the suite has silent order dependencies, you want
to know before Batch 2 moves code around.

**Batch 2 — DONE (#497).** The currency unit (MODEL-01). Needs a decision from you before any code:
*is a trade ever allowed to be denominated in a currency other than its asset's?* My
recommendation is **no** — derive `currency` from the asset, make the form field display-only,
and add a DB check plus a contract rule. If the answer is yes, then `positions.avg_cost` needs a
currency column and the breakdown math needs revisiting, which is `L` work. Either way, `avg_cost`
being an unlabeled number is the bug.

**Batch 3 — PARTIALLY DONE (#499);** the rest is #500 and, once #494 is decided, the FX policy. Collapse §1's decisions to one home each. This is the batch that buys the
maintainability you asked for. Start with the seven that already drifted; they are proven.
Mostly `S`/`M`. `FxDegradation`, `RemainingShares` and `ConsolidatedSummary` are the three objects
that pay for themselves immediately.

**Batch 4 — DONE (#503).** Make the jobs tell the truth (JOB-02, JOB-05, JOB-06, JOB-07, JOB-12). Today the
layer reports success while failing; after this it is a signal you can trust. JOB-07 first — a
Mission Control retry currently doubles the portfolio.

**Batch 5 — DONE (#509).** Apply the resilience you already built (GW-02, GW-03, GW-04, GW-05). Banxico and
ExchangeRate declare breaker keys nothing uses, and Banxico blocks an abusing token for a full
calendar day with that token serving both FX and CETES.

**Batch 6 — make the map match the territory** (§2). Decide ADR-006 (enforce or amend), fix the
false claims in CLAUDE.md, rewrite `audit-entropy.sh` to grep bare constants, and write the
`Asset` ownership ADR that has been deferred since May. This is the batch that makes the *next*
audit unnecessary.

**Batch 7 — enforcement, so §1 cannot happen again.** Without this, everything above re-drifts:
three CI greps (raw palette/hex in ERB, unsanctioned number formatters, bare cross-context
constants), and a decision on RuboCop's 746 disabled cops. Enable them in tranches with
`--auto-gen-config` per tranche; a `.rubocop_todo.yml` you are actively burning down is honest
debt, a green run measuring 5.7% of the cops is not.

**Explicitly not recommended:** merging the `sync_*` family wholesale. It looks like 20 duplicated
jobs and it is ~4 real merges — only the 3 bulk-price jobs are genuinely duplicated (~85%). The
per-provider jobs differ legitimately in breaker key, quota and symbol dialect. Detail in
[06-jobs.md](06-jobs.md), which says explicitly which merges are safe.
