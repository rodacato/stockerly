# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stockerly is a fintech platform for market trends, portfolios, alerts, and earnings built with Rails 8.1.2, PostgreSQL 16, Hotwire, and Tailwind CSS 4. It uses a pragmatic DDD + Hexagonal Architecture with 5 Bounded Contexts: Identity, Trading (includes Watchlist), Alerts, Market Data, Administration.

100% open source — no pricing tiers, no premium features.

## AI Assistant Identity

Read `IDENTITY.md` at the project root — it defines the AI assistant's role as **Staff Software Engineer & Product Architect** specialized in Rails, DDD, and fintech. Follow its working principles, technical expertise, and communication style.

## Commands

```bash
# Development server (Rails + Tailwind CSS watch)
bin/dev

# Run all tests (1841 specs)
bundle exec rspec

# Run single file or line
bundle exec rspec spec/contexts/alerts/use_cases/create_rule_spec.rb
bundle exec rspec spec/contexts/alerts/use_cases/create_rule_spec.rb:15

# Linting
bin/rubocop
bin/rubocop -A          # auto-correct

# Security
bin/brakeman            # static analysis
bin/bundler-audit       # gem vulnerabilities

# Full CI pipeline (setup + rubocop + bundler-audit + importmap audit + brakeman)
bin/ci

# Database
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset      # drop + create + migrate + seed

# Background jobs
bin/jobs                # starts Solid Queue worker

# Clear bootsnap cache (fixes stale config issues)
rm -rf tmp/cache
```

## Architecture

### Hexagonal Architecture + DDD + Event-Driven

Code is organized by **bounded context**, not by technical layer. Each context owns its contracts, domain services, events, handlers, and use cases together.

```
Controller → UseCase.call(params) → Contract (validate) → Domain Logic → EventBus.publish(event)
     ↑                                                                           ↓
Turbo Stream / HTML response                                           Handlers (sync/async)
```

### Bounded Contexts (`app/contexts/`)

| Context | Namespace | Intent |
|---------|-----------|--------|
| **Identity** | `Identity::` | User lifecycle: registration, auth, profiles, onboarding, search |
| **Trading** | `Trading::` | Trade execution, portfolio management, watchlists, dashboard, trends |
| **Alerts** | `Alerts::` | Alert rule management, evaluation, triggering |
| **Market Data** | `MarketData::` | External data: prices, fundamentals, news, earnings, indices, gateways |
| **Administration** | `Administration::` | Admin ops: asset CRUD, integrations, logs, user management |
| **Notifications** | `Notifications::` | Notification creation and delivery |

Each context has this structure:
```
app/contexts/{context_name}/
├── contracts/     # Dry::Validation input validation
├── domain/        # Pure business logic (calculators, evaluators, presenters)
├── events/        # Dry::Struct immutable domain events
├── gateways/      # Faraday HTTP adapters (Market Data only)
├── handlers/      # Event reaction logic (static .call, optional async?)
└── use_cases/     # Dry::Monads orchestration (Success/Failure)
```

### Shared Infrastructure (`app/shared/`)

Cross-cutting code with **no namespace change** — available everywhere:

| Path | Contents |
|------|----------|
| `app/shared/base/` | `ApplicationUseCase`, `ApplicationContract` |
| `app/shared/domain/` | `CircuitBreaker`, `RateLimiter`, `GatewayChain`, `KeyRotation`, `DataSourceRegistry`, `MarketHours`, `GainLoss`, `RiskMetrics` |
| `app/shared/events/` | `BaseEvent`, `EventBus` |
| `app/shared/types/` | `Types` (Dry::Types definitions) |

### Autoloading (Zeitwerk)

Configured in `config/application.rb`. Context subdirectories map to explicit Ruby modules:

- `app/contexts/alerts/domain/alert_evaluator.rb` → `Alerts::Domain::AlertEvaluator`
- `app/contexts/market_data/gateways/polygon_gateway.rb` → `MarketData::Gateways::PolygonGateway`
- `app/contexts/identity/events/user_registered.rb` → `Identity::Events::UserRegistered`

Shared infrastructure uses Zeitwerk collapse — no namespace prefix:
- `app/shared/domain/circuit_breaker.rb` → `CircuitBreaker` (no prefix)

### Cross-Context Communication

Contexts communicate **only via domain events**. No direct imports across contexts.

```ruby
# Market Data publishes → Alerts subscribes
EventBus.subscribe(MarketData::Events::AssetPriceUpdated, Alerts::Handlers::EvaluateAlertsOnPriceUpdate)
```

Key cross-context flows:
- `MarketData::Events::AssetPriceUpdated` → `Alerts::Handlers::EvaluateAlertsOnPriceUpdate`
- `MarketData::Events::FearGreedUpdated` → `Alerts::Handlers::EvaluateSentimentAlerts`
- `Trading::Events::SplitDetected` → `Trading::Handlers::AdjustPositionsOnSplit`
- `Identity::Events::UserRegistered` → `Identity::Handlers::CreatePortfolioOnRegistration`

### ApplicationUseCase Base Class

All Use Cases inherit from `ApplicationUseCase` which provides:
- `Dry::Monads[:result, :do]` — `yield` for monadic composition
- `validate(ContractClass, params)` — returns `Success(attrs)` or `Failure([:validation, errors])`
- `publish(event)` — dispatches via `EventBus`, returns `Success(event)`
- Class-level `.call(...)` delegates to `new.call(...)`

### EventBus

- Singleton at `app/shared/events/event_bus.rb` with `subscribe(event_class, handler)` / `publish(event)`
- Subscriptions wired at boot in `config/initializers/event_subscriptions.rb`
- Handlers with `self.async? = true` are enqueued via `ProcessEventJob` (Solid Queue)
- **Tests must call `EventBus.clear!` before each spec** (configured in `rails_helper.rb`)

### Controllers

- `AuthenticatedController` — base for logged-in pages (loads notifications for navbar)
- `Admin::BaseController` — inherits from `AuthenticatedController`, adds `require_admin` guard
- Controllers delegate to Use Cases and pattern-match on results:
  ```ruby
  case UseCase.call(params:)
  in Dry::Monads::Success(value) then ...
  in Dry::Monads::Failure[:validation, errors] then ...
  end
  ```

### Models

23 ActiveRecord models. No `repositories/` layer — ActiveRecord is used directly as the driven adapter.

### Frontend Stack

- **CSS:** Tailwind CSS 4 with custom theme (primary `#005A98`, see `docs/BRANDING.md`)
- **Icons:** Material Symbols Outlined (Google Fonts)
- **Typography:** Plus Jakarta Sans (headings), Inter (body), JetBrains Mono (financial data)
- **Charts:** CSS/SVG inline (conic-gradient donut, SVG sparklines)

### Layouts

6 layout files in `app/views/layouts/`: `application` (base), `public`, `auth`, `app`, `admin`, `legal`.

### Access Zones

- **Public:** `/`, `/trends`, `/open-source`, `/privacy`, `/terms`, `/risk-disclosure`, `/login`, `/register`
- **Authenticated:** `/dashboard`, `/market`, `/portfolio`, `/alerts`, `/earnings`, `/profile`
- **Password Reset:** `/forgot-password`, `/reset-password/:token`
- **Admin:** `/admin/assets`, `/admin/logs`, `/admin/users`

## Test Structure

```
spec/
├── contexts/         # Mirrors app/contexts/ — organized by bounded context
│   ├── identity/     # contracts/, events/, handlers/, use_cases/
│   ├── trading/      # contracts/, domain/, events/, handlers/, use_cases/
│   ├── alerts/       # contracts/, domain/, events/, handlers/, use_cases/
│   ├── market_data/  # domain/, events/, gateways/, handlers/, use_cases/
│   ├── administration/ # contracts/, events/, handlers/, use_cases/
│   └── notifications/  # handlers/, use_cases/
├── shared/           # Mirrors app/shared/ — base classes, domain, events
├── models/           # Validations, enums, associations, scopes
├── requests/         # HTTP smoke tests, guards, CRUD flows
├── jobs/             # Background job behavior
├── system/           # Capybara end-to-end browser tests
├── integration/      # Multi-layer flow tests
└── factories/        # FactoryBot definitions
```

Coverage: ~94% line, branch coverage enabled via SimpleCov.

## Environment Gotchas

- **`RAILS_ENV=development`** is set in the devcontainer shell — `rails_helper.rb` uses `ENV['RAILS_ENV'] = 'test'` (forced, not `||=`)
- **Rails 8.1 host authorization** blocks unknown hosts (403) — disabled in `test.rb` with `config.hosts.clear`
- **`allow_browser versions: :modern`** returns 406 (not 403), only fires when User-Agent contains a recognized version string
- **`:unprocessable_content`** replaces deprecated `:unprocessable_entity` in Rails 8.1
- **Ruby pattern matching caveat:** `case/in Dry::Monads::Success(data)` does NOT work — use `if result.success?` instead for conditional checks
- **Solid Cable** is used in development (not async adapter) for cross-process Turbo Stream broadcasts

## Conventions

- Respond in **Spanish** by default
- All code, documentation, and comments in **English**
- Pragmatic over dogmatic — DDD is a tool, not religion
- No over-engineering: only implement what was requested
- Frontend-first: static views first, then connect backend
- Auth via `has_secure_password` (no Devise), `generates_token_for :password_reset` for reset tokens
- `money-rails` gem for currency formatting (not custom Value Objects)
- No `ransack` — use ActiveRecord scopes with ILIKE for search/filters

### Commit Style

Follow `CONTRIBUTING.md` conventions:
- Imperative mood ("Add feature" not "Added feature")
- First line under 70 characters
- One commit per logical step
- Never commit API keys, `*.key` files, or `.env` with real values

## Documentation

| Doc | Path |
|-----|------|
| Product Requirements | `docs/spec/PRD.md` |
| Technical Spec | `docs/spec/TECHNICAL_SPEC.md` |
| Database Schema | `docs/spec/DATABASE_SCHEMA.md` |
| Use Cases Catalog | `docs/spec/COMMANDS.md` |
| Expert Profiles | `docs/spec/EXPERTS.md` |
| Deployment Guide | `docs/DEPLOY.md` |
| Brand System | `docs/BRANDING.md` |
| AI Identity & Principles | `IDENTITY.md` |
| Contributing Guide | `CONTRIBUTING.md` |
| Design Processing | `designs/wip/PROCESSING.md` |
