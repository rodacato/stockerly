# ADR-006 — SimpleUseCase: when NOT to use ApplicationUseCase

- **Status:** Accepted
- **Date:** 2026-05-15
- **Author:** Adrian Castillo (with synthesis from the documented expert panel — C2 Hiroto, C6 Esther)
- **Supersedes:** —
- **Related:** [`docs/research/code-audit-2026-05/inventory.md`](../../research/code-audit-2026-05/inventory.md), [Issue #38](https://github.com/rodacato/stockerly/issues/38), [Sprint 1 retro](../../sprints/2026-S01-reset/retro.md), [`CLAUDE.md` — ApplicationUseCase Base Class](../../../CLAUDE.md#applicationusecase-base-class)

---

## Context

The 2026-05 code audit inventoried 67 use cases across 6 bounded contexts. About a third (~20-22, depending on classification) are trivial CRUD wrappers — 13-19 lines of `ApplicationUseCase + Dry::Monads + Contract + Success/Failure` ceremony around a single `find_by`, `update!`, or `destroy!` call.

Examples encountered before this ADR was written:

```ruby
# Alerts::UseCases::ToggleRule (19 lines)
class ToggleRule < ApplicationUseCase
  def call(user:, rule_id:)
    rule = yield find_rule(user, rule_id)
    rule.update!(status: rule.active? ? :paused : :active)
    Success(rule)
  end

  private

  def find_rule(user, id)
    rule = user.alert_rules.find_by(id: id)
    rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
  end
end

# Identity::UseCases::LoadProfile (15 lines)
class LoadProfile < ApplicationUseCase
  def call(user:)
    watchlist_items = user.watchlist_items.includes(asset: :asset_price_histories).order(created_at: :desc)
    Success({ watchlist_items: watchlist_items })
  end
end
```

Two distinct shapes show up:

- **Pure reads** that cannot fail in any meaningful business sense (`LoadProfile`, `ListRecent`, `LoadProgress`, `LoadAssetCatalog`). The `Success(...)` wrap exists solely because the project rule says use cases return Results.
- **Single-resource writes** that can fail with exactly one not-found scenario (`ToggleRule`, `DestroyRule`, `RemoveFromWatchlist`, `ToggleStatus`). These exist alongside Rails' standard `ActiveRecord::RecordNotFound` + `rescue_from` pattern, which would express the same intent in fewer lines.

Both shapes are anti-pattern #3 (patterns over pragmatism): ceremony imposed by the rule rather than required by the problem. The cognitive cost matters at the human scale (a future developer learns the wrong pattern by inertia) and at the maintenance scale (every change to `ApplicationUseCase` has to consider 20+ no-op consumers).

This ADR is a corollary of [ADR-002](0002-trading-marketdata-boundary.md) — both are about matching ceremony to actual requirements rather than applying rules absolutely. The single previous ADR-002 reference example (`MarketData::UseCases::EnsureFreshFxRate`) was a missed exemplar: it should have been migrated to `SimpleUseCase` at creation, but Gemini review enforced the strict ApplicationUseCase rule and the author rubber-stamped the comment. Logged in the S05 PR #64 retro thread.

### Additional factors considered

1. **The base class is not the boundary.** What makes a use case useful is the explicit name, the small surface, and the testability. `ApplicationUseCase` adds dry-monads, validation, and event publishing — features that some use cases need and others don't. The base class should match the need.
2. **Rails idioms are not adversaries.** `find_by` + nil check is more familiar to Ruby developers than `yield find_rule(...)` + `Success/Failure`. When the failure path is single and Rails-canonical (404 from a missing record), `find!` + `rescue_from` is the idiomatic answer.
3. **Test cost.** Every Result-wrapped use case requires `result.value!` or pattern matching in specs. For a pure read, this is overhead the spec doesn't need.
4. **Migration cost.** Moving ~20 use cases to a simpler shape touches ~20 specs and ~20 controllers. The cost is real; the benefit is each future read or single-write use case lands as 3-5 lines instead of 13-19.

---

## Decision

**Use cases choose a base class by what they actually need, not by uniform rule.**

| Use case shape | Base class | Returns |
|---|---|---|
| Validates input via `Contract` | `ApplicationUseCase` | `Success(attrs)` / `Failure([:validation, errors])` |
| Composes multiple fallible steps via `yield` | `ApplicationUseCase` | `Success(value)` / `Failure(tuple)` |
| Publishes events | `ApplicationUseCase` | `Success(value)` |
| Single read, no failure path | `SimpleUseCase` | raw value (or `nil` for "absent") |
| Single mutation with one canonical not-found failure | `SimpleUseCase` + `find!` (let `ActiveRecord::RecordNotFound` propagate) | mutated record |
| Single boolean check / predicate | `SimpleUseCase` | `true`/`false` |

### `SimpleUseCase` base class

```ruby
class SimpleUseCase
  def self.call(*args, **kwargs)
    new.call(*args, **kwargs)
  end
end
```

That's it. The base class provides only `.call` delegation; no monads, no validation helpers, no event helpers. A `SimpleUseCase` returns whatever its `#call` method returns — typically a raw ActiveRecord object, a scope, a hash, or nil/true/false.

### Operational rules

#### ✅ When to use `SimpleUseCase`

- **Read-only loaders for the controller** (`LoadProfile`, `ListRecent`, `LoadProgress`, `LoadAssetCatalog`). Pattern: `result = LoadProfile.call(user:)` followed by `@watchlist_items = result[:watchlist_items]`.
- **Single-resource mutations where not-found = 404**. Use `user.alert_rules.find(id)` (raising `ActiveRecord::RecordNotFound`) and let Rails' default `rescue_from` produce the 404 response.
- **Boolean checks / predicates** that don't compose with other use cases.

#### ❌ When to keep `ApplicationUseCase`

- Anything calling `validate(ContractClass, params)`.
- Anything that needs `publish(event)`.
- Anything where `yield` composition catches more than one failure case (e.g., not-found AND validation AND business-rule).
- Anything that a controller (or another use case) chains via `case ... in Success(...) | Failure(...)` pattern matching.

#### ⚠️ Gray zone

- **Use cases with `yield` but only one branch.** If there's only one possible failure and it's "not found", consider `find!` instead. If the failure is business-rule (e.g., "cannot toggle a paused rule that's already deleted"), keep ApplicationUseCase — the monad readably encodes the constraint.
- **Use cases that publish a single event.** If the event payload is mechanical (an `id`), `SimpleUseCase` + an inline `EventBus.publish(...)` is fine. If the payload requires the use case's return value, keep ApplicationUseCase.

### Rule when in doubt

> *If a use case has zero `yield`, zero `validate`, zero `publish`, and zero pattern-matched callers, it is a `SimpleUseCase`. Anything else stays on `ApplicationUseCase`.*

---

## Consequences

### Positive

- **Reads land as 3-5 lines.** `LoadProfile`, `ListRecent`, etc. shrink to a method body that reads as plain Ruby.
- **Specs simplify.** No more `expect(result).to be_success` + `expect(result.value![:foo])` for use cases that cannot fail.
- **Controllers stop wrapping `Result`.** A `result = LoadProfile.call(user: current_user)` line replaces a `case/in Success` block for the pure-read shape.
- **The cognitive load of the base class matches the work.** New developers see the right ceremony for the right job.
- **Closes anti-pattern #3 for this specific axis.** The "patterns over pragmatism" leak in use cases is sealed.

### Negative

- **Two base classes to choose between.** The decision is now an explicit step rather than "always inherit". The decision matrix above mitigates this, but it adds one more thing to know.
- **CLAUDE.md needs amendment.** The current line "All Use Cases inherit from `ApplicationUseCase`" must be qualified.
- **Migration churn.** ~9 use cases touched in this sprint; their specs and controllers update accordingly. The diff is mechanical but non-trivial.

### Mitigations

- **Decision matrix is short and binary.** Most use cases are obviously one shape or the other; the gray zone is small.
- **Linter / audit script can pin the rule.** A future addition to `script/audit-entropy.sh` can count `SimpleUseCase` subclasses that secretly need `yield` (audit-time check rather than a class-load check), if/when the regression risk materializes.
- **CLAUDE.md amendment is one paragraph.** Done in the same PR as this ADR.

---

## Implementation

### Required for #38 (this sprint)

1. **Create `SimpleUseCase` base class** at `app/shared/base/simple_use_case.rb`.
2. **Migrate 9 trivial use cases** (the discovery card listed 10 but `Trading::UseCases::LoadAssetTrend` was already deleted in S03's Phase 22 cleanup — code-state audit caught this at sprint open):
   - `Identity::UseCases::LoadAssetCatalog`
   - `Identity::UseCases::LoadProgress`
   - `Identity::UseCases::LoadProfile`
   - `Notifications::UseCases::ListRecent`
   - `Alerts::UseCases::UpdatePreferences`
   - `Alerts::UseCases::ToggleRule`
   - `Alerts::UseCases::DestroyRule`
   - `Trading::UseCases::RemoveFromWatchlist`
   - `Administration::UseCases::Assets::ToggleStatus`
3. **Update specs** for the 9 use cases (raw-value assertions instead of `result.value!`).
4. **Update controllers** for the 9 use cases (no more `case ... in Success` blocks for pure reads).
5. **Amend `CLAUDE.md`** "ApplicationUseCase Base Class" section with the SimpleUseCase decision matrix.
6. **Add `docs/architecture/conventions.md`** that documents the decision and points to this ADR.

### Deferred

- **`MarketData::UseCases::EnsureFreshFxRate`** could fit `SimpleUseCase` as well — it has no validate/publish, only yield for composition that could be inlined. Was made `ApplicationUseCase` in PR #64 under Gemini pressure; left in place to avoid undoing the merged work, but flagged as a candidate for a future cleanup pass if the SimpleUseCase pattern gains adoption.
- **Other trivial use cases not on the 10-item list.** The inventory likely has more candidates beyond the original 10; surface them as a follow-up audit when convenient.

---

## Notes

- This ADR closes the issue #38 blocker. The "blocked" label removes when ADR-006 lands.
- The interaction with ADR-002 is intentional: both ADRs encode "rules should match the problem, not the other way around." S05 is the architectural sprint by design; these two ADRs together carry the bulk of the structural cleanup.
