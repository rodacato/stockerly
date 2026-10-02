# Architecture — Stockerly

> Map of the bounded contexts and reference to immutable decisions. The detail lives in the code.

---

## Stack

- **Backend:** Rails 8.1, Ruby 4.0
- **DB:** PostgreSQL 16 (primary + Solid Cache + Solid Queue + Solid Cable)
- **Frontend:** Hotwire (Turbo + Stimulus) + Tailwind CSS 4 + Propshaft + Import Maps
- **Domain stack:** dry-monads, dry-validation, dry-types, dry-struct
- **Testing:** RSpec + FactoryBot + Capybara
- **Deploy:** Kamal 2 + Cloudflare Tunnel + GitHub Actions
- **Observability:** in-instance error tracker (`/admin/errors`, ADR-020) + lograge structured logs

---

## Bounded Contexts

Stockerly has **6 bounded contexts** under `app/contexts/`. Each owns its contracts, domain logic, events, handlers, and use cases.

| Context | Path | Responsibility |
|---|---|---|
| **Identity** | `app/contexts/identity/` | Single-user lifecycle: first-admin setup, login, TOTP second factor and recovery codes (ADR-018), profile, password change and reset, onboarding, audit logging |
| **Trading** | `app/contexts/trading/` | Trades, positions, portfolios, watchlists, splits, snapshots, panorama and consolidado screens |
| **Alerts** | `app/contexts/alerts/` | Alert rules, evaluation, triggering (price, indicator and calendar conditions; see the `AlertRule` conditions) |
| **MarketData** | `app/contexts/market_data/` | External gateways, sync of prices/fundamentals/news/earnings, indices, F&G, the `Queries::*` read API |
| **Administration** | `app/contexts/administration/` | Asset CRUD, provider-symbol mapping, integration management, system logs, health, the internal error tracker (ADR-020) |
| **Notifications** | `app/contexts/notifications/` | Notification creation, in-app delivery, daily digest |

---

## Internal structure of each bounded context

```
app/contexts/{context_name}/
├── contracts/     # dry-validation: input validation at the boundary
├── domain/        # Pure logic (calculators, evaluators, presenters, value objects)
├── events/        # dry-struct: immutable domain events
├── gateways/      # Faraday HTTP adapters (MarketData only)
├── handlers/      # Reactions to events (sync or async)
├── queries/       # Read API exposed to customer contexts (ADR-002)
└── use_cases/     # Orchestration with dry-monads (Success/Failure)
```

Every context has `contracts/`, `domain/`, `events/`, `handlers/` and `use_cases/` except MarketData,
which has no `contracts/`. `queries/` exists in MarketData, Trading, Alerts and Notifications;
`gateways/` only in MarketData, which also carries a `discover/` folder for the Descubrir surface.
`ls app/contexts/*/` is the source.

---

## Shared infrastructure

Under `app/shared/` (Zeitwerk autoload without namespace prefix):

Everything under `app/shared/{base,domain,events,types}/` is collapsed: `app/shared/domain/circuit_breaker.rb` is `CircuitBreaker`. The inventory is `ls app/shared/*`.

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

Three one-directional pairs are declared: **Trading → MarketData** ([ADR-002](./adr/0002-trading-marketdata-boundary.md)), **Alerts → MarketData** (ADR-002's 2026-09-04 amendment) and **Alerts → Trading** ([ADR-025](./adr/0025-alerts-reads-trading.md)). Another pair adopts the pattern by writing its own ADR, not by precedent.

**Where two contexts write the same table**, [ADR-024](./adr/0024-asset-ownership-by-column.md)
settles it by column rather than by table: Administration owns `Asset`'s identity and lifecycle,
MarketData owns its observed data, and a context that needs a write on the other side calls the
owner's use case. `SystemLog` and `AuditLog` are declared infrastructure — any context may write
them — not shared kernel.

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

**Alerts → Notifications** is a direct write to a sole-writer use case, declared correct by
[ADR-024](./adr/0024-asset-ownership-by-column.md) and ADR-002's 2026-09-04 amendment.

---

## Architecture decisions

Decisions live in [`adr/`](./adr/) as ADRs (Architecture Decision Records). An ADR is never edited
to read as though it was always right — a reversal is recorded as a dated amendment or a
`Superseded by` header, because the reasoning is the part worth keeping.

| ADR | Title | Status |
|---|---|---|
| [001](./adr/0001-descriptive-not-prescriptive-language.md) | Descriptive language, never prescriptive | Accepted 2026-05-14 · amended by 013, then 014 |
| [002](./adr/0002-trading-marketdata-boundary.md) | Trading reads MarketData via a formalized read API | Accepted 2026-05-15 · amended 2026-08-27, 08-29, 09-04 · its 2026-09-04 Alerts → Trading clause superseded by 025 |
| [006](./adr/0006-simple-use-case-criterion.md) | `SimpleUseCase`: when NOT to use `ApplicationUseCase` | Accepted 2026-05-15 · amended 2026-08-27, 2026-09-04 |
| [007](./adr/0007-defer-i18n-adoption.md) | Defer I18n until multi-locale is real | **Superseded by 011** (2026-08-24) |
| [008](./adr/0008-privacy-notice-domicile-disclosure.md) | Privacy notice omits the full domicile inline | **Superseded by 026** (2026-09-13) |
| [009](./adr/0009-fx-history-strategy.md) | Historical FX rates for cross-currency revaluation | Accepted 2026-06-27 · implemented and amended 2026-08-26 |
| [010](./adr/0010-pivot-to-self-hosted-single-user-tracker.md) | Pivot to a self-hosted, single-user asset tracker | Accepted 2026-08-20 · addenda 2026-08-22, 2026-08-27 |
| [011](./adr/0011-adopt-i18n-for-the-2.0-redesign.md) | Adopt Rails I18n (single locale, es-MX) | Accepted 2026-08-24 · supersedes 007 |
| [012](./adr/0012-token-contract-and-themes.md) | Separate the token contract from theme values | Accepted 2026-08-24 |
| [013](./adr/0013-action-labels-on-persisted-observations.md) | Action verbs allowed when an observation backs them | Accepted 2026-08-24 · amends 001 · amended by 014 |
| [014](./adr/0014-state-phrases-from-a-closed-catalogue.md) | Reading a state out loud, from a closed catalogue | Accepted 2026-08-25 · amends 013 |
| [015](./adr/0015-one-api-key-per-provider.md) | One API key per provider; retire multi-key rotation | Accepted 2026-08-26 |
| [016](./adr/0016-canonical-market-data-observations.md) | Canonical observations, multi-source kept reachable | Accepted 2026-08-26 |
| [017](./adr/0017-python-bridge-for-yahoo-finance.md) | A Python bridge for Yahoo Finance, run as a subprocess | Accepted 2026-08-26 · amended 2026-08-29, 09-06 (partly superseded by 09-16), 09-16 |
| [018](./adr/0018-totp-with-recovery-codes.md) | TOTP with recovery codes, for an audience of more than one | Accepted 2026-08-27 · reverses design decision D23 |
| [019](./adr/0019-self-contained-by-default.md) | Self-contained by default: the fewest vendors a self-hoster can inherit | Accepted 2026-08-28 · adds the vision's fourth hard rule |
| [020](./adr/0020-internal-error-tracker.md) | An internal error tracker, because a self-hoster's 500 is lost today | Accepted 2026-08-28 |
| [021](./adr/0021-one-definition-of-the-day-change.md) | One definition of the day change, computed from our own closes | Accepted 2026-08-29 |
| [022](./adr/0022-github-as-the-system-of-record.md) | GitHub is the system of record for outstanding work | Accepted 2026-08-29 · retires the sprint protocol · amended 2026-09-16: retires the two migration records |
| [023](./adr/0023-a-missing-rate-absents-the-figure.md) | A missing exchange rate absents the figure, never fabricates one | Accepted 2026-08-30 · amended 2026-09-04 |
| [024](./adr/0024-asset-ownership-by-column.md) | `Asset` is owned by column: Administration lists it, MarketData measures it | Accepted 2026-09-04 · writes the shared-kernel decision 002 deferred |
| [025](./adr/0025-alerts-reads-trading.md) | Alerts may read Trading's public API, and holdings cross as plain data | Accepted 2026-09-12 · amends 002's 2026-09-04 amendment |
| [026](./adr/0026-no-legal-pages-on-a-self-hosted-instance.md) | A self-hosted instance serves no legal pages; the license carries what applies | Accepted 2026-09-13 · supersedes 008 |
| [027](./adr/0027-production-is-the-only-instance-that-spends-quota.md) | Production is the only instance that spends quota | Accepted 2026-09-04 · numbered 024 by mistake until 2026-09-16 |
| [028](./adr/0028-icons-ship-with-the-html.md) | Icons ship with the HTML | Accepted 2026-09-19 · amended 2026-09-22 |
| [029](./adr/0029-evolve-in-place-rather-than-rewrite.md) | Evolve in place rather than rewrite | Accepted 2026-05-14 (recorded 2026-09-23) |

The numbers 0003–0005 are burned (see below).

The table exists for the **status column**: which ADR is superseded, which amends which (001 → 013 → 014 is invisible from a directory listing). **Adding an ADR means
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

A new bounded context needs no registration: `app/contexts` is an autoload root, so a directory is a namespace.

---

## Extending Stockerly with a new bounded context

Steps (manual today; generator pending as a future improvement):

1. Create `app/contexts/{name}/` with the subfolders it actually needs
2. Create the first use case + contract + tests
3. Wire subscriptions to events in `config/initializers/event_subscriptions.rb`
4. Update the "Bounded Contexts" table in this README
5. Consider whether the decision warrants an ADR (likely yes — a new BC is a significant decision).
   If it does, write it and add its row to the ADR table in the same commit — do not reserve a number.
