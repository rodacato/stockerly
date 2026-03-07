# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/rodacato/stockerly/compare/v0.1.0-alpha...HEAD
[0.1.0-alpha]: https://github.com/rodacato/stockerly/releases/tag/v0.1.0-alpha
