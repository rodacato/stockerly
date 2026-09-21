# Assistant — plan under discussion

A working document, not a decision record. Same status as `DESIGN-AUDIT.md`: scaffolding.
Nothing here is accepted. Delete this file once the decisions it holds have become ADRs and
board items.

**What it proposes:** an opt-in, provider-agnostic assistant inside Stockerly, whose entire
surface to the product is a capability registry — which is also served over MCP. The LLM never
touches a model, a controller or a use case. It sees the registry and nothing else.

**Trigger, stated plainly:** Adrian wants to build and learn this. It is not solving a documented
fastidio. That is a legitimate trigger and it changes the success criterion — this ships to be
interesting and to be defensible in an interview, not to save minutes. Every phase below is
therefore written to be abandonable without leaving debt.

---

## Executive summary

**What.** An opt-in assistant inside Stockerly. You ask about a symbol in the omnibox; it shows
the plan it made, renders cards with real data in ~3 s, then streams a paragraph written only over
what it retrieved, every claim carrying its source. Later it can add tickers in batch, and answer
report requests it never computes itself.

**Why, honestly.** To build and learn this, and to have a defensible piece of work. It is not
fixing a documented fastidio, so every phase carries a usage threshold that ends it — including
P1's, which is five questions in fourteen days.

**The one idea.** *The LLM emits a specification; Ruby executes it.* It never calculates, never
writes, never speaks from its own memory. That single rule produces the capability registry, the
propose→confirm write path, and the report spec — three features, one principle.

**What it may touch.** A registry of capabilities wrapping existing `Queries::*`, each stamped
with `as_of`, a freshness verdict and a character budget. Not a database grant, not generated SQL:
the domain's meaning (FX at execution, weighted cost basis, splits) lives in Ruby, and a model
writing its own SQL would return numbers that are plausible and wrong. Writes reach preferences
only — watchlist, tracked, alerts — never the book of record.

**Why it cannot take over.** Its own bounded context, a customer with no privileges under ADR-002,
depended on by nothing. Two greppable checks land in P0 before the first line of assistant code:
nothing outside may reference it, and it writes nothing but its own conversation log. Delete the
directory and the product is whole.

**What makes it work rather than impress.** Eight gates, all code. The one that matters: a number
absent from the retrieved context cannot appear in the output, and that is a spec that can fail.
When data is missing the answer is to say so — ADR-023 as UI. The cards render before the prose,
so the answer is useful before the model writes a word, and every failure mode — no LLM
configured, quota exhausted, job killed, provider down — degrades to the same cards.

**Portability.** One port, two dialects (OpenAI-compatible and Anthropic Messages), no vendor gem,
model ids as configuration rather than constants. A forker brings OpenAI, Anthropic, Ollama or
nothing, and the app works in all four cases.

**Order.** P0 aligns the read API and ships a better omnibox, paying for itself even if nothing
follows. P1 is the whole pipeline on one question. P1.5 adds the second dialect, for the forker.
P2 serves the same registry over MCP. P3 measures before deciding on BAML. P4 adds one write. P5
is blocked until a report is named that no existing screen gives.

**Still undecided:** whether to lift the prescriptive-language ban (recommendation: no), BAML
(decide with a measured failure rate), chat history (a slot, not a transcript), assistant memory
(propose→confirm or not at all), and the UI name.

## Settled so far

| | Decision | Where |
|---|---|---|
| 1 | Its own bounded context, `Assistant::`, a customer with no privileges | §2 |
| 2 | Containment is enforced by greppable checks, not intentions | §2 C3/C4 |
| 3 | Capabilities wrap existing `Queries::*` — never a read-only DB grant, never generated SQL | §3 |
| 4 | Writes touch preferences only, never the book of record, always propose→confirm | §3.2, §4 G7 |
| 5 | Cards render before prose; the LLM is optional by construction | §1, §5 |
| 6 | Model routing maps **roles**, never hardcoded ids | §5 |
| 7 | Two wire dialects (OpenAI-compatible + Anthropic Messages) behind one port | §6 |
| 8 | No `openai` or `anthropic` gem; own the adapters | §6 |
| 9 | MCP is a transport over the registry, not the contract; assistant calls in process | §1, §8 Q6 |
| 10 | The record is persisted in Postgres; what is stored and what is sent are separate | §7.1 |
| 11 | Composition runs in a job and appends to the row; the channel only delivers | §7.2 |
| 12 | Every end-to-end gap has a decision and a phase; three are contract, not runtime | §11 |

Still open: §8 (Q1 prescriptive language · Q2 BAML · Q3 history · Q4 memory · Q5 UI name).

---

## 1. The shape, in one paragraph

You type a question. A **planner** (cheap model, no streaming) turns it into a list of capability
calls from a fixed registry. Rails **executes** them — real queries, real numbers, real
provenance. The results render as cards immediately. A **composer** (streaming model) then writes
a paragraph *about the retrieved context only*, with a source chip on every claim. Write actions
never execute: they render as a confirmation card you click.

**Contract and transport are different things.** The registry is the contract: a Ruby object per
capability, and the rule that nothing outside it can ever be called (G2, C4). MCP is one
*transport* over that contract, for external clients. The in-app assistant calls the registry in
process; it does not speak the protocol to itself. Crossing a process boundary to reach an object
in the same process buys no guarantee the contract does not already give, and costs a running
process a self-hoster has to keep alive.

---

## 2. Containment — how it never owns the product

This is the part that matters most, so it is stated as rules a script can check, not as
intentions.

| # | Rule | How it is enforced |
|---|---|---|
| C1 | The assistant is a **new bounded context**, `Assistant::`. It adds no code to the existing six. | Directory boundary |
| C2 | It is a **customer with no privileges** (ADR-002 pattern, same as Alerts→Trading in ADR-025). It reads suppliers through `Queries::*` and public use cases. No AR model of another context, no gateway. | `bin/checks boundaries`, extended |
| C3 | **Nothing in the six existing contexts may reference `Assistant::`.** The dependency is one-directional and the product is whole without it. | New check: grep for `Assistant::` outside its own tree |
| C4 | **The assistant writes nothing but its own record.** Under `app/contexts/assistant/`, the only writable models are `AssistantConversation` and `AssistantMessage` — its own log, infrastructure in the sense `SystemLog` and `AuditLog` already are. Every domain write happens by calling an existing use case from the confirmation path, which lives in a controller, not in the context. | New check: `assistant-no-writes`, with those two models allowlisted |
| C5 | **One entry point in the UI.** The omnibox. If a change requires editing `market/show` or the dashboard, the design is wrong. | Review |
| C6 | **Unconfigured is the default.** No `Integration` row → the context is inert and every surface degrades to what exists today. The suite passes with the flag on and off. | Specs both ways |
| C7 | **The MCP surface and the registry are the same list.** MCP may not expose a capability the registry does not define, and the registry may not hold one MCP does not expose. | Parity spec over both lists |

C3 and C4 are the two that actually prevent capture, and both are greppable. Add them to
`script/checks/` in P0, **before** the first line of assistant code — a check written afterwards
only ratifies what was already built.

---

## 3. Capability catalogue

The registry is the product. Everything else is plumbing.

Each capability is a Ruby object with: a stable name, a typed input, a typed output, the supplier
it reads through, and a provenance stamp (source + `as_of`). It wraps something that already
exists; a capability that needs new domain logic is a smell.

**Not a read-only database connection, and not generated SQL.** The domain's meaning lives in
Ruby, not in the schema: FX captured at execution, FX-weighted cost basis, split adjustments and
fee handling are `Position`, `GainLoss` and `FxRateResolver`, none of which a `SELECT` can see. A
model writing its own SQL would reimplement the product's most important rule badly and return a
number that is plausible and wrong — the worst failure mode a money app has. Raw SQL also erases
ADR-016 provenance, bypasses every ADR-002 boundary at once, and moves containment from a
greppable check to a Postgres grant. Open-ended analysis is served by **parameterised**
capabilities (period, grouping, metric — the P5 spec), and genuinely ad-hoc SQL belongs outside
the product: you, in `psql` or an editor, against the `bin/prod-sync` mirror.

### 3.1 Read — P1 subset marked ★

| Capability | Wraps | Returns |
|---|---|---|
| ★ `asset.lookup` | `Trading::UseCases::SearchCatalogue`, `MarketData::UseCases::SearchTickers` | symbol, name, type, currency, exchange |
| ★ `asset.snapshot` | `MarketData::Queries::AssetMarketContext`, `Domain::DayChange`, `FiftyTwoWeekRange` | price, day change, 52w range, `as_of` |
| ★ `asset.indicators` | `technical_readings`, `Queries::IndicatorSeries` | RSI, MAs, Bollinger, `calculated_at` |
| ★ `asset.observations` | `MarketData::Queries::NotableObservations` | persisted observations + their ADR-013 reading |
| ★ `asset.news` | `MarketData::Queries::RecentNews` | title, source, url, published_at — **quoted, never re-toned** |
| `asset.fundamentals` | `asset_fundamentals`, `Domain::FundamentalPresenter` | metric set + period label |
| `asset.statements` | `financial_statements` | one period, one statement type |
| `asset.earnings` | `MarketData::Queries::UpcomingEarnings` | next event, last surprise |
| `metric.definition` | `MarketData::Domain::MetricDefinitions` + `market.metricas.*` | the glossary entry, already written |
| `market.pulse` | `market_indices`, `Queries::CurrentFearGreed`, `MarketCalendar` | indices, sentiment, session state |
| `fx.rate` | `fx_rates`, `fx_rate_histories` | rate on a date, with source (Banxico) |
| `cetes.curve` | `cetes_rate_history`, `Queries::CetesReinvestedReturn` | auction curve, reinvested return |
| `portfolio.positions` | `Trading::Queries::OpenHoldings` | already returns plain hashes (ADR-025) — the cleanest fit in the repo |
| `portfolio.performance` | `portfolio_snapshots`, `UseCases::AssembleConsolidado` | period return, by currency |
| `portfolio.trades` | `UseCases::AssembleHistorial` | trade list for a window |
| `alerts.recent` | `alert_events` | what fired, when, on what rule |

### 3.2 Write — P4, every one of them propose→confirm

| Capability | Executes via | Why it is safe |
|---|---|---|
| `tracked.add` | `Administration::UseCases::Assets::EnsureListed` + `ResolveTrackedSymbolsJob` | Reversible, already batched and rate-limited |
| `watchlist.add` / `remove` | `Trading::UseCases::AddToWatchlist` / `RemoveFromWatchlist` | A preference |
| `alert.create` / `alert.pause` | `Alerts::UseCases::*` | A preference; the enum is closed so the intent is easy to validate |

### 3.3 Banned, permanently

`Trade` in any form (create, edit, delete) · `ImportTrades` / `UndoImport` ·
`ResetPortfolioData` · anything under `Administration` settings, integrations or users ·
anything that writes `Asset` identity columns (ADR-024 owner is Administration).

**The line:** the assistant may touch preferences. It may not touch the book of record. A bad
watchlist row is one click to undo; a bad trade corrupts cost basis, captured FX and every
snapshot after it.

---

## 4. The pipeline and its gates

A system prompt is not a guardrail, it is a request. These are the gates, and they are code.

| Gate | Where | What it does |
|---|---|---|
| G1 budget | before the planner | `Integration#budget_exhausted?` / `minute_budget_exhausted?` already exist. Exhausted → cards only, no prose, stated in the UI |
| G2 plan | planner output | The plan may only name capabilities in the registry. Unknown name → reject, do not re-prompt freely |
| G3 context | before the composer | Only what the executed capabilities returned enters the composing prompt. Nothing else, ever |
| G4 numbers | composer output | **A number not present in the context cannot appear in the output.** Testable: extract numerals from the output, assert membership. The composer is not allowed to derive — if a percentage is wanted, Ruby computes it and puts it in the context |
| G5 provenance | render | Every claim carries capability + `as_of`. No provenance → the sentence does not render |
| G6 silence | render | No data → say so. ADR-023 as UI. *"No hay notas de TSLA en 7 días"* is a correct answer |
| G7 action | write path | A write capability produces an **intent**, never an effect. The confirmation card is rendered from the resolved intent and the click calls the real use case |
| G8 injection | composer prompt | `news_article` text is third-party (Finnhub). It is delimited and labelled as data, never as instruction |

G4 is the one to build first: it is the only gate that can fail in a test, and it is the whole
claim of the feature.

---

## 5. Model routing — by role, never by hardcoded id

A table, not an inference: spending 2.5 s of floor latency to *decide* which model to use costs
more than it saves.

The table maps **roles**; the ids behind them are configuration. `claude-sonnet` means nothing to
someone running Ollama, and a hardcoded id is the single easiest way to make this feature
maintainer-only.

| Role | What it does | What it needs |
|---|---|---|
| `plan` | Classify intent, choose capabilities | Cheap, short output, never streams |
| `compose` | Write the paragraph over retrieved context | Fast first token — here the streaming *is* the feature |
| `code` (optional, later) | Explain repo code from a pasted file | Strong at code; never a default |

Both roles may point at the same id — a forker with one model configured must work.

**Defaults for a SheLLM instance**, documented as an example and not as a constant:
`plan → claude-haiku` (short output, so its streaming weakness never applies),
`compose → claude-sonnet` (first token at ~1.7 s), `code → codex` (carries ~13.5k tokens of its
own prompt, so never the default).

Measured floor on that instance: ~2.5 s/request, ~250 chars/s generation, 5 concurrent. Budget the
UI to that: plan ≈ 3 s, cards land, prose starts ≈ 1.7 s later. **The cards arriving before the
prose is what makes the wait tolerable and what makes the LLM optional.**

---

## 6. Providers — two directions, one port, no LLM gem

The MCP adapter and the LLM client get confused because both talk HTTP. They point opposite ways
and never overlap.

| Piece | Direction | What it is |
|---|---|---|
| LLM port + adapters | **outbound** — Stockerly calls | Faraday, one port, two dialects |
| Capability registry | internal | Plain Ruby objects. The single source |
| MCP adapter | **inbound** — Stockerly is called | Serves the registry to an external client |

### 6.1 One port, two adapters

A self-hoster may hold an OpenAI key, an Anthropic key, a local Ollama, or nothing. Anthropic's
own API does **not** speak `/v1/chat/completions` — it speaks `/v1/messages` — so a single wire
format would lock out exactly the forker who brings their own Anthropic key. The feature supports
both dialects.

This is the repo's existing shape, not a new one: `DataSourceRegistry` already puts eight gateways
behind one interface. The assistant gets a port — `complete(messages:, system:, role:, stream:)`
yielding chunks — and two concrete adapters.

| Adapter | Reaches |
|---|---|
| `OpenAiCompatible` | OpenAI, SheLLM (OpenAI format), Ollama, LM Studio, OpenRouter, LiteLLM, vLLM |
| `AnthropicMessages` | Anthropic's API, SheLLM (`/v1/messages`) |

Two adapters, essentially the whole ecosystem. What the port normalises is small and bounded —
**verify each row against current provider docs when implementing, they move**:

| | OpenAI-compatible | Anthropic Messages |
|---|---|---|
| Auth | `Authorization: Bearer` | `x-api-key` + a version header |
| System prompt | a `role: "system"` message | a top-level `system` field |
| Max tokens | optional | required |
| Response text | `choices[0].message.content` | `content[]` blocks |
| Stream events | deltas, terminated by a sentinel | typed events |
| Errors | `error.message` | `error.type` + message |

### 6.2 No `openai` or `anthropic` gem

The two dialects do not change this — they strengthen it. The gems do not remove the port (you
still normalise two response shapes into one), so they would replace two ~60-line Faraday adapters
that already share auth, base_url, SSE and error handling with two dependencies plus transitives
(ADR-019). They also assume their own service: validating model ids and sending vendor headers
actively gets in the way once `base_url` points at Ollama or SheLLM. The repo runs eight gateways
on this exact pattern, with `CircuitBreaker`, `RateLimiter`, `RetryPolicy` and `ApiKeyResolver` in
`app/shared/` — the adapters inherit all of it for free.

The one thing a gem would genuinely save is SSE handling, and that is a Faraday `on_data` callback
you want to own anyway, because it feeds a Turbo Stream.

### 6.3 Configuration and one boundary detail

**Configuration fits in what exists.** `Integration` already has `provider_name`,
`api_key_encrypted` and a jsonb `settings`: dialect, `base_url` and the id per role live there.
No migration. The dialect is chosen by the operator, not sniffed from the URL — detection is
fragile and a wrong guess fails in a way nobody can read.

**`PerformsRequests` is out of reach.** It lives in `market_data/gateways/`, so including it would
violate ADR-002. Duplicate the ~30 lines of Faraday assembly rather than promote it — three
repeated lines beat a premature abstraction. If a third context ever needs it, that is when it
moves to `app/shared/`.

**MCP's own SDK is a separate question**, and only matters at P2. If the Ruby SDK is not mature
enough, the cheap escape is a thin MCP shim in TypeScript that does nothing but HTTP to a JSON
endpoint over the same registry — it runs locally, ships in no production container, and keeps
Ruby clean. Verify before choosing; do not assume either way.

---

## 7. Surface — persistence, streaming, and the session

### 7.1 Record and context are different things

The same split as contract/transport, one layer up. **What is stored** and **what is sent to the
model** are separate decisions, and conflating them is what makes people choose localStorage.

- **Record:** every question and answer, persisted in Postgres. Always.
- **Context:** in v0, a last-symbol slot (Q3) — not the transcript.

You can keep everything and send almost nothing. Two Rails models, flat in `app/models/` like the
other 38: `AssistantConversation` and `AssistantMessage` (role, content, status, capability
results, token/latency stamps).

**localStorage is ruled out by the plan itself**, before taste enters: P1's Signal is "questions
asked in 14 days", and a number living in one browser's storage cannot answer it. Add the streaming
requirement in 7.2 and the phone/desktop split, and the server is the only place the record can
live.

### 7.2 Streaming: the row is the truth, the channel is only delivery

The premise to correct first: **closing the app closes the channel.** Action Cable has no buffer
and no replay — a socket that was shut does not catch up on reconnect. What actually survives a
closed tab is that the *work* ran server-side and wrote down its output as it went.

1. Question → `AssistantMessage` in `pending` → enqueue a job. Solid Queue is already running
   (`bin/jobs`).
2. The job executes the plan, persists the capability results, then streams the composition,
   **appending to the row** on a throttle (every ~300 ms, not per token — a 600-char answer is
   ~2.4 s, so ~8 updates).
3. Each flush also broadcasts a Turbo Stream. Action Cable is already wired here — Solid Cable
   runs in development for exactly this.
4. Reopen the app and the view renders **from the row**, finished or mid-flight, then subscribes
   for whatever is left.

The job is not only about surviving a closed tab. Production runs `WEB_CONCURRENCY=2` with
`RAILS_MAX_THREADS=5` — ten threads total — and holding one for the ~7 s of a full answer is a
bad trade for a surface that also has to survive a reload.

**Not push notifications.** `push_subscription` exists, but waking a phone for something that takes
seven seconds is noise. Revisit only if a capability ever takes minutes.

### 7.3 Clear

With a record, "clear" splits in two and only one of them is destructive:

- **New conversation** (the common one): start a new `AssistantConversation` and drop the context
  slot. Nothing is deleted; the Signal still counts.
- **Delete** (rare): actually removes rows. Worth having, but it is not the button you reach for
  daily, and it should not be the default meaning of the word on screen.

The context slot should also expire on its own — a pronoun resolved against something you asked
forty minutes ago is worse than no pronoun at all.

---

## 8. Open questions — recommendation attached, decision is Adrian's

**Q1 — Prescriptive language.** Lifting the personal-finance ban is free: ADR-001 already allows
*"Your NVDA position dropped 18% from average cost in MXN"* under Position state. Lifting the
**opinion/advice** ban is not: it is the fourth amendment to ADR-001, and ADR-014 already wrote
that two amendments in two days is what the loophole looks like from the inside.
*Recommendation: keep the prescriptive ban.* It is the only thing that distinguishes this product
from every other tracker with a chatbot bolted on, and "it refuses to tell you what to do, on
purpose" is a better interview answer than the opposite.

**Q2 — BAML.** Real appeal, real cost. It adds a DSL, a codegen step and a native runtime to a repo
whose ADR-019 says *the fewest vendors a self-hoster can inherit*, and which already carries one
second runtime (the Python bridge, ADR-017) and knows what that costs. Against 3–5 structured
functions, `ApplicationContract` + Dry::Validation + "return JSON" + one retry is most of BAML
already built and already tested here. Ruby support needs verifying before anything commits to it.
*Recommendation: not in P1. Instrument parse failures, and revisit in P3 with a number.* If the
failure rate is under a few percent, BAML is a dependency bought for a problem that never appeared.

**Q3 — Chat history.** Multi-turn re-sends the whole conversation every turn — quota and latency
for one benefit: pronouns (*"¿y AMD?"*). Cheaper: the planner receives a **last-symbol slot**, a
single string, not a transcript. That buys ~80% of the benefit for one field.
*Recommendation: no transcript in v0. One slot. Revisit only if you catch yourself wanting it.*

**Q4 — Assistant memory.** An auto-written memory in a money app can quietly inject stale context
into an answer, and it is the hardest thing here to debug. It should follow the rule the rest of
the design already follows: **the model proposes, you confirm.** A preferences record you can read
and edit, that the assistant may *suggest* additions to, is predictable; a memory it writes by
itself is not. *Recommendation: P6 at the earliest, propose→confirm, and only if a real repetition
shows up.*

**Q5 — Name.** "Analista" is a person who opines, which is the wrong promise under ADR-001 — and
ADR-001 explicitly governs section naming. Code namespace `Assistant::` is fine; the UI label is
open. Something closer to a verb than a role.

**Q6 — Does the in-app assistant speak MCP? (recommendation taken, recorded here)** The appeal is
one code path, so registry and MCP surface cannot drift. The cost is real: a process to run and
supervise, a transport to fail, auth to design, and — because the in-app assistant lives in
production — an MCP server exposed on the production host, which is exactly the new surface P2 was
shaped to avoid. Likely a third runtime too. The drift it protects against is cheaper to kill with
C7's parity spec than with a process hop. *Settled as: registry in process, MCP as an adapter over
it, parity enforced by a test.* If the purist version is wanted later, the registry is unchanged
and only the call site moves — this door does not close today.

---

## 9. Phases

Every phase carries the same six lines, because "controllable and measurable" is not a mood — it
is knowing beforehand what proves the phase worked and what would end it.

- **In** — what must be true to start.
- **Build** — the scope, closed.
- **Gate** — a command that answers pass/fail. No self-reports.
- **Usable** — what you can do afterwards that you could not before.
- **Signal** — the usage metric and its threshold. This is filter 3 of the discovery card, and it
  is what stops a learning project from quietly becoming an obligation.
- **Kill** — what is deleted and what survives if the phase is abandoned.

Instrumentation is free: `SystemLog` is infrastructure any context may write, so one row per
invocation gives every Signal below its number without new tables.

**P0 — Alignment. No assistant, no LLM.** The only phase whose output is not usable as a feature,
and the only one that must pay for itself anyway.

- **In:** nothing.
- **Build:** the two containment checks (C3, C4) with empty baselines, written *before* any
  assistant code exists. Normalise the `Queries::*` this will consume to return plain data plus an
  `as_of` stamp — `Trading::Queries::OpenHoldings` already does (ADR-025) and is the template.
  The capability contract carries all four of its properties from birth: `as_of`, the
  `DataFreshness` verdict, a `max_chars` budget it enforces itself, and an `ok` / `failed(reason)`
  result — never a silent empty (§11). Extend the omnibox (`SearchController` + `_dropdown`) to
  resolve symbols, glossary metrics and routes.
- **Gate:** `bin/checks` green with the two new ids · `bundle exec rspec` green · every normalised
  query has a spec asserting a plain-data return with `as_of` · a spec asserting a capability over
  its budget truncates rather than overflows · a spec asserting a failing supplier yields
  `failed(reason)`, not an empty success.
- **Usable:** search resolves metrics and routes, not just symbols. That ships on its own.
- **Signal:** none needed — this phase is justified by the refactor, not by the assistant.
- **Kill:** nothing to undo. The checks and the flatter read API are good on their own merits, and
  that is the test this phase had to pass.

**P1 — One question, end to end.**

- **In:** P0 green.
- **Build:** the LLM port with `OpenAiCompatible`, role routing (§5), `Integration` config. The ★
  read capabilities. Planner → execute → cards → streaming prose in a job that appends to the row
  (§7.2). Gates G1–G6, G8. One shape only: a single symbol. Plus the five runtime answers from
  §11: message timeout and sweep, the anchor-capability rule, es-MX fixed in the system prompt,
  one question in flight, signed stream names.
- **Gate:** a spec where the composer is fed a context and a number absent from it, and G4 rejects
  the output · the full suite green with **no** `Integration` row configured · the omnibox behaves
  exactly as P0 when the LLM is unreachable mid-stream · a spec where the job is killed mid-stream
  and the row ends `failed` with its cards intact · a spec where the anchor capability fails and
  nothing is composed.
- **Usable:** ask about one symbol and get cards in ~3 s, prose after.
- **Signal:** questions asked in 14 days. **Under 5 → stop here and keep P0.** That is a real
  outcome, not a failure: you built the thing and learned it.
- **Kill:** delete `app/contexts/assistant/` and the omnibox entry point. C3 guarantees nothing
  else references it, which is the whole reason C3 exists.

**P1.5 — The second dialect.** Its user is the forker, not you — stated plainly rather than dressed
up as your own use.

- **In:** P1's port shipped and exercised.
- **Build:** `AnthropicMessages` behind the same port.
- **Gate:** one spec running an identical request through both adapters against recorded responses,
  asserting an identical normalised result.
- **Usable:** an OpenAI key, an Anthropic key, Ollama or SheLLM all work. This is what makes the
  feature publishable instead of maintainer-only.
- **Signal:** none available — nobody is watching a fork. Justified by ADR-019, not by usage.
- **Kill:** delete one adapter; the port stays.

**P2 — MCP adapter.**

- **In:** the registry stable for a few weeks, so the surface is not moving while being exposed.
- **Build:** the MCP transport over the same registry, read-only, running locally against the
  `bin/prod-sync` mirror. The C7 parity spec.
- **Gate:** the parity spec (registry list == MCP list, both directions) · nothing new listening on
  the production host.
- **Usable:** Claude Desktop over your own data, with tool-calling you did not have to build.
- **Signal:** sessions opened against it in 30 days. **Zero → the question you imagined asking was
  not real.** Good to know cheaply.
- **Kill:** delete the adapter directory; the registry is untouched.

**P3 — Structure and shapes.**

- **In:** at least a few dozen logged invocations, or there is nothing to measure.
- **Build:** parse-failure instrumentation on the planner. The two-symbol comparison shape. Q2
  decided with the measured number.
- **Gate:** the parse-failure rate is a number on a dashboard, not an impression · the comparison
  shape has its own G4 spec.
- **Usable:** `nvda vs amd` — the answer no screen gives today.
- **Signal:** the parse-failure rate itself. **Under ~3% → BAML is a dependency for a problem that
  never appeared, and Q2 closes as no.**
- **Kill:** drop the comparison shape; the pipeline is unaffected.

**P4 — First write.**

- **In:** P1's Signal met, i.e. you actually use this.
- **Build:** `tracked.add` in batch, propose→confirm, G7. **One action, not a framework.**
  Anti-pattern #6 is the failure mode: five half-built actions and none exercised.
- **Gate:** a spec proving no write reaches the database without the confirmation click · `bin/checks
  assistant-no-writes` still green with an empty baseline, i.e. the write lives in the controller
  and not in the context.
- **Usable:** paste a messy list of tickers, confirm, done.
- **Signal:** times used versus the `/tracked` form over 30 days. **Losing to the form → do not
  build a second action.**
- **Kill:** delete the confirmation path; reads keep working.

**P5 — Reports. Blocked, on purpose.**

- **In:** one report named that `/portfolio`, Consolidado and Historial do not already give. Until
  that sentence exists, this phase does not start. If it never gets written, that is the answer.
- **Build:** spec-out, Ruby-executes — the LLM emits `{period, grouping, metric}` and never a number.
- **Gate:** the emitted spec is validated by a contract before execution; an invalid spec renders
  nothing.
- **Usable:** the report you named.
- **Signal:** run at least twice after the first time, or it was a one-off better served by `psql`.
- **Kill:** delete the spec contract and its capability.

**P6 — Memory, only if Q4 ever gets a yes.** Propose→confirm, like everything else here.

## 10. ADRs this needs

Written when its phase lands, not upfront.

- **P1 — "The assistant is an invoked surface."** Why generated prose does not contradict ADR-014's
  closed catalogue: the catalogue governs what the app says *on its own*, in its screens. The
  assistant speaks only when called, opt-in, with provenance visible. The distinction is
  invocation, and it needs writing down or it will be re-derived in an argument later.
- **P1 — "Provenance contract."** G3/G4/G5/G6 as a rule: nothing outside the retrieved context,
  and absence is an answer.
- **P1.5 — "Provider-agnostic by port."** Two dialects, no vendor gem, ids as configuration —
  ADR-019 applied to the LLM seam, so a forker is never asked to bring the maintainer's provider.
- **P4 — "The assistant is a customer with no privileges."** C2/C3/C4 as an ADR, so the checks have
  a reason attached.
- **Only if Q1 is lifted** — a fourth amendment to ADR-001. Its own decision, on its own day.

---

## 11. The end-to-end gaps, decided

Each one has an answer and a phase. A gap in a list with no owner is a gap that comes back.

**Three of them are not runtime problems at all — they are the capability contract**, so they
belong in P0 where the registry is born, not as patches in P1.

| Gap | Decision | Phase |
|---|---|---|
| Stale data stated confidently | Every capability output carries `as_of` **and** the `DataFreshness` verdict (`app/shared/domain/`, already built). The verdict enters the context as a written sentence and the card as a chip | P0, contract |
| Context budget | Each capability declares `max_chars` and truncates itself. The registry enforces it; the prompt never does | P0, contract |
| Partial capability failure | A capability returns `ok` or `failed(reason)` — never a silent empty. Failures stay out of the context (G3) and render as error cards | P0, contract |
| Zombie stream | Absolute timeout per message → `failed`, plus a 5-minute Solid Queue sweep for rows a dead process left behind. The view then shows the persisted cards and says the prose did not finish | P1 |
| Composing over a half-empty context | If the **anchor** capability fails (the one that identifies the subject, e.g. `asset.lookup`), nothing is composed — cards only. If accessory ones fail, compose over what arrived | P1 |
| Two languages in one answer | System prompt fixes es-MX. Headlines are quoted in English with their source and **never translated** (ADR-001, and the note in `_news.html.erb`). The paragraph may say what a story is about; it may not re-tone it | P1 |
| Concurrent asks | One question in flight per conversation; the input blocks. With a single user this costs nothing and removes a class of problem | P1 |
| Stream authorisation | Signed stream name per conversation — Turbo's default helper. Trivial, and free to get wrong | P1 |
| Valid but irrelevant plan | **No gate.** G2 checks existence, not fit. The plan chips are rendered, so a wrong plan is visible in ~3 s — one more reason the cards come first | by design |

**Two of these pay twice.** The zombie stream degrades to *cards only* — the same fallback as an
unconfigured LLM, so there is one failure mode in the UI rather than three. And `asset.news`
sending titles, source and date but **not** `summary` fixes the context budget and largely empties
G8 at the same time: third-party prose that never enters the prompt cannot carry an instruction.

**Honest about what is testable.** The freshness chip on the card is a spec that can fail. "The
paragraph did not omit the staleness" is not — you cannot assert an absence of omission. So the
guarantee lives in the card, and the context sentence is best effort. Do not claim otherwise.

---

## 12. Not building

A persona or avatar · fake "thinking" animation (the pipeline reads as true because it *is*) ·
general market knowledge from the model's own training · a transcript in v0 · a read-only database
grant or generated SQL · anything that writes a `Trade` · a chat surface anywhere except the
omnibox.
