# Architectural Conventions

> Pragmatic conventions distilled from the ADRs. Keep this short — when in
> doubt the canonical source is the ADR linked at the top of each section.

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

Examples (after the S05 migration):

```ruby
# Pure read
class LoadProfile < SimpleUseCase
  def call(user:)
    user.watchlist_items.includes(asset: :asset_price_histories).order(created_at: :desc)
  end
end

# Single mutation with 404
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

Writes that cross contexts flow exclusively through domain events. Reads follow the customer/supplier pattern — the downstream context (Trading today) calls the supplier's (MarketData's) public read API (`Queries::*`, marked `Domain::*` services, or use cases), never the supplier's ActiveRecord models or gateways. See [ADR-002](adr/0002-trading-marketdata-boundary.md) for details.

---

## Descriptive language (ADR-001)

User-facing copy describes what happened or what is observable; never what the user should do. No "buy", "sell", "rebalance", "consider". See [ADR-001](adr/0001-descriptive-not-prescriptive-language.md).
