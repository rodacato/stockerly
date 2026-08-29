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
- **Observability:** in-instance error tracker (`/admin/errors`, ADR-020) + lograge structured logs

---

## Bounded Contexts

Stockerly has **6 bounded contexts** under `app/contexts/`. Each owns its contracts, domain logic, events, handlers, and use cases.

| Context | Path | Responsibility |
|---|---|---|
| **Identity** | `app/contexts/identity/` | Single-user lifecycle: first-admin setup, login, profile, password change and reset, onboarding, audit logging |
| **Trading** | `app/contexts/trading/` | Trades, positions, portfolios, watchlists, splits, snapshots, panorama and consolidado screens |
| **Alerts** | `app/contexts/alerts/` | Alert rules, evaluation, triggering (price, sentiment, volume, concentration) |
| **MarketData** | `app/contexts/market_data/` | External gateways, sync of prices/fundamentals/news/earnings, indices, F&G, the `Queries::*` read API |
| **Administration** | `app/contexts/administration/` | Asset CRUD, provider-symbol mapping, integration management, system logs, health |
| **Notifications** | `app/contexts/notifications/` | Notification creation, in-app delivery, daily digest |

> **Historical note:** early documentation said "5 bounded contexts". `Notifications` appeared in code later and the doc was never updated. The truth is 6, not 5.
>
> **Corrected 2026-08-27.** Identity no longer owns registration or email verification: [ADR-0010](./adr/0010-pivot-to-self-hosted-single-user-tracker.md) removed the multi-user surface and Identity collapsed to single-user login/setup. Administration no longer owns "API key pools": [ADR-015](./adr/0015-one-api-key-per-provider.md) retired them in favour of one key per provider.

---

## Internal structure of each bounded context

```
app/contexts/{context_name}/
├── contracts/     # dry-validation: input validation at the boundary
├── domain/        # Pure logic (calculators, evaluators, presenters, value objects)
├── events/        # dry-struct: immutable domain events
├── gateways/      # Faraday HTTP adapters (MarketData only)
├── handlers/      # Reactions to events (sync or async)
├── queries/       # Read API exposed to customer contexts (MarketData only, ADR-002)
└── use_cases/     # Orchestration with dry-monads (Success/Failure)
```

A context has the folders it needs, not all of them: Identity and Notifications have no `domain/`,
Notifications has no `contracts/`, and `gateways/` and `queries/` exist only in MarketData, which
also carries a `discover/` folder for the Descubrir surface.

---

## Shared infrastructure

Under `app/shared/` (Zeitwerk autoload without namespace prefix):

| Path | Contains |
|---|---|
| `shared/base/` | `ApplicationUseCase`, `ApplicationContract` |
| `shared/domain/` | `ApiKeyResolver`, `CircuitBreaker`, `DataFreshness`, `DataSourceRegistry`, `GainLoss`, `GatewayChain`, `GatewayFailure`, `HealthMetrics`, `MarketHours`, `PythonRunner`, `RateLimiter`, `SourceChange` |
| `shared/events/` | `BaseEvent`, `EventBus` |
| `shared/types/` | `Types` (dry-types) |

> `KeyRotation` was replaced by `ApiKeyResolver` when [ADR-015](./adr/0015-one-api-key-per-provider.md) retired multi-key pools; `ActivityRecorder` was deleted with the multi-user surface ([ADR-0010](./adr/0010-pivot-to-self-hosted-single-user-tracker.md)) and has no remaining callers. `PythonRunner` arrived with [ADR-017](./adr/0017-python-bridge-for-yahoo-finance.md).

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

**Rule:** cross-context **writes** flow exclusively through domain events. Cross-context **reads**
follow the customer/supplier pattern of [ADR-002](./adr/0002-trading-marketdata-boundary.md): the
customer calls the supplier's published read API — `Queries::*`, use cases, and domain services
explicitly marked as read API — and never touches the supplier's ActiveRecord models or gateways.

The one adopted pair is **Trading → MarketData** (Trading reads, MarketData does not read Trading).
Another pair adopts the pattern by writing its own ADR, not by precedent.

```ruby
# Writes: events
EventBus.subscribe(
  MarketData::Events::AssetPriceUpdated,
  Alerts::Handlers::EvaluateAlertsOnPriceUpdate
)

# Reads: the supplier's published API
MarketData::Queries::CurrentFearGreed.call
MarketData::Queries::NotableObservations.call(asset_ids: ids)
```

Subscriptions are wired in `config/initializers/event_subscriptions.rb`.

> **Amended 2026-08-27.** This section used to read *"contexts communicate only via Domain Events"*.
> ADR-002, accepted 2026-05-15, lists that exact sentence under its **Negative** consequences —
> *"the line is too absolute; it must be qualified"*. The qualification was made in `CLAUDE.md` and
> in `conventions.md` and missed here for three months.

**Known deviations.** One remains, and it is deliberate rather than pending:

- `Alerts::Handlers::CreateNotificationOnAlert` calls `Notifications::UseCases::CreateNotification`
  directly. This is a cross-context *write* that does not go through an event. It is defensible —
  Notifications is closer to a library than a peer context — but the Alerts ↔ Notifications pair has
  no ADR, so the deviation is recorded rather than blessed.

The three leaks this section listed until 2026-08-27 are otherwise gone, and not because they were
fixed as leaks: `Trading::UseCases::AssembleDashboard` was split into `assemble_panorama.rb` and
`assemble_consolidado.rb` reading through `MarketData::Queries::*`, and both
`MarketData::UseCases::GeneratePortfolioInsight` and `Trading::Domain::ConcentrationAnalyzer` were
deleted in Sprint 3.

---

## Architecture decisions

Decisions live in [`adr/`](./adr/) as ADRs (Architecture Decision Records). An ADR is never edited
to read as though it was always right — a reversal is recorded as a dated amendment or a
`Superseded by` header, because the reasoning is the part worth keeping.

| ADR | Title | Status |
|---|---|---|
| [001](./adr/0001-descriptive-not-prescriptive-language.md) | Descriptive language, never prescriptive | Accepted 2026-05-14 · amended by 013, then 014 |
| [002](./adr/0002-trading-marketdata-boundary.md) | Trading reads MarketData via a formalized read API | Accepted 2026-05-15 |
| [006](./adr/0006-simple-use-case-criterion.md) | `SimpleUseCase`: when NOT to use `ApplicationUseCase` | Accepted 2026-05-15 |
| [007](./adr/0007-defer-i18n-adoption.md) | Defer I18n until multi-locale is real | **Superseded by 011** (2026-08-24) |
| [008](./adr/0008-privacy-notice-domicile-disclosure.md) | Privacy notice omits the full domicile inline | Accepted 2026-05-18 · premise outdated by 010 |
| [009](./adr/0009-fx-history-strategy.md) | Historical FX rates for cross-currency revaluation | Accepted 2026-06-27 · implemented and amended 2026-08-26 |
| [010](./adr/0010-pivot-to-self-hosted-single-user-tracker.md) | Pivot to a self-hosted, single-user asset tracker | Accepted 2026-08-20 · addendum 2026-08-22 |
| [011](./adr/0011-adopt-i18n-for-the-2.0-rewrite.md) | Adopt Rails I18n (single locale, es-MX) | Accepted 2026-08-24 · supersedes 007 |
| [012](./adr/0012-token-contract-and-themes.md) | Separate the token contract from theme values | Accepted 2026-08-24 |
| [013](./adr/0013-action-labels-on-persisted-observations.md) | Action verbs allowed when an observation backs them | Accepted 2026-08-24 · amends 001 · amended by 014 |
| [014](./adr/0014-state-phrases-from-a-closed-catalogue.md) | Reading a state out loud, from a closed catalogue | Accepted 2026-08-25 · amends 013 |
| [015](./adr/0015-one-api-key-per-provider.md) | One API key per provider; retire multi-key rotation | Accepted 2026-08-26 |
| [016](./adr/0016-canonical-market-data-observations.md) | Canonical observations, multi-source kept reachable | Accepted 2026-08-26 |
| [017](./adr/0017-python-bridge-for-yahoo-finance.md) | A Python bridge for Yahoo Finance, run as a subprocess | Accepted 2026-08-26 |
| [018](./adr/0018-totp-with-recovery-codes.md) | TOTP with recovery codes, for an audience of more than one | Accepted 2026-08-27 · reverses design decision D23 |
| [019](./adr/0019-self-contained-by-default.md) | Self-contained by default: the fewest vendors a self-hoster can inherit | Accepted 2026-08-28 · adds the vision's fourth hard rule |
| [020](./adr/0020-internal-error-tracker.md) | An internal error tracker, because a self-hoster's 500 is lost today | Accepted 2026-08-28 |
| [021](./adr/0021-one-definition-of-the-day-change.md) | One definition of the day change, computed from our own closes | Accepted 2026-08-29 |

Eighteen ADRs: **0001, 0002 and 0006–0021**. The gap is explained below.

**ADR-018 is the only one that reverses a decision this project had already published.** Design decision D23 recommended *against* building TOTP, and it was right for the
audience it was written for: one person, who could put Cloudflare Access in front of his own tunnel.
ADR-010 retired that audience. Access cannot be prescribed to a self-hoster who does not have it, so
the recommendation expired with its premise rather than being overruled — and recovery codes ship in
the same scope, because the permanent-lockout risk D23 identified is multiplied by every self-hoster,
none of whom a maintainer can recover.

**Why a table rather than a pointer to the directory.** The filenames already give number and title,
so a pointer would carry those for free. What it cannot carry is the **status column** — which ADR
is superseded, which amends which — and that chain is the one thing a reader needs before trusting
any single file. 001 → 013 → 014 in particular is invisible from a directory listing, and reading
001 alone gets the language rule wrong.

The cost is that this table goes stale, which is exactly what happened: from 2026-05 to 2026-08-27 it
listed ADR-001 and nothing else, while thirteen more were written around it. **Adding an ADR means
adding its row here in the same commit.** A row that disagrees with its file is worse than no row.

### The 0003–0005 numbering gap

**ADR-003, ADR-004 and ADR-005 were never written and never will be. The numbers are burned, not
reserved.** Verified 2026-08-27 against the full history — no file with those numbers was ever added
on any branch.

They exist as citations because [ADR-002](./adr/0002-trading-marketdata-boundary.md) reserved them
forward for work it deferred — Administration as a non-BC, and foreign-event publishing from
`Administration::UseCases::Assets::*`. Neither was ever written, and **ADR-007, one of the three
numbers ADR-002 spent, was later allocated to the I18n deferral** — an unrelated topic. So ADR-002's
*"Pending ADR-007 — Administration may not be a real BC"* now points at a document about Spanish
copy. Both deferrals are still open; they were only un-numbered.

The rule that follows: **cite an ADR number only once the file exists.** Deferred work is named as
deferred work, or gets an issue; a number is assigned by writing the ADR, never by promising one.

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

1. Create `app/contexts/{name}/` with the subfolders it actually needs
2. Register autoload in `config/application.rb`
3. Create the first use case + contract + tests
4. Wire subscriptions to events in `config/initializers/event_subscriptions.rb`
5. Update the "Bounded Contexts" table in this README
6. Consider whether the decision warrants an ADR (likely yes — a new BC is a significant decision).
   If it does, write it and add its row to the ADR table in the same commit — do not reserve a number.
