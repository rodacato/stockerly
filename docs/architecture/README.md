# Architecture — Stockerly

> Map of the bounded contexts and reference to immutable decisions. This is the **single-screen view** of the architecture; the detail lives in the code.

---

## Stack

- **Backend:** Rails 8.1.2, Ruby 3.3.6
- **DB:** PostgreSQL 16 (primary + Solid Cache + Solid Queue + Solid Cable)
- **Frontend:** Hotwire (Turbo + Stimulus) + Tailwind CSS 4 + Propshaft + Import Maps
- **Domain stack:** dry-monads, dry-validation, dry-types, dry-struct, dry-initializer
- **Testing:** RSpec + FactoryBot + Capybara
- **Deploy:** Kamal 2 + Cloudflare Tunnel + GitHub Actions
- **Observability:** Sentry + lograge structured logs

---

## Bounded Contexts

Stockerly has **6 bounded contexts** under `app/contexts/`. Each owns its contracts, domain logic, events, handlers, and use cases.

| Context | Path | Responsibility |
|---|---|---|
| **Identity** | `app/contexts/identity/` | Registration, authentication, profile, password reset, email verification, audit logging |
| **Trading** | `app/contexts/trading/` | Trades, positions, portfolios, watchlists, splits, snapshots, dashboard |
| **Alerts** | `app/contexts/alerts/` | Alert rules, evaluation, triggering (price, sentiment, volume, concentration) |
| **MarketData** | `app/contexts/market_data/` | External gateways, sync of prices/fundamentals/news/earnings, indices, F&G |
| **Administration** | `app/contexts/administration/` | Asset CRUD, integration management, API key pools, system logs, health |
| **Notifications** | `app/contexts/notifications/` | In-app notification creation and delivery |

> **Historical note:** the original documentation (`docs/archive/spec-2026-Q1/TECHNICAL_SPEC.md`) said "5 bounded contexts". `Notifications` appeared in code later and the doc was never updated. The truth is 6, not 5.

---

## Internal structure of each bounded context

```
app/contexts/{context_name}/
├── contracts/     # dry-validation: input validation at the boundary
├── domain/        # Pure logic (calculators, evaluators, presenters, value objects)
├── events/        # dry-struct: immutable domain events
├── gateways/      # Faraday HTTP adapters (MarketData only)
├── handlers/      # Reactions to events (sync or async)
└── use_cases/     # Orchestration with dry-monads (Success/Failure)
```

---

## Shared infrastructure

Under `app/shared/` (Zeitwerk autoload without namespace prefix):

| Path | Contains |
|---|---|
| `shared/base/` | `ApplicationUseCase`, `ApplicationContract` |
| `shared/domain/` | `CircuitBreaker`, `RateLimiter`, `GatewayChain`, `KeyRotation`, `DataSourceRegistry`, `MarketHours`, `GainLoss`, `DataFreshness`, `HealthMetrics`, `ActivityRecorder` |
| `shared/events/` | `BaseEvent`, `EventBus` |
| `shared/types/` | `Types` (dry-types) |

---

## Typical flow

```
HTTP Request
    ↓
Controller (thin, only HTTP ↔ Use Case)
    ↓
UseCase.call(params)
    ↓
    ├── validate(Contract, params) → Success(attrs) | Failure([:validation, errors])
    ├── domain logic / queries
    └── publish(event)
        ↓
    EventBus.publish
        ├── sync handlers (immediate)
        └── async handlers via ProcessEventJob (Solid Queue)
    ↓
Controller pattern-matches Result
    ↓
Turbo Stream / HTML response
```

---

## Cross-context communication

**Rule:** contexts communicate **only via Domain Events**. No direct imports across contexts.

```ruby
# Example: MarketData publishes → Alerts subscribes
EventBus.subscribe(
  MarketData::Events::AssetPriceUpdated,
  Alerts::Handlers::EvaluateAlertsOnPriceUpdate
)
```

Subscriptions are wired in `config/initializers/event_subscriptions.rb`.

> **Known current leaks** (to be documented in the Sprint 1 code audit, Step 6):
> 1. `Trading::UseCases::AssembleDashboard` calls models in MarketData directly (not via event). "God-dashboard use case" anti-pattern.
> 2. `MarketData::UseCases::GeneratePortfolioInsight` calls `Trading::Domain::ConcentrationAnalyzer` directly.
> 3. `Alerts::Handlers::CreateNotificationOnAlert` invokes a Notifications use case directly (defensible but breaks the rule).
>
> These leaks will be evaluated for resolution in subsequent sprints (not P0).

---

## Architecture decisions

Immutable decisions live in [`adr/`](./adr/) as ADRs (Architecture Decision Records).

| ADR | Title | Status |
|---|---|---|
| [0001](./adr/0001-descriptive-not-prescriptive-language.md) | Descriptive, never prescriptive language | Accepted (2026-05-14) |

> Future ADRs to consider (not yet written):
> - ADR on dry-monads: when to use, when NOT (trivial CRUD)
> - ADR on EventBus sync vs async
> - ADR on ActiveRecord as driven adapter (no Repository pattern)
> - ADR on when to create a new bounded context vs subfolder
> - ADR on cross-context rule "events only" + documented exceptions

---

## Autoloading (Zeitwerk)

Configured in `config/application.rb`. Rules:

- `app/contexts/{ctx}/domain/foo.rb` → `Ctx::Domain::Foo`
- `app/contexts/{ctx}/gateways/foo_gateway.rb` → `Ctx::Gateways::FooGateway`
- `app/contexts/{ctx}/events/foo_happened.rb` → `Ctx::Events::FooHappened`
- `app/shared/domain/foo.rb` → `Foo` (no prefix, via collapse)

If a new bounded context is created, its namespace must be registered in `application.rb`.

---

## Extending Stockerly with a new bounded context

Steps (manual today; generator pending as a future improvement):

1. Create `app/contexts/{name}/` with the 5-6 standard subfolders
2. Register autoload in `config/application.rb`
3. Create the first use case + contract + tests
4. Wire subscriptions to events in `config/initializers/event_subscriptions.rb`
5. Update the "Bounded Contexts" table in this README
6. Consider whether the decision warrants an ADR (likely yes — a new BC is a significant decision)
