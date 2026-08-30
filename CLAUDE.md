# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Stockerly is a **self-hosted, single-user** asset tracker — stocks (USD), crypto, and Mexican fixed income (CETES) — with correct MXN/USD multi-currency tracking. Built with Rails 8.1.2, PostgreSQL 16, Hotwire, and Tailwind CSS 4. It uses a pragmatic DDD + Hexagonal Architecture with 6 Bounded Contexts: Identity, Trading (includes Watchlist), Alerts, Market Data, Administration, Notifications.

The multi-user closed beta was run and failed on UX grounds; the audience was dropped and the multi-user surface deleted in place — see [ADR-0010](docs/architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md) and [docs/1.0-retrospective.md](docs/1.0-retrospective.md). There is one account, created by the first-boot Setup Wizard. "Self-hosted for anyone" is packaging discipline, not a mandate to build for hypothetical users.

100% open source — no pricing tiers, no premium features.

## AI Assistant Identity

Read `IDENTITY.md` at the project root — it defines the AI assistant's role as **Staff Software Engineer & Product Architect** specialized in Rails, DDD, and fintech. Follow its working principles, technical expertise, and communication style.

## Commands

```bash
# Development server (Rails + Tailwind CSS watch)
bin/dev

# Run all tests
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

# Local code quality (complexity / smells / duplication) — preventive, pre-Sonar
bin/quality             # RubyCritic on Ruby files changed vs origin/master
bin/quality app lib     # whole-repo baseline (noise tuned in .reek.yml)

# Local CI pipeline (setup + rubocop + bundler-audit + importmap audit + brakeman)
# config/ci.rb declares NO rspec step — run the suite separately.
bin/ci

# Database — names derive from the checkout directory, so each git worktree has its own
bin/rails db:migrate
bin/rails db:seed
bin/rails db:reset      # drop + create + migrate + seed
bin/rails db:worktrees        # every database group on this server + the worktree it belongs to
bin/rails db:worktrees:prune  # drop the groups whose worktree is gone (FORCE=1 skips the prompt)

# Background jobs
bin/jobs                # starts Solid Queue worker

# Clear bootsnap cache (fixes stale config issues)
rm -rf tmp/cache
```

### Before opening a PR

Run `bin/quality` on the changed files and act on the result. Decision rule:

- A new or modified file rated **D or F** → fix the flagged smells, or justify in one line why it stays.
- Real Reek smells (FeatureEnvy, NestedIterators, DuplicateMethodCall) → fix. Idiom noise is already tuned out in `.reek.yml`.
- It's advisory, not a hard gate — SonarQube in CI (`quality.yml`) is the enforcing gate. Don't wire `bin/quality` into `bin/ci`.

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
| **Identity** | `Identity::` | Single-user lifecycle: auth, profile, onboarding, search |
| **Trading** | `Trading::` | Trade execution, portfolio management, watchlists, dashboard, trends |
| **Alerts** | `Alerts::` | Alert rule management, evaluation, triggering |
| **Market Data** | `MarketData::` | External data: prices, fundamentals, news, earnings, indices, gateways |
| **Administration** | `Administration::` | Instance ops: integrations, sync logs, instance settings (asset CRUD moved to `/tracked` per D9) |
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
| `app/shared/domain/` | `ApiKeyResolver`, `CircuitBreaker`, `DataFreshness`, `DataSourceRegistry`, `GainLoss`, `GatewayChain`, `GatewayFailure`, `HealthMetrics`, `MarketHours`, `PythonRunner`, `RateLimiter`, `SourceChange` |
| `app/shared/events/` | `BaseEvent`, `EventBus` |
| `app/shared/types/` | `Types` (Dry::Types definitions) |

`ApiKeyResolver` replaced `KeyRotation`: [ADR-015](docs/architecture/adr/0015-one-api-key-per-provider.md) retired multi-key pools, so there is one key per provider. `ActivityRecorder` was deleted with the `user_activity` telemetry in the 2.0 cleanup.

### Market Data Gateways

`app/contexts/market_data/gateways/` holds **10 concrete provider gateways** — Alpaca, Finnhub, CoinGecko, DataBursatil, Yahoo Finance, Alpha Vantage, FMP, Banxico, ExchangeRate (`FxRatesGateway`), and Alternative.me (`CryptoFearGreedGateway`). That is 15 files: the 10 concrete gateways, 2 base classes (`MarketDataGateway`, `FundamentalsGateway`), 1 error class (`ApiKeyNotConfiguredError`), `RetryPolicy`, and the `ResolvesApiKey` module the eight keyed gateways share. Registration and fallback priority live in `config/initializers/data_sources.rb`. **Polygon.io and CNN are retired** (`db/migrate/20260826210000_remove_retired_integrations.rb`) — do not cite them as sources.

### Autoloading (Zeitwerk)

Configured in `config/application.rb`. Context subdirectories map to explicit Ruby modules:

- `app/contexts/alerts/domain/alert_evaluator.rb` → `Alerts::Domain::AlertEvaluator`
- `app/contexts/market_data/gateways/banxico_gateway.rb` → `MarketData::Gateways::BanxicoGateway`
- `app/contexts/identity/events/first_admin_created.rb` → `Identity::Events::FirstAdminCreated`

Shared infrastructure uses Zeitwerk collapse — no namespace prefix:
- `app/shared/domain/circuit_breaker.rb` → `CircuitBreaker` (no prefix)

### Cross-Context Communication

**Writes** that cross context boundaries flow exclusively through domain events. **Reads** follow the customer/supplier pattern documented in [ADR-002](docs/architecture/adr/0002-trading-marketdata-boundary.md): a downstream context may call the supplier's public read API (use cases and `Queries::*` objects, plus domain services explicitly marked as read API), but never reaches into the supplier's ActiveRecord models or gateways.

Current customer/supplier pair: **Trading → MarketData** (Trading reads, MarketData does not read Trading). Other pairs may adopt the pattern via additional ADRs when needed.

```ruby
# Writes: events (unchanged)
EventBus.subscribe(MarketData::Events::AssetPriceUpdated, Alerts::Handlers::EvaluateAlertsOnPriceUpdate)

# Reads: supplier's public API
sentiment    = MarketData::Queries::CurrentFearGreed.call
observations = MarketData::Queries::NotableObservations.call(asset_ids: ids)
```

Forbidden in Trading: direct AR model access (`MarketIndex.major`, `FearGreedReading.latest_*`, `TechnicalObservation`) and direct gateway instantiation (`MarketData::Gateways::*.new`).

Key cross-context flows:
- `MarketData::Events::AssetPriceUpdated` → `Alerts::Handlers::EvaluateAlertsOnPriceUpdate` (write event)
- `Trading::Events::SplitDetected` → `Trading::Handlers::AdjustPositionsOnSplit` (write event)
- `Identity::Events::FirstAdminCreated` → `Identity::Handlers::CreatePortfolioOnRegistration` (write event) — public registration is gone; the single account is created by the Setup Wizard
- `MarketData::Queries::*` consumed by Trading (read API per ADR-002)

### Use Case Base Classes

Two base classes per [ADR-006](docs/architecture/adr/0006-simple-use-case-criterion.md). Choose by what the use case actually needs.

**`ApplicationUseCase`** — for use cases that compose, validate, or publish:
- `Dry::Monads[:result, :do]` — `yield` for monadic composition
- `validate(ContractClass, params)` — returns `Success(attrs)` or `Failure([:validation, errors])`
- `publish(event)` — dispatches via `EventBus`, returns `Success(event)`
- Returns `Success(value)` / `Failure(tuple)`. Callers pattern-match.

**`SimpleUseCase`** — for trivial wrappers without ceremony:
- Only provides `.call` class-method delegation. No monads, no validate, no publish.
- Use for pure reads (returns the value directly), single-resource mutations with a canonical 404 (use `find!`; let `ActiveRecord::RecordNotFound` propagate), and predicates (returns true/false).
- Returns raw value. Callers consume it directly; controllers `rescue ActiveRecord::RecordNotFound` / `rescue ActiveRecord::RecordInvalid` for the failure paths.

Decision rule: if `yield`, `validate`, or `publish` is needed → `ApplicationUseCase`. Otherwise → `SimpleUseCase`. See `docs/architecture/conventions.md` for examples.

### EventBus

- Singleton at `app/shared/events/event_bus.rb` with `subscribe(event_class, handler)` / `publish(event)`
- Subscriptions wired at boot in `config/initializers/event_subscriptions.rb`
- Handlers with `self.async? = true` are enqueued via `ProcessEventJob` (Solid Queue)
- **Tests must call `EventBus.clear!` before each spec** (configured in `rails_helper.rb`)

### Controllers

- `AuthenticatedController` — base for logged-in pages (session timeout, authentication, onboarding redirect). The navbar's unread count is a helper, not a `before_action`, so a request that renders no navbar does not pay for it
- `Admin::BaseController` — inherits from `AuthenticatedController`, adds `require_admin` guard
- Controllers delegate to Use Cases and pattern-match on results:
  ```ruby
  case UseCase.call(params:)
  in Dry::Monads::Success(value) then ...
  in Dry::Monads::Failure[:validation, errors] then ...
  end
  ```

### Models

38 files in `app/models/` — 37 models plus `ApplicationRecord`. No `repositories/` layer — ActiveRecord is used directly as the driven adapter.

### Frontend Stack

- **CSS:** Tailwind CSS 4 with a custom theme. The design system lives in `design/` (Pencil-based, source of truth); a visual redesign is underway.
- **Icons:** Material Symbols Outlined (Google Fonts)
- **Typography:** Plus Jakarta Sans (headings), Inter (body), JetBrains Mono (financial data)
- **Charts:** CSS/SVG inline (conic-gradient donut, SVG sparklines)

### Layouts

8 layout files in `app/views/layouts/`: `application` (base), `app`, `auth`, `legal`, `onboarding`, `public`, plus `mailer.html.erb` / `mailer.text.erb`. There is **no** `admin` layout — the admin screens render under `app`.

### Access Zones

- **Public:** `/` (302 → `/login`), `/privacy`, `/terms`, `/risk-disclosure`, `/login`
- **First boot:** `/setup` — `ApplicationController#redirect_to_setup` sends every request here while no user exists; `SetupController#require_no_users` redirects away once one does. Then `/onboarding/*` → `/welcome`.
- **Authenticated:** `/dashboard`, `/discover`, `/portfolio`, `/alerts`, `/assets`, `/tracked`, `/positions` (Historial), `/trades/import`, `/market/:symbol`, `/notifications`, `/settings`, `/profile`, `/help`, `/report-bug`
- **Password Reset:** `/forgot-password`, `/reset-password/:token`
- **Second factor (ADR-018):** `/two-factor` and `/recovery-code` are reachable only with a pending login; `/two-factor/setup` and `/two-factor/codes` are enrolment, behind a full session
- **Admin:** `/admin/integrations`, `/admin/logs`, `/admin/errors` (ADR-020, gated by the `developer_mode` switch), `/admin/settings`, `/admin/jobs` (Mission Control)

The standalone `/market` listing, `/news` and `/earnings` were deleted in the 2.0 cleanup (D31 — see the comment in `config/routes.rb`); earnings now live in a tab on each asset's own page. `/admin/assets` is gone (D9): the catalogue is managed from `/tracked`.

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
├── lib/              # lib/ code — Stockerly::Checkout, WorktreeDatabases
└── factories/        # FactoryBot definitions
```

**3,164 examples** (`bundle exec rspec --dry-run`, measured 2026-08-30). Coverage measured the same day: **95.73% line** (7690/8033) and **80.56% branch** (2239/2779) via SimpleCov, with branch coverage enabled. Re-measure rather than quoting this figure once it ages — the `coverage/` report is regenerated on every run, and Sonar reads `coverage/coverage.json`.

## Environment Gotchas

- **`RAILS_ENV=development`** is set in the devcontainer shell — `rails_helper.rb` uses `ENV['RAILS_ENV'] = 'test'` (forced, not `||=`)
- **Rails 8.1 host authorization** blocks unknown hosts (403) — disabled in `test.rb` with `config.hosts.clear`
- **`allow_browser versions: :modern`** returns 406 (not 403), only fires when User-Agent contains a recognized version string
- **`:unprocessable_content`** replaces deprecated `:unprocessable_entity` in Rails 8.1
- **Ruby pattern matching:** `case/in Dry::Monads::Success(value)` / `Failure[:tag, payload]` works (dry-monads implements `deconstruct`/`deconstruct_keys`) and is the canonical controller style — used across ~13 controllers (see the Controllers example above). Use `if result.success?` only for a plain boolean check where you don't need to destructure the value.
- **Solid Cable** is used in development (not async adapter) for cross-process Turbo Stream broadcasts

## Conventions

### Language (3 zones, Rails I18n adopted)

| Zone | Language |
|---|---|
| Chat with Adrian | Español |
| Repo artifacts (commits, issues, PRs, code, comments, docs in `docs/`) | English |
| User-facing UI (views, flashes, mailers, page titles, controller error strings) | **es-MX** |

**Rails I18n, single locale (`es-MX`), managed with `i18n-tasks`.** User-facing copy lives in `config/locales/es-MX.yml` behind lazy lookups (`t(".key")`); code artifacts stay English **including routes** (`/dashboard`, `/assets`, `/alerts`, `/settings`). Adopted **surface by surface as the 2.0 redesign is translated** — a screen gets its keys when its slice lands, so hardcoded es-MX in a not-yet-redesigned view is expected, not a defect. See [ADR-0011](docs/architecture/adr/0011-adopt-i18n-for-the-2.0-rewrite.md), which supersedes ADR-0007: deferring was right while the alternative was rewriting working screens, and stopped being right once every string was being rewritten anyway.

### Other

- Pragmatic over dogmatic — DDD is a tool, not religion
- No over-engineering: only implement what was requested
- Frontend-first: static views first, then connect backend
- Auth via `has_secure_password` (no Devise), `generates_token_for :password_reset` for reset tokens
- Money is modeled as a plain `decimal` amount + ISO `currency` string — no Value Object layer
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
| Vision (norte + audience + JTBDs + non-goals) | `docs/vision/` |
| Architecture map + ADRs | `docs/architecture/` |
| Expert Panel v2 (8 Core + 8 Situational) | `docs/research/experts.md` |
| **How work is tracked (board, issues, research)** | `docs/ops/github-workflow.md` |
| Deployment Guide | `docs/ops/deploy.md` |
| 1.0 retrospective (why the pivot happened) | `docs/1.0-retrospective.md` |
| Design system (source of truth, Pencil-based) | `design/` |
| AI Identity & Principles | `IDENTITY.md` |
| Contributing Guide | `CONTRIBUTING.md` |
