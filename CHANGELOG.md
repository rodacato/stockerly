# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-09-22

### Alpha Vantage and FMP retired (2026-09-16)

#### Changed
- Yahoo Finance is the only fundamentals source: the company overview joins the financial statements on the Python bridge ([ADR-017](docs/architecture/adr/0017-python-bridge-for-yahoo-finance.md), 2026-09-16 amendment). No API key is needed for fundamentals any more.
- The Tracked budget reads the daily quota of the provider that leads fundamentals and names it. Yahoo Finance's daily ceiling doubles to 4,000 calls.
- The financial statements tab names the providers of the stored rows instead of always saying Alpha Vantage.

#### Removed
- Alpha Vantage and FMP: gateways, registrations, integration rows and their stored keys (migrations `20260916130000` and `20260916140000`, irreversible). There is no fallback behind Yahoo for fundamentals.

### Observability moved inside the instance (2026-08-28)

#### Added
- Internal error tracker ([ADR-020](docs/architecture/adr/0020-internal-error-tracker.md)): unhandled exceptions from requests and jobs are recorded in `error_events` through a `Rails.error` subscriber, grouped by exception class plus the first application frame, and read at `/admin/errors`. Request params are filtered at the point of write; rows are purged after 30 days.
- `developer_mode` instance switch, beside `maintenance_mode`, gating the errors screen and its hub row — never the recording.

#### Removed
- Sentry (`sentry-ruby`, `sentry-rails`, its initializer, the `ApplicationController` hook and every `SENTRY_*` reference in the deploy config, workflow, `.env.example` and runbook). The instance no longer needs an external account to answer "why did that 500 happen". `CheckSyncHealthJob` keeps the two channels that already reached the owner.

### 2.0 pivot — self-hosted single-user tracker (shipped to production 2026-08-23)

Stockerly pivoted from a multi-user closed-beta fintech app to a self-hosted,
single-user asset tracker after the closed beta failed on UX grounds. See
[ADR-0010](docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)
.

#### Changed
- Reframed the product as a self-hosted single-user tracker (MXN/USD correct, no aggregators). `Identity` collapsed to single-user login/setup; `Notifications` shrank to in-app only.

- Multi-key API rotation retired in favour of one key per provider ([ADR-015](docs/architecture/adr/0015-one-api-key-per-provider.md)): four providers' terms prohibit using multiple credentials to exceed a free tier. `KeyRotation` → `ApiKeyResolver`.
- Copy moved into Rails I18n (`config/locales/es-MX.yml`, single locale, managed with `i18n-tasks`), adopted surface by surface with the redesign ([ADR-0011](docs/architecture/adr/0011-adopt-i18n-for-the-2.0-redesign.md), superseding ADR-0007).

#### Removed
- Multi-user surface: public registration and email verification. **The first-boot Setup Wizard stays** — `Identity::UseCases::CreateFirstAdmin` is now the only way the single account is created, and `Identity::Events::FirstAdminCreated` replaced `UserRegistered` as the trigger for portfolio and alert-preference creation.
- Most of the `Administration` multi-user surface: invite-by-code system and user management.
- The "AI Intelligence" LLM integration seed (multi-provider gateway) — dropped, never a real feature. No LLM code remains in the tree.
- Models backing the deleted surface (invite codes, remember tokens, email events, user activity).
- Retired data providers Polygon.io and CNN, gateway and integration rows together (`db/migrate/20260826210000_remove_retired_integrations.rb`). Ten concrete gateways remain.
- The standalone `/market` listing, `/news` and `/earnings` screens (D31) and `/admin/assets` (D9) — earnings moved to a tab on each asset page, and the catalogue is managed from `/tracked`.

### Added

- **site:** add a Spanish version and a language switch
- mark the hub row that leaves the product
- **site:** add the OSS landing page for GitHub Pages
- **release:** generate the changelog entry from the commit log
- **design:** ui-kit 0.4.0 — promote NavRow and SwitchRow
- **design:** ajustes flow — one hub, no admin zone
- **design:** consolidado — patrimonio, equity curve, ¿valió la pena?
- **design:** promote Segmented to ui-kit 0.3.0, re-vendor activos
- **design:** activos flow — three-tier ladder + capture sheet
- **design:** asset · Mi posición mode (portfolio lens)
- **design:** cockpit flow — panorama, states, and asset Análisis detail
- **design:** bootstrap Pencil design system + onboarding & auth flows
- **onboarding:** treat CoinGecko as key-requiring (Demo key lifts rate limits)
- **onboarding:** group data sources (key-needed first) + link every source
- **onboarding:** show each provider's purpose + where to get its API key
- **ops:** Resend webhooks → EmailEvent table (invite delivery tracking) (#179) (#186)
- **observability:** UserActivity table + event subscriptions for feature usage (#172) (#187)
- **ops:** CheckSyncHealthJob — proactive Sentry alert on stale syncs (#173) (#185)
- **profile:** 2-col, IdentityCard, theme, sessions, 3-channel prefs (#146) (#156)
- **dashboard:** Stockerly-2.0 design pass for sidebar + main grid (#143) (#154)
- **auth:** password recovery — centered card + 5 dedicated states (#147) (#158)
- **trades:** filter strip, footer totals and inline delete-confirm (#145) (#153)
- **market:** asset detail 'Acerca de la empresa / Ficha' block (#144) (#155)
- **design:** Lumen palette migration in application.css (#142) (#152)
- **admin:** Stockerly-2.0 assets catalogue — es-MX (#137)
- **admin:** Stockerly-2.0 users list — es-MX (#135)
- **admin:** Stockerly-2.0 /admin/integrations — es-MX (#136)
- **admin:** Stockerly-2.0 /admin panel — es-MX (#134)
- **admin:** Stockerly-2.0 /admin/settings — es-MX + audit log (#138)
- **admin:** Stockerly-2.0 system log viewer — es-MX (#139)
- **alerts:** bmv_holiday + cete_auction rule types (#94 follow-up) (#133)
- **market:** Stockerly-2.0 asset detail — adaptive by type, observations-first (#93) (#132)
- **alerts:** Stockerly-2.0 + MX-aware rule types (#94) (#131)
- **earnings:** Stockerly-2.0 + BMV via Yahoo (#100) (#128)
- **notifications:** Stockerly-2.0 inbox + es-MX (#101) (#127)
- **trades:** Stockerly-2.0 design pass for /trades — currency-aware + es-MX (#98) (#118)
- **profile:** Stockerly-2.0 design pass for /profile — settings only + es-MX (#97) (#121)
- **market:** Stockerly-2.0 design pass for /market — MX-first + es-MX (#92) (#120)
- **auth:** password recovery flow es-MX — closes auth family (#99) (#119)
- **portfolio:** Stockerly-2.0 design pass — Lumen + mixed MXN+USD + es-MX (#91) (#117)
- **dashboard:** Stockerly-2.0 design pass — Lumen + MX-first KPIs + es-MX (#90) (#116)
- **auth:** rewrite /register es-MX + Art. 8 NLFPDPPP express consent (#96 + B-03) (#112)
- **auth:** rewrite /login in es-MX (#95) (#111)
- **legal:** rewrite Risk Disclosure to remove false leverage/margin claims (B-02) (#109)
- **legal:** rewrite Terms of Service in es-MX with CDMX jurisdiction (B-01) (#108)
- **legal:** update Privacy + add ARCO procedure for NLFPDPPP compliance
- **identity:** /welcome + /help + /report-bug, replace wizard [#77]
- **identity:** invite-by-code system for closed beta [#74]
- **identity:** rewrite /privacy as LFPDPPP-compliant notice [#73]
- **audit:** trivial handlers for 5 user/admin-actor events [#35]
- **market_data:** Queries namespace with 4 read APIs [#33]
- **market:** Recent Observations block on asset detail [#40]
- **dashboard:** Notable Observations Turbo Frame (user-filtered) [#40]
- **market_data:** DetectTechnicalObservationsJob + schedule [#40]
- **market_data:** DetectTechnicalObservations use case [#40]
- **market_data:** TechnicalIndicators domain calculator [#40]
- **market_data:** TechnicalObservation model + migration [#40]
- **dashboard:** surface Upcoming Events for CETES maturity [#29]
- **trading:** NotifyApproachingMaturities + daily job [#29]
- **trading:** persist maturity_date on fixed-income positions [#29]
- **trading:** contract accepts maturity_date for fixed_income [#29]
- **trading:** add maturity_date column to positions [#29]
- **design:** add unified _kpi_card partial with semantic tokens
- **trading:** tag UpcomingDividend with native currency
- **trading:** thread preferred_currency through dashboard use cases
- **trading:** historical-FX cost basis in PortfolioSummary
- **trading:** make Portfolio aggregates currency-aware
- **trading:** add currency column to portfolio_snapshots
- **trading:** fx_rate backfill rake + extract FxRateResolver (#51)
- **trading:** capture FX rate at trade execution (#49)
- **trading:** add Asset.currency column with country-based backfill (#46)

### Fixed

- **site:** make the language switch reachable, pressable and announced
- **site:** stop claiming every provider has a free tier
- **admin:** say "cerca del límite" beside the quota figure
- hide controls over nothing and move Avisos to Ajustes
- **trading:** drop the currency the radar's rows do not share
- **onboarding:** ask for Banxico before the other five keys
- **identity:** give the recovery codes a frame with one way out
- **onboarding:** count steps finished, not the one on screen
- **admin:** repair Mission Control jobs 401 + link it from Settings
- **admin:** keep current page on asset row actions + repair pagy styling
- **notifications:** route earnings + maturity reminders through CreateNotification
- **security:** patch CVE gems + service-worker URL host check (#207)
- **identity:** harden InviteCode flow — enumeration + expiration (#170) (#184)
- **brand:** fingerprint logo assets to defeat CDN cache (#167)
- **brand:** match Stockerly-2.0 canonical glyph for header + favicon (#161) (#162)
- **legal:** apply Gemini review on PR #110
- **trading:** TakeSnapshotsJob converts mixed-currency positions before summing
- **docs:** apply Gemini review on PR #89
- **docs:** also update qa.md screenshots note (missed in last commit)
- **docs:** apply Gemini review on PR #88
- **docs:** apply Gemini review on PR #86
- **docs:** apply Gemini review on PR #85
- **docs:** apply Gemini review on PR #84
- **docs:** apply Gemini review on PR #82
- **docs:** apply Gemini review on PR #79
- **design:** close brand drifts surfaced by Gemini review [#68]
- **design:** apply text-X-fg dark:text-X consistently on Gemini review [#37]
- **design:** apply Gemini review on PR #67 — a11y + token-pattern fix
- apply Gemini review on PR #66 (3 of 4 comments)
- **audit:** apply Gemini review on PR #65 — consistency + no-op gate
- apply Gemini review on PR #64
- **design:** apply Gemini review on PR #63 — a11y + consistency
- **market_data:** apply Gemini review on PR #62
- **trading:** apply Gemini review on PR #61
- **market_data:** SyncCetes no longer overwrites Asset.maturity_date [#29]
- **design:** apply Gemini review on PR #58
- **trading:** apply Gemini review on PR #57
- **market_data:** restore FK in down migration of portfolio_insights
- **design:** crop wordmark.svg viewBox to remove right-side dead space

### Changed

- **ci:** split the suite across four runners
- **ci:** skip coverage in the pull-request gate
- **site:** give the page a hierarchy instead of one repeated card
- **kit:** retire the info token family
- **brand:** inline the wordmark instead of fetching it
- **auth:** shrink the auth card to the form
- **design:** pay cockpit's debt — D10 money format, dead code, kit 0.3.0
- **market-data:** simplify asset sync status to user-controlled binary
- delete admin/users management (multi-user surface)
- delete remember_token — 'remember me' + active-sessions UI
- delete verify-email feature (dead after registration removal)
- delete multi-user registration + invite_code surface
- drop user_activity — beta usage-audit telemetry (#172), nothing reads it
- drop email_event — beta-only Resend delivery tracking, no place single-user
- **market-data:** rename TrendScore labels to descriptive vocab [#70]
- **design:** migrate dashboard + portfolios + shared + earnings + components [#37]
- **design:** migrate news/index + admin/onboarding/complete to tokens [#37]
- **design:** migrate market views to semantic tokens [#37]
- **design:** migrate auth pages to semantic tokens — setup + password_resets [#37]
- **design:** apply font-display to headings globally via CSS rule [#37]
- **design:** remove text-X-fg/N opacity hacks per WCAG-AA pattern [#37]
- **design:** S05 slice — semantic tokens migration [#37]
- migrate 3 remaining use cases to SimpleUseCase [#38]
- **alerts:** migrate 3 single-mutation use cases to SimpleUseCase [#38]
- **identity:** migrate 3 pure-read use cases to SimpleUseCase [#38]
- **trading:** FxRateResolver delegates to EnsureFreshFxRate [#33]
- **trading:** AssembleDashboard reads MarketData via Queries [#33]
- **design:** migrate admin dashboard to semantic tokens [#37]
- **design:** migrate _log_severity_badge to semantic tokens [#37]
- **design:** migrate _status_badge to semantic tokens [#37]
- **admin:** migrate admin_kpi_card → kpi_card
- **dashboard:** migrate stat_card → kpi_card
- **trading:** drop Position USA-centric scopes + delegate currency to Asset (#50)
- rubocop bracket spacing on the two early drop migrations
- **onboarding:** add horizontal padding to the Launch CTA
- rubocop autocorrect on remember_token removal

### Documentation

- repoint four README artboards at files that exist
- **vision:** drop the stale non-goal on OSS contributors
- describe the release flow the workflow implements
- teach the contribution flow branch protection actually wants [#465]
- show the app that exists, not the beta it used to be [#465]
- **adr:** adopt I18n and separate the token contract from theme values
- **design:** export the 13 artboards as the review artifact
- 2.0 live in prod — session handoff status + cutover bitacora
- add 2.0 production cutover runbook (wipe + deploy)
- keep api_key_pool multi-key (rate-limit workaround) — cancel the rework
- close Tier 1 dead-code cleanup, log the gem-audit correction
- api_key_pool rework keeps the admin UI (deploy-and-forget), single-key not ENV
- capture editorial-source opt-in idea (defer until after api_key_pool rework)
- log notification fix, dead-code sweep, and onboarding polish
- mark notification fix done, re-scope remaining Phase 3 as deferred polish
- log multi-user surface removal complete in bitacora/todo
- log registration-surface delete in bitacora
- log email_event + user_activity deletes in bitacora/todo
- reconcile stale claims — P0 fixed, api_key_pool is plumbing not delete
- add GETTING_STARTED.md and fix local-run README inaccuracies
- **s12:** fix issue-number mapping in scope.md (#180)
- **sprints:** open S12 — trust-safety-and-visibility (#178)
- **sprints:** open S11 — visual-truth-and-completion (#151)
- **sprints:** open S10 — design completion + first beta invite + bug triage (#126)
- **sprints:** open S09 design-pass — Stockerly-2.0 on S08 foundations (#115)
- **legal:** document Art. 16 domicile disclosure as conscious exception (ADR-008)
- **sprints:** apply Gemini review on PR #106
- **sprints:** open S08 beta-readiness — compliance blockers + cost-basis P0 + auth revamps
- add design-workflow WIP memory + mark /welcome ready
- **ops:** add beta support runbook [#78]
- **design:** add Claude Design handoff bundle [#81]
- **sprints:** open S07 beta-prep with goal/scope/log
- **design:** trim components.md from 821 to 155 lines [#68]
- **market:** replace Upside/Downside with neutral Target Δ% label [#36]
- **market:** replace prescriptive TrendScore buckets with descriptive labels [#36]
- **sprint:** open S06 visual-coherence — #36 + #37 final slice + #68
- **design:** memorialize -fg pattern + F&G heatmap exception [#37]
- CLAUDE.md amendment + conventions guide for ADR-006 [#38]
- **adr:** write ADR-006 SimpleUseCase + base class [#38]
- **claude:** amend Cross-Context Communication per ADR-002 [#33]
- **sprint:** log #29 implementation deviations from DoD
- **adr:** apply Gemini review on PR #60
- **adr:** write ADR-002 Trading↔MarketData boundary
- **sprints:** open Sprint 3 — jtbd-alignment
- **vision:** fix JTBD count in audience H1 (5 → 6)
- **sprints:** open Sprint 2 — truth-foundation
- **claude:** fix bounded context count (5 → 6, add Notifications)
- **retro:** sync SHA refs with rebased history
- translate Sprint 1 artifacts to English + add retro
- **sprints:** add sprint protocol + template
- **research:** close Sprint 1 Step 6 — code audit 2026-05-14
- restructure — archive aspirational specs, create vivo skeleton
- **research:** add expert panel v2 — 8 Core + 8 Situational with profiles
- **identity:** rewrite with anti-patterns + brutal-honesty mandate
- close Sprint 1 Step 2 — vision foundation + ADR-001
- **vision:** add JTBD #6 (technical zones) + descriptive-language rule
- **vision:** define audience as beta cerrada (≤20), drop fiscal scope

### Maintenance

- **devcontainer:** persist shell history, and reap zombies with tini
- **deps:** bump sentry-rails from 6.6.2 to 6.7.0
- **deps:** bump csv from 3.3.5 to 3.3.6
- **deps:** bump sentry-ruby from 6.6.2 to 6.7.0
- **deps:** bump bootsnap from 1.24.6 to 1.25.0
- **docs:** remove pre-pivot docs, fix dead refs for 2.0
- **market-data:** drop dead "AI Intelligence" LLM integration seed
- remove unused money-rails + image_processing gems
- replace stale closed-beta + email-verification copy
- remove dead helper methods + two orphan events
- remove dead use cases, skeleton helper, and orphan partials
- remove dead welcome mailer (caller deleted with registration)
- untrack .mcp.json (kwik-e symlink, gitignore it)
- kick off 2.0 evolve — bitacora, todo, ignore redesign/
- **deps:** bump crass to 1.0.7 (fixes ReDoS/DoS advisories)
- **deps:** bump actions/cache from 5 to 6
- **deps:** bump image_processing from 1.14.0 to 2.0.2 (#193)
- **devcontainer:** wire kwik-e harness (personal-safe)
- **ops:** consolidate hardcoded support email + document LFPDPPP routing check (#169) (#182)
- close S11 — retro + qa + log final (#160)
- **mailers:** bug-report mailer es-MX subject + logo regression spec (#149) (#159)
- **market:** translate StatementsHelper line items to es-MX (#148) (#157)
- **brand:** regenerate live SVG assets from canonical brand kit (#140)
- close S10 — retro + qa + log final (#141)
- **invite-prep:** navbar es-MX + beta-invite checklist + e2e smoke (#125) (#130)
- **design:** logo audit + canonical wordmark + es-MX mailers (#124) (#129)
- close S09 — retro + qa + log final (#123)
- close #113 — i18n deferred, document 3-zone language rule in CLAUDE.md (#122)
- close S08 — retro + qa + log final + memory updates (#114)
- add parallel-research-workflow memory + gitignore .research/
- S07→S08 inter-sprint cleanup (4 carry-overs)
- gitignore .local/ for mockups + design-assets memory
- **audit:** exclude border-{l,r,t,b,x,y}-N width utilities from color count
- **audit:** exclude app/views/legal/ from ADR-001 violations count
- **audit:** exclude ADR-002 sanctioned reads from cross-context-leaks regex
- **events:** drop FxRatesRefreshed — system-driven, no audience [#35]
- **events:** delete 5 ghost event classes [#35]
- **design:** delete legacy stat_card + admin_kpi_card partials
- **admin:** remove AI Intelligence section from admin panel
- **market_data:** remove LLM core (gateway + contracts + model + table)
- **market_data:** remove news sentiment analysis pipeline
- **market_data:** remove AI Fundamental Health Check
- **market_data:** remove AI Earnings Narrative
- **market_data:** remove AI Insight from dashboard
- **specs:** remove specs for archived features
- **alerts:** drop archived enum values + clean orphan rows
- **alerts:** remove concentration_risk alert rule
- **alerts:** remove sentiment_above / sentiment_below alert rules
- **trading:** remove ConcentrationAnalyzer (HHI Concentration)
- **trading:** remove TWR benchmark comparison
- **trading:** remove Risk Metrics (Sharpe / drawdown / volatility)
- **design:** Brand Discovery v1 — Lumen palette + focal-frame logo + catalog (#54)
- **public:** remove fake landing, trends, open_source + clean auth fake copy (#53)
- **admin:** capture currency on admin asset creation + remove gateway leak (#52)
- **deps:** bundle update + GH actions + supersede stale dependabot PRs (#48)
- remove unused Claude Code Review workflows (#47)
- remove unused designs/ folder and stale CLAUDE.md reference
- **github:** setup issue templates, PR template, workflow doc
- bootstrap claude memory system for revamp

### Testing

- **trading:** multi-currency calculator audit — no bug found, regression guard added (#168) (#181)
- **trading:** consolidate mixed-currency snapshot specs into one (Gemini review)
- **market:** update analyst_target specs to assert neutral copy [#36]
- **support:** db query-counter idiom + N+1 guard on hot loop [#33]
- **notification:** pin maturity_reminder in enum spec [#29]
- **trading:** mixed MXN+USD portfolio integration spec

### CI

- go back to one test job, now that nothing serialises the gate
- answer the merge queue
- **pages:** stamp the version instead of refusing to publish
- **pages:** refuse to publish a page that names the wrong version
- publish site/ to GitHub Pages
- cut releases from a dispatch, not from seven manual steps
- **deploy:** apply Kamal conventions — image fix, workflow_dispatch action, aliases

## [0.1.0-rc1] - 2026-03-07

Hardened for public deployment. Registration and maintenance controls, admin
settings panel, and CI fixes since the alpha.

### Added
- Admin Settings page with toggle controls for site-wide configuration
- Maintenance mode (503 page for non-admin users, admin-exempt)
- Registration toggle via SiteConfig (close/open public sign-ups)
- Honeypot anti-bot field on registration form
- `SiteConfig` model for persistent key/value site settings
- Navigation links between app and admin areas
- Screenshots gallery in README
- CI badges for security, coverage, PostgreSQL, and PRs welcome

### Changed
- Seeds no longer create a default admin user (use Setup Wizard instead)
- README simplified to single hero screenshot with collapsible gallery

### Fixed
- CI FrozenError caused by Zeitwerk conflict with `lib/stockerly/version.rb`

## [0.1.0-alpha] - 2026-03-07

First public alpha release. All core features are functional with ~2080 specs
and ~94% test coverage.

### Added

#### Platform & Architecture
- Pragmatic DDD + Hexagonal Architecture with 6 Bounded Contexts (Identity, Trading, Alerts, Market Data, Administration, Notifications)
- EventBus for cross-context communication with sync and async handlers
- Railway-oriented programming with dry-monads (Success/Failure) in all Use Cases
- Dry::Validation contracts for input validation at system boundaries
- Hotwire-native frontend (Turbo Drive, Frames, Streams + Stimulus controllers)
- Tailwind CSS 4 with custom fintech theme (primary `#004a99`, Inter font, Material Symbols)
- PWA support with offline fallback, service worker caching strategies, and installable manifest

#### Identity & Auth
- Registration with email verification (soft block banner)
- Login with `has_secure_password` (bcrypt, no Devise)
- Password reset via `generates_token_for :password_reset`
- Session security: 12-hour absolute expiry, 30-minute inactivity timeout
- Admin role with `require_admin` guard
- First-run Setup Wizard for admin onboarding (API keys, asset selection, initial sync)

#### Trading & Portfolio
- Trade execution (buy/sell) with position management and `with_lock` concurrency
- Trade editing (30-day guard) and soft delete (`discarded_at` audit trail)
- Portfolio dashboard with allocation donut charts (by sector and asset type)
- Period returns calculator (1D, 1W, 1M, 3M, 6M, 1Y, YTD, ALL) from snapshots
- SVG performance chart with period return pills
- Time-Weighted Return (TWR) benchmarking against S&P 500, NASDAQ, Dow Jones
- Risk metrics: annualized volatility, Sharpe ratio (vs CETES 28D), max drawdown
- Concentration alerts with HHI (Herfindahl-Hirschman Index) risk levels
- Position annotations (notes + labels)
- Weekly Insight report with observational language (no prescriptive advice)

#### Market Data & Integrations
- Multi-provider gateway architecture with GatewayChain and circuit breakers
- Polygon.io: real-time prices, historical data, news feed, earnings, batch stock quotes
- Alpha Vantage: fundamentals (OVERVIEW + financial statements), bi-weekly sync
- CoinGecko: crypto prices and market data (unified 5-min interval)
- FMP (Financial Modeling Prep): fundamentals fallback via GatewayChain
- Banxico SIE API: CETES rates with yield-to-maturity calculation
- FX rates for multi-currency support
- DataSourceRegistry with EventBus pattern for provider management
- RateLimiter (proactive per-minute/per-day) + CircuitBreaker (reactive on failures)
- API key pool with KeyRotation (least-used strategy)
- Adaptive scheduling with cache-backed exponential backoff

#### Market Intelligence
- 5-factor TrendScore: RSI (30%), Momentum (20%), MACD (20%), Volume (15%), EMA Crossover (15%)
- Graceful degradation: 2-factor fallback for assets with < 35 price closes
- TrendScore factor breakdown tooltip on market listings
- Fear & Greed Index (Alternative.me + CNN) with historical SVG chart and sub-indicators
- Market indices card with sparklines (S&P 500, NASDAQ, Dow Jones, IPC, VIX)
- Asset detail page with adaptive tabs (7 for stocks, 2 for crypto)
- FundamentalCalculator (D/E, TTM, CAGR) with FundamentalPresenter (live P/E, P/B, P/S)
- P/E ratio history chart (inline SVG polyline)
- Earnings calendar with beat/miss badges, EPS bar charts, and earnings detail page
- Analyst target price card with upside/downside % and 52-week range bar
- Volume bars on price charts

#### Alerts
- Price-based alerts (above/below thresholds)
- Sentiment alerts (Fear & Greed above/below)
- Volume spike detection (threshold x 5-day average)
- Concentration risk alerts (portfolio-level with `PORTFOLIO` sentinel)
- Cooldown system (`cooldown_minutes` + `last_triggered_at`)

#### Dividends & Splits
- Dividend tracking from FMP with upcoming payouts on portfolio tab
- Stock split detection with automatic position adjustment (shares x ratio, cost / ratio)
- SplitDetected event with async AdjustPositionsOnSplit handler

#### News
- News feed from Polygon with watchlist and ticker filtering
- Compact news cards with ticker badges

#### AI Intelligence (Phase 22)
- Multi-provider LLM gateway (Anthropic + OpenAI API formats)
- Custom `base_url` support for SheLLM, Ollama, Together, or any compatible endpoint
- Portfolio insight generator with data anonymization
- News sentiment analysis (batch, max 10 articles)
- Fundamental health checks with 7-day cache
- Earnings narrative generator
- LLM response validation via Dry::Validation contracts
- Purely optional: app works without any AI provider configured

#### Administration
- Admin dashboard with asset CRUD, user management, system logs
- Integration management with rate limit usage bars and API key pool UI
- Mission Control Jobs dashboard at `/admin/jobs`
- System health monitoring (Solid Queue depth, Solid Cache stats, circuit breaker status)
- Sync issue tracking with auto-retry and 7-day auto-disable
- Daily API budget enforcement with atomic PostgreSQL counters

#### UX & Performance
- Skeleton loader component with CSS shimmer animation
- Lazy-loaded Turbo Frame tabs (Earnings, Statements)
- Dashboard lazy loading (news feed + trending as separate endpoints)
- Standardized empty state component across all views
- Fragment caching (Russian doll for watchlist, time-based for static sections)
- TradingView Advanced Chart widget (lazy-loaded via IntersectionObserver)
- Global search modal with async fetch, 300ms debounce, keyboard navigation

#### Security & Operations
- Rate limiting on all sensitive endpoints (Rails 8.1 native `rate_limit`)
- Audit logging for login, login failure, and password change events
- IDOR protection tests across controllers
- Structured logging with lograge (JSON, user_id + IP per request)
- Brakeman static analysis + Bundler Audit in CI
- Honeybadger error tracking integration
- `/health` JSON endpoint (ok/degraded/critical, 503 on critical for Kamal)
- Kamal 2 deployment with Cloudflare Tunnel (zero inbound ports)

#### Developer Experience
- Devcontainer with Docker-outside-of-Docker for consistent environments
- CI pipeline: RuboCop + Bundler Audit + Importmap Audit + Brakeman + RSpec
- Pre-commit hooks for secret leak prevention
- ~2080 RSpec specs with ~94% line coverage (branch coverage enabled)

[Unreleased]: https://github.com/rodacato/stockerly/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/rodacato/stockerly/compare/v0.1.0-rc1...v0.2.0
[0.1.0-rc1]: https://github.com/rodacato/stockerly/compare/v0.1.0-alpha...v0.1.0-rc1
[0.1.0-alpha]: https://github.com/rodacato/stockerly/releases/tag/v0.1.0-alpha
