# ADR-025 — Alerts may read Trading's public API, and holdings cross as plain data

- **Status:** Accepted
- **Date:** 2026-09-12
- **Author:** Adrian Castillo
- **Related:** [ADR-002](./0002-trading-marketdata-boundary.md) (this amends its 2026-09-04 amendment), [ADR-024](./0024-asset-ownership-by-column.md), [ADR-001](./0001-descriptive-not-prescriptive-language.md), `ALR-2`

---

## Context

ADR-002 established the customer/supplier pattern for cross-context reads. Its **amendment of
2026-09-04** enumerated what Alerts actually references and declared two pairs — and one non-pair,
in these words:

> **Alerts → Trading is declared out of scope: the dependency does not exist.** No Trading model and
> no `Trading::` reference occurs in the context. Alert rules key on `asset_symbol`, never on a
> position, so there is nothing for a Trading read API to serve. A rule written for a dependency
> that does not exist is an opinion.

**This ADR amends that clause.** Eight days later the dependency exists, and the amendment was right
about its own moment rather than wrong: every word of its reasoning holds for how a rule is
**evaluated**. Rules still key on `asset_symbol`; the evaluator still needs no position; nothing
about `EvaluateAlertsOnPriceUpdate` changes here.

What appeared is a **second consumer** with a different question. `ALR-2` proposes rules instead of
evaluating them, and a proposal has to know what the owner holds. Its trigger is dated and is not a
design argument — Adrian, 2026-09-12:

> *"la verdad es que no sé de technical análisis, así que algo que me dé una ruta o recomendación
> me ayuda a entender más qué buscar"*

So the 2026-09-04 clause is not being overturned, it is being outgrown: it declared that nothing
needed serving, and now something does. That is the same shape [D113](../../../design/DECISIONS.md)
and D54 already established in this project — a decision whose stated premise has changed gets
revisited, and saying so beats quietly contradicting it.

## Decision

**Alerts may read Trading's public read API.** The pair `Alerts → Trading` joins
`Trading → MarketData` and `Alerts → MarketData` as a declared customer/supplier relationship, with
the same rules ADR-002 set: the customer calls use cases and `Queries::*` objects, and never touches
the supplier's ActiveRecord models or its internals. **ADR-002's 2026-09-04 clause declaring this
pair out of scope is superseded by this ADR and by nothing else** — its two declared pairs stand.

Trading gains a `queries/` directory, mirroring the ten MarketData already has. Its first entry is
`Trading::Queries::OpenHoldings`.

**And one rule ADR-002 left implicit, made explicit here: what crosses this boundary is plain
data.** `OpenHoldings` returns an array of hashes — `symbol`, `asset_type`, `shares`,
`market_value` — not `Position` records. A relation would hand Alerts every association and every
method on the model, which is the coupling the boundary exists to prevent; returning four facts
hands it only what it asked for.

MarketData's queries return relations, and that stays correct: Trading is its long-standing
customer and pays for the laziness with `includes`. The difference is deliberate — a **new**
boundary starts closed and opens by demand, rather than inheriting the widest shape available.

## Consequences

**Trading does not read Alerts.** The relationship is one-directional, like ADR-002's. If Alerts
ever needs to *write* something in Trading, that is an event, not a read — ADR-002's write rule is
untouched.

**`Alerts::Domain::RuleSuggestions` is a pure function over holdings.** It takes the hashes, returns
the *shape* of candidate rules, and carries no copy: the view names each one against one i18n key
per condition, so the phrase catalogue stays where [ADR-014](./0014-state-phrases-from-a-closed-catalogue.md)
put it. The domain can therefore be tested without a database, which is how it is tested.

**What the suggestions may say is still bounded by ADR-001.** A suggestion proposes *what to watch*
and explains what the indicator measures; it never proposes what to do about it. *"El RSI mide si un
activo subió mucho muy rápido; arriba de 70 suele llamarse sobrecompra"* is descriptive.
*"NVDA está estirado, considera vender"* would not be, and no key in the catalogue says it.

**The cost of being wrong is small.** If this pair turns out to be a mistake, the surface is one
query object, one directory and one call site in `LoadDashboard` — not a dependency woven through
Alerts.

## Alternatives considered

**Read `Position` directly from Alerts.** Rejected: it is the exact reach-in ADR-002 forbids, and
it would have been the second undeclared boundary in the codebase after the one ADR-024 spent
fifteen months undoing.

**Leave the 2026-09-04 clause unamended and build anyway.** Rejected, and it is the alternative
worth naming explicitly: the code would then contradict a live ADR sentence, which is how a
document stops being read. The clause is cheap to amend and expensive to leave wrong.

**Let `AlertsController` compose — ask Trading itself and hand the data to Alerts.** Rejected. The
coupling is identical; only its location changes, and it moves to the layer where nothing records
it. A boundary that exists in the code and not in the documents is the state this ADR is written
to avoid.

**Move the suggestion engine into Trading**, since Trading already reads holdings. Rejected: the
output is a set of `AlertRule` shapes, and rule semantics — the nine conditions, their thresholds,
their windows — belong to Alerts. Trading would have to learn the alert vocabulary to produce them,
which trades a read boundary for a worse conceptual one.
