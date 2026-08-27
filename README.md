<p align="center">
  <img src="design/brand/wordmark.png" alt="Stockerly" width="230">
</p>

[![CI](https://github.com/rodacato/stockerly/actions/workflows/ci.yml/badge.svg)](https://github.com/rodacato/stockerly/actions/workflows/ci.yml)
[![Quality Gate](https://sonarqube.notdefined.dev/api/project_badges/measure?project=stockerly&metric=alert_status&token=sqb_500a04df309530790583c67b9505d0e88c24474c)](https://sonarqube.notdefined.dev/dashboard?id=stockerly)
[![Coverage](https://sonarqube.notdefined.dev/api/project_badges/measure?project=stockerly&metric=coverage&token=sqb_500a04df309530790583c67b9505d0e88c24474c)](https://sonarqube.notdefined.dev/dashboard?id=stockerly)
[![Maintainability](https://sonarqube.notdefined.dev/api/project_badges/measure?project=stockerly&metric=sqale_rating&token=sqb_500a04df309530790583c67b9505d0e88c24474c)](https://sonarqube.notdefined.dev/dashboard?id=stockerly)
[![Reliability](https://sonarqube.notdefined.dev/api/project_badges/measure?project=stockerly&metric=reliability_rating&token=sqb_500a04df309530790583c67b9505d0e88c24474c)](https://sonarqube.notdefined.dev/dashboard?id=stockerly)
[![Security](https://sonarqube.notdefined.dev/api/project_badges/measure?project=stockerly&metric=security_rating&token=sqb_500a04df309530790583c67b9505d0e88c24474c)](https://sonarqube.notdefined.dev/dashboard?id=stockerly)

[![Ruby](https://img.shields.io/badge/Ruby-3.3.6-CC342D?logo=ruby&logoColor=white)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.2-D30001?logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4-06B6D4?logo=tailwindcss&logoColor=white)](https://tailwindcss.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Open-source, self-hosted single-user asset tracker for stocks (USD), crypto, and Mexican fixed income (CETES), with correct MXN/USD multi-currency tracking. Built with Rails 8, PostgreSQL, Hotwire, and Tailwind CSS 4.

100% free and open source — no pricing tiers, no premium features. See [docs/1.0-retrospective.md](docs/1.0-retrospective.md) for why Stockerly pivoted from a multi-user beta to a single-user tracker.

![Dashboard](docs/screenshots/dashboard.png)

## Features

- **Portfolio Management** — Track trades, positions, gain/loss, allocation by sector and asset type. Period returns (1D to ALL), TWR benchmarking against S&P 500/NASDAQ/Dow Jones, risk metrics (volatility, Sharpe ratio, max drawdown).
- **Market Intelligence** — 5-factor TrendScore (RSI, Momentum, MACD, Volume, EMA), Fear & Greed Index, market indices with sparklines, asset detail pages with adaptive tabs for stocks and crypto.
- **Alerts** — Price thresholds, sentiment conditions, volume spikes, portfolio concentration risk (HHI). Configurable cooldown system.
- **Earnings** — Beat/miss history, EPS bar charts and analyst targets, on each asset's own page.
- **Dividends & Splits** — Automatic tracking and position adjustment on stock splits.
- **Multi-Provider Data** — 10 market-data gateways (Alpaca, Finnhub, CoinGecko, DataBursatil, Yahoo Finance, Alpha Vantage, FMP, Banxico, ExchangeRate, Alternative.me). Gateway chains with circuit breakers and adaptive scheduling.
- **PWA** — Installable as a mobile app with offline support.
- **Discover** — Market-wide waves, five basket-filtered headlines, and the macro calendar. Read without holding a position.
- **Instance Operations** — Integration monitoring with rate-limit bars, sync logs with CSV export, background-job dashboard, and instance settings.

## Architecture

Pragmatic DDD + Hexagonal Architecture with 6 Bounded Contexts:

| Context | Responsibility |
|---------|---------------|
| **Identity** | Single-user auth, profile, onboarding |
| **Trading** | Trades, portfolios, watchlists, dashboard |
| **Alerts** | Rule management, evaluation, triggering |
| **Market Data** | External data: prices, fundamentals, earnings, FX |
| **Administration** | Integrations, sync logs, instance settings |
| **Notifications** | Notification creation and delivery |

Cross-context communication via domain events only. See [CLAUDE.md](CLAUDE.md) for detailed architecture docs.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby 3.3.6, Rails 8.1.2 |
| Database | PostgreSQL 16 (multi-database: primary + Solid Cache + Solid Queue + Solid Cable) |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS 4 |
| Background Jobs | Solid Queue |
| Auth | `has_secure_password` (bcrypt, no Devise) |
| Validation | dry-validation, dry-monads, dry-types, dry-struct |
| Deployment | Kamal 2, Docker, Cloudflare Tunnel |
| CI | GitHub Actions (RSpec, RuboCop, Brakeman, Bundler Audit) |

## Getting Started

The fastest path is the Dev Container (`Reopen in Container` → `bin/dev`). On bare metal
(Ruby 3.3.6 + PostgreSQL 16), `bin/setup` does the whole thing — gems, databases, server —
and seeds demo data when it creates the database. Then open **`http://localhost:4100`**. The
seeded demo login is `demo@stockerly.com` / `password123` (a regular user, not an admin). An
instance with **no** users opens the Setup Wizard instead, which creates the single account;
because the dev seeds always create users, reaching the wizard takes an empty database. No
Node.js needed.

**See [GETTING_STARTED.md](GETTING_STARTED.md) for the full guide** (both run paths, the
four-database setup, background jobs via `bin/jobs`, first-run check, and troubleshooting).

## Configuration

### API Keys

Stockerly ships **10 market-data gateways** (concrete providers — `app/contexts/market_data/gateways/` holds 13 files: 12 classes, of which 2 are base classes, plus 1 error class). API keys are configured during the Setup Wizard, later under Integrations, or via Rails credentials. The registrations below are the source of truth in [`config/initializers/data_sources.rb`](config/initializers/data_sources.rb):

| Provider | Data it serves |
|----------|----------------|
| [Alpaca](https://alpaca.markets/) | US stocks/ETFs/indices — history, news, dividends, splits |
| [Finnhub](https://finnhub.io/) | US prices, symbol search, news, earnings |
| [CoinGecko](https://www.coingecko.com/) | Crypto prices, history, market data |
| [DataBursatil](https://databursatil.com/) | BMV (Mexican market) prices, history, intraday |
| [Yahoo Finance](https://finance.yahoo.com/) | Prices, history, indices, dividends, splits (Python bridge, [ADR-017](docs/architecture/adr/0017-python-bridge-for-yahoo-finance.md)) |
| [Alpha Vantage](https://www.alphavantage.co/) | Fundamentals |
| [FMP](https://financialmodelingprep.com/) | Fundamentals — maintainer-only; its `/api/v3` is gated to accounts created before 2025-08-31 |
| [Banxico](https://www.banxico.org.mx/SieAPIRest/) | Historical FX fixes and CETES rates |
| [ExchangeRate](https://www.exchangerate-api.com/) | Current FX rates |
| [Alternative.me](https://alternative.me/crypto/fear-and-greed-index/) | Crypto Fear & Greed sentiment |

All providers are optional, and several need no key at all. The app works without any API keys configured — you just won't get live market data. Rate limits are per-provider settings stored on each `Integration` record, not hardcoded, so consult the provider's current terms rather than this table.

## Running Tests

```bash
# Full suite (2,690 examples as of 2026-08-27)
bundle exec rspec

# Single file
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb

# Single example
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb:15
```

## Code Quality

```bash
# Linting
bin/rubocop

# Security analysis
bin/brakeman

# Dependency vulnerabilities
bin/bundler-audit

# CI pipeline (setup + rubocop + bundler-audit + importmap audit + brakeman)
# Note: bin/ci has no test step — run `bundle exec rspec` separately.
bin/ci
```

Install local git hooks to reduce accidental secret leaks:

```bash
bin/setup-hooks
```

## Deployment

Stockerly deploys to any Linux server using **Kamal 2** with Docker.

The reference deployment uses Hetzner VPS + Cloudflare Tunnel (no inbound ports needed).

See [docs/ops/deploy.md](docs/ops/deploy.md) for the complete deployment guide.

## Documentation

| Document | Description |
|----------|-------------|
| [GETTING_STARTED.md](GETTING_STARTED.md) | Run Stockerly locally — both paths, databases, jobs, troubleshooting |
| [docs/](docs/) | Documentation index (vision, architecture, ops) |
| [docs/vision/](docs/vision/) | Product north, audience, JTBDs, non-goals |
| [docs/architecture/](docs/architecture/) | Bounded contexts map + ADRs |
| [docs/ops/deploy.md](docs/ops/deploy.md) | Production deployment guide |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution model |
| [RELEASING.md](RELEASING.md) | Versioning and release process |
| [SECURITY.md](SECURITY.md) | Security policy and vulnerability reporting |
| [CLAUDE.md](CLAUDE.md) | Architecture reference (DDD, bounded contexts, conventions) |
| [docs/1.0-retrospective.md](docs/1.0-retrospective.md) | Why Stockerly pivoted from a multi-user beta to a single-user tracker |

## Contributing

Stockerly is a self-hosted single-user tracker, built first as Adrian's daily-driver and packaged so any technically capable person can stand it up. See [docs/vision/audience.md](docs/vision/audience.md) for the audience model and [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute.

If you find a bug or have a question, open an [issue](https://github.com/rodacato/stockerly/issues).

## Gallery

<details>
<summary>More screenshots</summary>

_Captured before the 2.0 mark landed; they show the retired logo, and some screens no longer
exist — the standalone market listing was deleted in the 2.0 cleanup._

![Market Listings](docs/screenshots/market.png)
![Asset Detail](docs/screenshots/asset-detail.png)
![Portfolio](docs/screenshots/portfolio.png)
![Alerts](docs/screenshots/alerts.png)
![Admin — Integrations](docs/screenshots/admin-integrations.png)
![Admin — Settings](docs/screenshots/admin-settings.png)
![Admin — Logs](docs/screenshots/admin-logs.png)

</details>

## License

[MIT](LICENSE) — 100% free and open source.
