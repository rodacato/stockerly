# Hexagonal Architecture Reorganization

> **Started:** 2026-03-02
> **Completed:** 2026-03-02
> **Status:** Complete — 1841 specs passing
> **Goal:** Reorganize from layer-based to bounded-context-based architecture (Hexagonal + DDD + EDA)

---

## Architecture Overview

### Before (Layer-based)
```
app/
├── contracts/       # 16 files — grouped by context ✓
├── domain/          # 23 files — FLAT ✗
├── event_handlers/  # 40 files — FLAT ✗
├── events/          # 41 files — FLAT ✗
├── gateways/        # 11 files — FLAT ✗
├── use_cases/       # 60 files — grouped by context ✓
└── types/           # 1 file
```

### After (Context-based Hexagonal)
```
app/
├── contexts/
│   ├── identity/         # Auth, profiles, onboarding
│   │   ├── contracts/
│   │   ├── events/
│   │   ├── handlers/
│   │   └── use_cases/
│   ├── trading/          # Trades, portfolios, watchlist, dashboard
│   │   ├── contracts/
│   │   ├── domain/
│   │   ├── events/
│   │   ├── handlers/
│   │   └── use_cases/
│   ├── alerts/           # Alert rules, evaluation, notifications
│   │   ├── contracts/
│   │   ├── domain/
│   │   ├── events/
│   │   ├── handlers/
│   │   └── use_cases/
│   ├── market_data/      # Prices, fundamentals, news, earnings, gateways
│   │   ├── domain/
│   │   ├── events/
│   │   ├── gateways/
│   │   ├── handlers/
│   │   └── use_cases/
│   ├── administration/   # Admin CRUD, integrations, logs
│   │   ├── contracts/
│   │   ├── events/
│   │   ├── handlers/
│   │   └── use_cases/
│   └── notifications/    # Notification delivery
│       ├── events/
│       ├── handlers/
│       └── use_cases/
├── shared/               # Cross-cutting infrastructure (no namespace change)
│   ├── base/             # ApplicationUseCase, ApplicationContract
│   ├── domain/           # CircuitBreaker, RateLimiter, GatewayChain, etc.
│   ├── events/           # BaseEvent, EventBus
│   └── types/            # Dry::Types definitions
├── controllers/          # Unchanged
├── models/               # Unchanged
├── jobs/                 # Unchanged
└── views/                # Unchanged
```

### Autoloading Strategy

Zeitwerk collapse — folders organize for humans, Ruby sees flat namespaces:
- `app/contexts/alerts/domain/alert_evaluator.rb` → `Alerts::AlertEvaluator`
- `app/contexts/market_data/gateways/polygon_gateway.rb` → `MarketData::PolygonGateway`
- `app/shared/domain/circuit_breaker.rb` → `CircuitBreaker` (unchanged)

---

## Bounded Contexts

| Context | Namespace | Intent | Owns |
|---------|-----------|--------|------|
| **Identity** | `Identity::` | User lifecycle: registration, auth, profiles, onboarding | 5 contracts, 7 events, 8 handlers, 14 use cases |
| **Trading** | `Trading::` | Trade execution, portfolio management, watchlists, trends | 2 contracts, 7 domain, 7 events, 5 handlers, 9 use cases |
| **Alerts** | `Alerts::` | Alert rule management, evaluation, triggering | 1 contract, 1 domain, 2 events, 4 handlers, 8 use cases |
| **Market Data** | `MarketData::` | External data: prices, fundamentals, news, earnings, indices | 7 domain, 11 gateways, 14 events, 15 handlers, 10 use cases |
| **Administration** | `Administration::` | Admin ops: asset CRUD, integrations, logs, user mgmt | 5 contracts, 7 events, 7 handlers, 17 use cases |
| **Notifications** | `Notifications::` | Notification creation and delivery | 1 event, 1 handler, 3 use cases |
| **Shared** | (none) | Cross-cutting: CircuitBreaker, RateLimiter, EventBus, Types | 7 domain, 2 events infra, 2 base classes, 1 types |

---

## Progress

### Step 0: Setup autoloading and shared infrastructure
- **Status:** Complete
- **Scope:** 13 app files + 10 specs
- **Commit:** `a70d760`

### Step 1: Migrate Identity context
- **Status:** Complete
- **Scope:** 34 app files + 30 specs
- **Commit:** `818efc7`

### Step 2: Migrate Alerts context
- **Status:** Complete
- **Scope:** 16 app files + 14 specs
- **Commit:** `2e8126e`

### Step 3: Migrate Trading context
- **Status:** Complete
- **Scope:** 29 app files + 25 specs
- **Commit:** `a68641d`

### Step 4: Migrate Market Data context
- **Status:** Complete
- **Scope:** 53 app files + 49 specs
- **Commit:** `8aad42a`

### Step 5-6: Migrate Administration + Notifications contexts
- **Status:** Complete
- **Scope:** 41 app files + 28 specs
- **Commit:** `bd16404`

### Step 7: Cleanup and documentation
- **Status:** Complete
- **Scope:** Remove empty dirs, update CLAUDE.md
- **Commit:** (this commit)
- **Commit:** —

---

## Cross-Context Communication Rules

1. **Events are the glue** — contexts communicate only via domain events
2. **No direct imports** across contexts (e.g., Trading should not import `MarketData::PolygonGateway`)
3. **Shared infrastructure** is the exception — CircuitBreaker, RateLimiter, EventBus are available everywhere
4. **Jobs orchestrate** — background jobs in `app/jobs/` wire gateways and use cases together

### Key Cross-Context Event Flows

```
MarketData::AssetPriceUpdated  →  Alerts::EvaluateAlertsOnPriceUpdate
MarketData::FearGreedUpdated   →  Alerts::EvaluateSentimentAlerts
MarketData::SplitDetected      →  Trading::AdjustPositionsOnSplit
Identity::UserRegistered       →  Identity::CreatePortfolioOnRegistration
Identity::UserSuspended        →  Administration::CreateAuditLogOnSuspension
```
