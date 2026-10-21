# ADR-031 — The assistant is an invoked surface, grounded in what it retrieved

- **Status:** Accepted
- **Date:** 2026-10-21 (proposed and accepted, PR #862)
- **Author:** Adrian Castillo
- **Related:** [ADR-001](./0001-descriptive-not-prescriptive-language.md), [ADR-002](./0002-trading-marketdata-boundary.md), [ADR-013](./0013-action-labels-on-persisted-observations.md), [ADR-014](./0014-state-phrases-from-a-closed-catalogue.md), [ADR-019](./0019-self-contained-by-default.md), [ADR-023](./0023-a-missing-rate-absents-the-figure.md)

---

## Context

The author wants an assistant inside Stockerly: ask about a symbol or a figure, get the real data
back and a short explanation of it. The trigger is learning and building it — stated as such, not
dressed up as a documented pain — and the job it serves is J7, *learning to read the numbers while
using the app*.

Two decisions stand in the way, and both exist for a reason this repository already paid for.
ADR-001 opens by naming Phase 22's **LLM Insights** among the features that drifted into
prescription and had to be cut. ADR-014 then forbids *"LLM-generated or free-form copy"*: a state
sentence is written once, by a person, and reviewed. An assistant that writes prose at request time
is exactly what that line rules out. Building one without settling this would either break ADR-014
quietly or reopen it by argument every time the assistant says something.

## Decision

**1. The assistant is an invoked surface.** ADR-014's catalogue governs what the app says **on its
own** — every sentence a screen renders without being asked. The assistant speaks only when the
owner asks, on a surface that exists for that purpose, and is **inert until a provider is
configured**. Invocation is the distinction, and it is the only one: nothing the assistant composes
may be rendered anywhere else (a screen, a notification, the daily brief).

**2. It composes only over what it retrieved.** The model never computes, never answers from its
own training, and never states a figure the app did not give it.

- It reads the product only through a registry of capabilities wrapping existing read APIs. Each
  result carries its source and its `as_of`. No database grant, no generated SQL.
- **A number absent from the retrieved context cannot appear in the answer.** An answer that
  breaks this is discarded, not repaired; the cards are shown without prose.
- Figures are rendered from the capability results, never parsed out of the prose.
- Missing data is said, not filled — ADR-023 as an answer.

**3. ADR-001 and ADR-013 hold in full.** The assistant describes; it never recommends, and the
action verb stays the owner's. This ADR amends neither.

**4. It is contained.** Its own bounded context, `Assistant::`, a customer with no privileges in the
sense of ADR-002. Two checks enforce it: nothing outside the context references it, and it writes
nothing but its own conversation record. Deleting the context leaves the product whole.

**5. Version one reads no holdings.** Market data, the asset detail and the glossary only. Sending
the owner's positions to a provider needs its own amendment, with a data review.

**6. It is provider-agnostic by port.** One port, wire dialects as adapters, model ids as
configuration, no vendor SDK (ADR-019). A self-hoster brings a provider or none; no provider is
assumed by the code or recommended by the docs.

**7. Its character never comments on results.** If the assistant has a visual presence, its
expression reflects only what the pipeline is doing — idle, retrieving, composing, no data, failed
— and never a gain, a loss or a market direction. A pleased face on a green day is advice.

## Alternatives considered

**Keep ADR-014's ban and build nothing.** The default, and still the outcome if version one is not
used: the plan ends at a usage threshold, and the context is deleted.

**An LLM that drafts catalogue entries, reviewed by a person.** Keeps ADR-014 intact, but answers
no question at request time — it is a writing aid, not an assistant. Compatible with this ADR.

**An external client over the registry only (MCP), no prose in the app.** Avoids the question
entirely by moving it outside the product. Kept as a later transport over the same registry, not as
the answer: the learning surface J7 asks for lives in the app.

**Free tool-calling chat over the whole product.** Rejected: it moves containment from a check to a
prompt, and puts the book of record within reach of a model.

## Consequences

- ADR-014 carries a scope line pointing here; its rule is unchanged for everything the app says on
  its own.
- The registry needs plain-data, `as_of`-stamped results. Most read APIs return records today, so
  the first phase is that alignment, and it pays for itself without the assistant.
- The numbers rule is the one claim a test can fail, and it is built first.
- Files, migrations and checks are listed here when the first phase merges.
