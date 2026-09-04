# Architectural Conventions

> Pragmatic conventions distilled from the ADRs — the ones a change is most likely to trip over.
> Keep this short; when in doubt the canonical source is the ADR linked at the top of each section,
> and the full list with its supersession chain is the [ADR table](./README.md#architecture-decisions).
>
> This file is deliberately partial. It covers ADR-001, 002, 006, 011, 012, 013, 014, 015 and 016 —
> the ones with a rule you can break by accident while writing code. Every other ADR is read directly.

---

## Use case base class selection (ADR-006)

When creating a new use case, choose its base class by what the use case actually needs.

### `ApplicationUseCase` when

- The use case validates input via a `Contract`.
- Multiple fallible steps compose with `yield`.
- A domain event is published via `publish(event)`.
- The caller pattern-matches against multiple Failure tuples (`:not_found`, `:validation`, `:unauthorized`, business-specific failure tags).

Example:

```ruby
class CreateRule < ApplicationUseCase
  def call(user:, params:)
    attrs = yield validate(CreateContract, params)
    rule  = yield persist(user, attrs)
    _     = yield publish(Alerts::Events::AlertRuleCreated.new(...))
    Success(rule)
  end
end
```

### `SimpleUseCase` when

- The use case is a pure read with no failure path.
- The use case is a single mutation whose only failure is the canonical 404 (`ActiveRecord::RecordNotFound` from `find`) or validation (`ActiveRecord::RecordInvalid` from `update!`).
- The use case is a predicate (returns `true`/`false`).
- The controller catches the failure with `rescue ActiveRecord::RecordNotFound` / `rescue ActiveRecord::RecordInvalid`.

Examples, both live in the code today:

```ruby
# Pure read — Notifications::UseCases::ListRecent
class ListRecent < SimpleUseCase
  def call(user:, tipo: "todos", estado: "todos", limit: DEFAULT_LIMIT)
    filtered = user.notifications.by_tipo(tipo).by_estado(estado).recent.limit(limit).to_a
    { notifications: filtered, shown_count: filtered.size, ... }
  end
end

# Single mutation with 404 — Alerts::UseCases::ToggleRule
class ToggleRule < SimpleUseCase
  def call(user:, rule_id:)
    rule = user.alert_rules.find(rule_id)  # raises RecordNotFound
    rule.update!(status: rule.active? ? :paused : :active)
    rule
  end
end
```

Caller:

```ruby
def toggle
  rule = Alerts::UseCases::ToggleRule.call(user: current_user, rule_id: params[:id])
  redirect_to alerts_path, notice: "Alert #{rule.active? ? 'activated' : 'paused'}."
rescue ActiveRecord::RecordNotFound
  redirect_to alerts_path, alert: "Alert rule not found."
end
```

### Decision rule

If the use case needs `yield`, `validate`, or `publish` → `ApplicationUseCase`.
Otherwise → `SimpleUseCase`.

---

## Cross-context communication (ADR-002)

Writes that cross contexts flow exclusively through domain events. Reads follow the customer/supplier pattern — the downstream context (Trading today) calls the supplier's (MarketData's) public read API (`Queries::*`, marked `Domain::*` services, or use cases), never the supplier's ActiveRecord models or gateways. See [ADR-002](adr/0002-trading-marketdata-boundary.md) for details, and [ADR-024](adr/0024-asset-ownership-by-column.md) for the one table two contexts write: `Asset` is owned by column, and a write on the other side of that seam calls the owner's use case.

---

## Descriptive language (ADR-001, amended by ADR-013 and ADR-014)

User-facing copy describes what happened or what is observable. **Prescription is allowed only when
a persisted `TechnicalObservation` backs it** — that row is the whole allowance, and it must exist
before the screen does.

| | Allowed | Where the allowance lives |
|---|---|---|
| An action verb on an asset — *compra*, *vende* | ✅ over a persisted observation | `MarketData::Domain::ObservationAction::ACTIONS` — eight observation types, nothing else |
| A sentence naming a state — *"Estirado — no es momento de comprar"* | ✅ from the closed catalogue | `MarketData::Domain::AssetState` + the phrase keys in `es-MX.yml` |
| A verb derived in a view, a helper, or a query at render time | ❌ | — |
| A portfolio-level verb — *rebalancea*, *sal de esta posición* | ❌ | observations are per-asset; nothing backs it |
| Probabilistic predictions, confidence-weighted forecasts, LLM-generated copy | ❌ | untouched by all three ADRs |

Widening the allowance means **writing a detector**, not editing a template: add the observation
type and its persistence path, then add the row to `ACTIONS` or `BY_OBSERVATION`. The reading that
produced the verb stays on screen next to it, dated by its `observed_at`.

See [ADR-001](adr/0001-descriptive-not-prescriptive-language.md),
[ADR-013](adr/0013-action-labels-on-persisted-observations.md),
[ADR-014](adr/0014-state-phrases-from-a-closed-catalogue.md).

> **Corrected 2026-08-27.** This section stated ADR-001's unamended ban — *"No 'buy', 'sell',
> 'rebalance', 'consider'"* — as live policy for three days after ADR-013 and ADR-014 carved it out
> and the carve-out shipped. ADR-001 itself carried the amendment link from the start; this file,
> which is the one people read, did not.

---

## Copy lives in the locale file (ADR-011)

User-facing strings go in `config/locales/es-MX.yml` behind **lazy lookups** — `t(".key")` — so a
key's home is the template that renders it. `es-MX` is the only locale and a second one is not a
goal; the layer is about where strings live, not about translating the product. The catalogue is
managed with `i18n-tasks` (`health` in CI, `normalize` to keep it sorted, `unused` / `missing` to
keep it honest).

Code stays English, **routes included** — `/dashboard`, `/assets`, `/alerts`, `/settings`.

Adopted **surface by surface as the 2.0 redesign lands**. Hardcoded es-MX in a screen nobody has
redesigned yet is expected, not a defect — do not open cleanup PRs for it. See
[ADR-011](adr/0011-adopt-i18n-for-the-2.0-rewrite.md), which supersedes ADR-007.

---

## Token names are a contract (ADR-012)

Views and components reference **roles** — `--color-primary`, `--color-bg-surface`,
`--color-fg-subtle` — never a raw hex and never a value. Token names never change meaning; only
their values are theme-scoped.

Two independent axes: `data-theme` names the **palette** (today: `lumen`), and light/dark is the
**mode**. Do not overload one attribute with both. See
[ADR-012](adr/0012-token-contract-and-themes.md).

---

## Market-data rows record where they came from (ADR-016)

Every persisted observation carries four orthogonal dimensions: `interval`, `status`
(`confirmed` · `provisional` · `disposable`), `source`, and `as_of` separate from `fetched_at`.
`status` is not `source` — a delayed quote is provisional whoever served it.

Three rules keep multi-source a migration rather than a rewrite:

1. `source` is `NOT NULL` on every row. A null source cannot be interpreted later.
2. `as_of` and `fetched_at` stay separate columns.
3. **Reads go through a query object, not scattered `find_by`s** — the resolution policy needs one
   place to live.

Provenance names the sub-source when the sub-source decides the number: `Banxico/SF60653`, not
`Banxico`. See [ADR-016](adr/0016-canonical-market-data-observations.md).

---

## One API key per provider (ADR-015)

A provider gets exactly one credential, resolved through `ApiKeyResolver`. Holding several keys for
the *same* provider to stretch a free tier is prohibited by four providers' terms and is not done
here regardless of what it is called.

Falling back to a **different** provider is a separate, legitimate mechanism and already exists as
`GatewayChain`. Rotating a credential on expiry or compromise is a third thing again. Do not
conflate them. See [ADR-015](adr/0015-one-api-key-per-provider.md).
