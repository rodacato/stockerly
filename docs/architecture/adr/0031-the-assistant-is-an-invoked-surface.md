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
own training, and never states a figure the app did not give it. (Concepts may come from the
model's knowledge since the [second amendment of 2026-10-22](#amendment-2026-10-22-b--concepts-from-the-models-knowledge-figures-only-from-the-app);
facts and figures may not.)

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
the owner's positions to a provider needs its own amendment, with a data review. (Lifted by
switch in the [amendment of 2026-10-22](#amendment-2026-10-22--the-assistant-may-read-the-owners-holdings-by-switch).)

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
- Shipped in phase 1 (#872): the context `app/contexts/assistant/`, the
  `assistant_conversations` / `assistant_messages` tables
  (`db/migrate/20261022120000_create_assistant_conversations.rb`), `AssistantComposeJob`, and the
  doors the isolation check allows (`Assistant::QuestionsController`, `Settings::AssistantsController`,
  routes, `config/initializers/event_subscriptions.rb`). Checks: `assistant-isolation`
  (`script/checks/assistant_isolation.rb`, §4) and the assistant's row in `boundaries`. The
  numbers rule is `Assistant::Domain::NumbersGate`, run on every streamed flush.
- The registry of §2 is `Assistant::Capabilities::Registry` (#880): a closed list, each read
  returning cards or a stated failure.

## Amendment, 2026-10-22 — the assistant may read the owner's holdings, by switch

**Context.** §5 kept version one off the owner's positions and said lifting that "needs its own
amendment, with a data review". Version one shipped (#872, #880, #884, #890) and the owner's
verdict after using it is that a glossary and the market are not what he asks daily. He asks
*"¿cómo va lo mío?"*, *"¿qué vence esta semana?"*, *"¿cuánto llevo en NVDA en pesos?"*:

> *"quiero que sea mi experto de lo que tengo, me interesa y me ayude a contestar preguntas
> rápidas"*

**Decision.** §5 is lifted under four conditions.

1. **A switch, off by default.** Ajustes · Asistente gains *Puede leer tus posiciones*. It is
   shown with the host the positions would be sent to. An instance whose owner never turns it
   on behaves exactly as before. A self-hoster on an external provider does not send their
   portfolio without deciding to.
2. **Through Trading's read API, as plain data.** Assistant → Trading becomes a declared
   customer/supplier pair, the way ADR-025 made Alerts → Trading one. The reads are
   `Trading::Queries::*` returning hashes, never `Position` or `Portfolio` records. The
   isolation check keeps holding: the assistant reads no foreign model.
3. **The screen's own figures.** A holding's value, cost and gain are the ones `/portfolio`
   shows, read from the same calculation. The assistant never recomputes them. MXN cost stays at
   the rate of each trade (ADR-009). A second figure for the same holding would discredit
   both.
4. **Visible when used.** An answer that read the holdings says so under *Lo que leí*, like any
   other read. The numbers gate applies unchanged.

**Data review.** What leaves the instance when the switch is on, and only in a turn that reads
holdings:
- the symbols held;
- their quantities, value, cost and gain;
- the dates of what is maturing or reporting.

It goes to the configured host. With a local host (SheLLM, Ollama) it stays on the owner's
network. With a hosted API it reaches that vendor under that vendor's terms. The switch's line
names the host so the owner knows which case applies. Nothing is persisted outside
`assistant_messages`, which already holds the cards an answer read.

**Alternatives.**
- *Always on, no switch.* Rejected: it decides for every self-hoster what leaves their machine.
- *Aggregates only* (totals, no symbols). Rejected: *"¿cuánto llevo en NVDA?"* is the question.

**Consequences.**
- §5 reads as amended here.
- `CLAUDE.md`'s list of customer/supplier pairs gains Assistant → Trading.
- The registry gains holdings capabilities. They return no data while the switch is off.
- MCP (the plan's P2) stays after this, local only, against a registry that has stopped moving.

## Amendment, 2026-10-22 (b) — concepts from the model's knowledge, figures only from the app

**Context.** §2 says the model "never answers from its own training". In use, that makes the
assistant an index: a question the glossary does not hold gets *"eso no está en el glosario"*, and
a question the glossary does hold gets the glossary's sentence back. The owner wants an expert in
the subjects he invests in — US and Mexican equities, crypto, CETES, USD/MXN — not a lookup:

> *"quiero que el chatbot se sienta como un experto en los temas financieros que me interesan,
> incluso sobre mis posiciones esta bien"*

**Decision.** §2 splits what the model may say into two kinds.

1. **Concepts may come from its knowledge.** What something is, how it is read, why it matters:
   what an RSI measures, how a CETES auction works, why a split does not change a cost basis.
2. **Facts and figures may not.** Anything about a specific asset, the market or the owner's
   holdings comes only from what the registry read: prices, changes, dates, events, headlines,
   amounts. **The numbers gate is unchanged.** A numeral absent from the cards still discards the
   answer, so a concept is explained without figures of its own.
3. **The glossary wins where it speaks.** When the cards carry a glossary entry, the explanation
   follows it rather than a definition of the model's own, so the app and the assistant agree.
4. **Citations mark the line.** A claim from the cards cites its block. What comes from knowledge
   carries no citation, so the reader can see which is which.

§3 holds in full: explaining a concept is description, never a recommendation.

**Alternatives.**
- *Keep §2 strict.* Rejected: it is the verdict above. An assistant limited to the glossary is a
  slower glossary.
- *Allow figures from knowledge too*, such as typical thresholds or historical levels. Rejected:
  a figure the app did not produce cannot be checked against anything, and the gate is the one
  claim of §2 a test can fail.

**Consequences.**
- The prompt's rules say this split. The gate, the registry and the planner do not change.
- The cost is that a conceptual sentence has no source the reader can open. The missing citation
  is the disclosure.
- A good explanation that needs a number ("over 70 is overbought") is discarded unless the cards
  hold that number. The glossary entries that carry such thresholds are the way to make one
  available.

