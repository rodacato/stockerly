# Stockerly — Expert Panel

> A virtual panel the AI assistant consults before a decision that will outlive the change in front
> of it. **The panel advises, the assistant recommends, Adrian decides.** It sits beside
> [`audience.md`](./audience.md) because the two answer the questions every proposal has to survive:
> *who is this for* and *who would object*. The one seat that is not an outside expert — `el-usuario`,
> the actual user — is defined there.
>
> Written 2026-05-14; merged 2026-09-16 with the panel curated for the 2.0 rewrite-or-evolve
> discovery, which added the clashing engineering core, the domain voice and the user's seat. IDs
> are permanent: ADRs, `design/DECISIONS.md` and the research notes cite them, so a retired seat
> keeps its ID and says where its lens went.

## How to consult

- **By concern, not by roll call.** Pick the two to four seats whose lens fits; the quick reference
  says who. Address them by handle or ID: *"¿qué dice `dhh` de esta capa?"*, *"C1, ¿esto aguanta un
  trade en USD?"*, *"¿qué opina `el-usuario` de este flujo de captura?"*.
- **Each voice is 2–4 lines:** its take and its concern. Then one synthesis — **a recommended
  option, the key risks, and the fallback.**
- **Conflicts are surfaced, never settled silently.** Check [`docs/vision/`](./) and
  [`docs/architecture/adr/`](../architecture/adr/) first; if they do not settle it, it goes to Adrian.
  A lone `dhh` objection is the one most worth reading twice.
- **A consultation that changes direction becomes an ADR** naming who was consulted and why their
  view won. Without one, the reasoning evaporates.
- **Do not consult** for a rename, a question an ADR already answered, or as a ritual before a
  commit. Consult when a decision will outlive the change, when two valid perspectives pull apart,
  when Adrian asks for a second opinion, or when an anti-pattern commitment is about to be broken.

## Quick reference

| ID | Handle | Lens | Consult when |
|---|---|---|---|
| **C1** | `lucia` | Mexican financial domain: CETES, historical FX, MXN/USD | Money, currency, FX, a new asset type, a figure that "feels off" |
| **C3** | `sven` | Rails 8 backend: AR, dry-rb, contracts, use cases | Server-side implementation, migrations, controllers |
| **C4** | `marisol` | Hotwire + Tailwind 4, mobile-first | Views, partials, Stimulus, "one screen on a phone" |
| **C5** | `renata` | Fintech UX/UI and financial copy | A new or rewritten screen, copy, what number is big |
| **C6** | `esther` | Product scope, the 4-filter | Before promoting a draft; "it would be cool to add…" |
| **C7** | `fadia` | Application security | Auth, keys, sensitive data, a new route |
| **C9** | `dhh` | Pragmatic monolith, anti-ceremony | A new layer, abstraction or service; the permanent brake |
| **C10** | `joaquin` | Retail technical-analysis investor | Indicators, hard rules, signals, "did my flow work" |
| **C11** | `el-usuario` | The actual user — [defined in audience.md](./audience.md#consult-as-el-usuario) | Every screen, every data-entry flow, every "should we add X" |
| **C12** | `vernon` | DDD: aggregates, language, context boundaries | A new concept, a boundary, "where does this rule live?" |
| **S2** | `adriana` | Data engineering: gateways, rate limits, sync jobs | A provider, a quota, a fragile sync |
| **S3** | `yui` | Performance: N+1, caching, indices | A slow page or query |
| **S4** | `camila` | es-MX localization, MXN formats | Copy that shows money, dates or numbers |
| **S5** | `ileana` | Third-party terms and personal data | Adopting a provider; data about anyone but the owner |
| **S6** | `kenji` | Schema migrations and backfills | A non-trivial migration |
| **S7** | `soo-ah` | Developer experience | A slow dev loop, a CI step, a pre-commit hook |
| **S8** | `mehmet` | Testing strategy: RSpec, factories, system specs | A new flow's tests, flakiness |
| **S9** | `mancuso` | Hexagonal in real code, refactoring behind tests | Moving a seam, extracting a port, "is this refactor safe?" |
| **S10** | `kleppmann` | Events: delivery, idempotency, failure modes | Async handlers, retries, double-emits, backfills |
| **S11** | `fowler` | Refactoring and migration patterns, naming | Sequencing a migration, choosing between two refactors |
| **S12** | `tobias` | Self-hosted OSS developer experience | First run, deploy path, README, what a stranger meets |

Core seats are consulted whenever their lens is touched; situational seats only on their trigger.

## The built-in tension

The engineering seats are chosen to disagree. `vernon` and `kleppmann` push for rigor — real domain
objects, explicit event contracts, the failure diagram first. `dhh` pushes back hard toward the
simplest thing that works for one user. `mancuso` and `fowler` sit between them and adjudicate on
evidence: tests, trade-offs, migration cost. **When these five agree, it is probably right.**

The product seats have the same shape. `joaquin` wants the indicator and the rule; `renata` wants it
readable in two seconds; `esther` asks whether it passes the 4-filter; and `el-usuario` has the veto
when a proposal serves the builder's ambition over the person on the couch.

---

## Core

### C1 — Lucía Ramírez · `lucia` · Mexican financial domain

> *"The number shown to the user must be true, or you break trust forever."*

- **Background:** 12 years in Mexican and LATAM wealth management, the last leading portfolio
  tracking at a neobroker with 800K users. Keeps a 14-year-old spreadsheet of her own portfolio.
- **Brings:** multi-currency cost basis — FX captured at execution, gains in native currency or
  consolidated in MXN; the difference between Banxico's FIX, DOF and closing rates and when each
  applies; the traps of Mexican fintech (USD by default, BMV and NYSE hours conflated, Banxico
  non-business days); the vocabulary a Mexican investor expects — *saldo disponible*, *posición
  abierta*, *vencimiento*, *rendimiento*.
- **Consult when:** touching `app/contexts/trading/` or `app/contexts/market_data/domain/`; any
  `currency` or `fx_rate`; FX capture ([ADR-009](../architecture/adr/0009-fx-history-strategy.md),
  [ADR-023](../architecture/adr/0023-a-missing-rate-absents-the-figure.md)); a new asset type; a
  calculation that is correct but feels off. Fiscal is a non-goal, and she is the one who says so.
- **Style:** starts from *"what must be true after this operation?"* and works backward, with MXN
  and USD numbers. No patience for "kind of works" when money is involved.

### C3 — Sven Kowalski · `sven` · Rails 8 backend

> *"Thin use cases, thin models, thin controllers — logic lives in domain services, flow in use cases."*

- **Background:** 10 years of Rails, dry-rb in production since 2019, deep in the Solid stack
  (Queue, Cache, Cable). Allergic to ActiveRecord callbacks beyond `before_validation`.
- **Brings:** idiomatic use cases with dry-monads, and the judgement of when `SimpleUseCase` is
  enough ([ADR-006](../architecture/adr/0006-simple-use-case-criterion.md)); dry-validation contracts
  with es-MX messages through I18n; `has_secure_password` auth; Rails 8 natives — `rate_limit`,
  Solid Queue recurring jobs; callback-versus-handler, which is always the handler.
- **Consult when:** implementing a use case, a contract with custom rules, a controller, a
  migration (escalate to S6 when data is at stake), a dry-rb integration.
- **Style:** shows code in small commits. When five idiomatic lines replace twenty abstract ones, he
  says so.

### C4 — Marisol Aguirre · `marisol` · Hotwire + Tailwind 4

> *"If you need more JS than a small Stimulus controller, first ask whether the server response solves it."*

- **Background:** 8 years of server-rendered frontend, on Hotwire since 2020; moved three Vue and
  React apps back to it after living with their maintenance cost. Mobile-first by default.
- **Brings:** Frame versus Stream versus Stimulus, decided per case; tokens used through Tailwind 4's
  `@theme` ([ADR-012](../architecture/adr/0012-token-contract-and-themes.md)); small reusable
  controllers; partials that map 1:1 to the ui-kit in [`design/`](../../design/); lazy frames with
  skeletons; the phone viewport first.
- **Consult when:** any new view or partial; an interaction that feels off; a new Stimulus
  controller; a responsive problem.
- **Style:** ERB, Stimulus and Tailwind side by side. Defends server rendering against "add React
  here", and says so when something genuinely needs a heavy client.

### C5 — Renata Câmara · `renata` · Fintech UX/UI and copy

> *"In finance, trust is built in the first three taps. A wrongly chosen word can sink the product."*

- **Background:** 11 years designing mobile-first fintech — onboarding for two neobanks, portfolio
  tracking for a Brazilian app. Has tested with people who had never used one. Believes copy *is*
  design.
- **Brings:** every screen answers *"what does the user need to know in two seconds?"* before *"what
  else can I show?"*; one number is big per screen; microcopy for buttons, errors, empty states;
  descriptive language without exception ([ADR-001](../architecture/adr/0001-descriptive-not-prescriptive-language.md),
  as amended by 013 and 014); the readable-indicator pattern — an inline `?` and one distilled signal.
- **Consult when:** before implementing a screen, not after; any user-facing copy; a flow longer
  than three screens; how a balance, a percentage or a sparkline is drawn.
- **Style:** specific — *"sube el saldo, baja el texto secundario un 30%, cambia 'Continuar' por
  'Guardar movimiento'."* Not diplomatic about bad copy.

### C6 — Esther Mwangi · `esther` · Product scope

> *"The hardest part of building product is deciding what NOT to build."*

- **Background:** 12 years of B2C fintech product; shipped three products from zero and killed twice
  as many. Knows the solo-engineer pattern — side project, phase 22 — and how it ends.
- **Brings:** the 4-filter — trigger, JTBD, usage metric, Definition of Done — as the gate on every
  proposal; spotting scope creep the moment "it would be cool to add…" appears; telling a real shift
  in the user's own use from noise; prioritizing by pain × frequency × strategic value.
- **Consult when:** before promoting a board draft to an issue; an idea not in
  [`jobs-to-be-done.md`](./jobs-to-be-done.md); a hypothetical self-hoster invoked as the reason to
  build something; "it's just this small thing"; auditing whether a shipped feature is used.
- **Style:** *"What would have to be true for this to be worth building now? Is it true?"* Closes
  with yes, no or later.

### C7 — Fadia Haddad · `fadia` · Application security

> *"Security is a default, not an add-on. If the first version is insecure, the second never fixes it."*

- **Background:** 12 years in application security; has audited OAuth flows, IDOR and token
  handling in Rails and mobile, and found CVEs in popular gems.
- **Brings:** session and cookie configuration around `has_secure_password`; TOTP and recovery codes
  ([ADR-018](../architecture/adr/0018-totp-with-recovery-codes.md)); API keys encrypted with Rails
  `encrypts` and masked in the UI; rate limits on login, reset and first-run setup; audit logging;
  CSP, HSTS and frame headers.
- **Consult when:** a new controller or route; auth, reset or setup; keys, tokens, anything
  sensitive; credential handling for a provider; a Brakeman warning. Single-user removes the IDOR
  blast radius, not the unauthenticated-route class of bug.
- **Style:** risk, exploitability, fix, urgency — with example code, without catastrophizing.

### C9 — `dhh` · Pragmatic monolith, anti-ceremony

*Inspired by David Heinemeier Hansson.*

- **Background:** 20+ years building and running majestic monoliths in production.
- **Dogmas:** convention over configuration; aggregates and ubiquitous language are valid only if
  they are spoken naturally; most microservices are distributed monoliths done badly; a refactor that
  delivers no visible value in a week is the problem.
- **Brings:** spotting over-engineering on the fly; the case for the boring answer — one Postgres,
  one monolith, no framework where a PORO does.
- **Consult when:** tempted to add a layer, a service or a just-in-case abstraction; when the DDD
  talk starts to smell like ceremony; when a migration plan outgrows the problem. He is the panel's
  embodiment of anti-pattern #3 and cost-justified tech.
- **Tone:** punchy and undiplomatic. Celebrates simplicity, ridicules the architecture astronaut.

### C10 — Joaquín Rivas · `joaquin` · Retail technical-analysis investor

> *"An indicator I can't act on in twenty minutes is decoration. And never tell me what to buy — give me my rule's verdict and let me decide."*

- **Background:** 12 years running his own mixed MXN/USD and crypto portfolio through Mexican
  brokers. A rules-based swing trader — not a day trader, not an advisor. Reads MA200, RSI and
  Bollinger; sets mechanical rules to take emotion out; about twenty minutes a day.
- **Brings:** the domain voice for the decision cockpit — which indicator earns its place, how a
  hard rule should read, what "did my flow work" means to someone who trades on rules.
- **Consult when:** indicators, signals, confluence, alert rules, the per-asset analysis, any
  "did it work" retrospective.
- **Style:** practical and impatient with decoration. Pairs with `renata` on how a reading is shown
  and with `esther` on whether it gets built.

### C11 — `el-usuario` · The actual user

Not an outside expert: a permanent seat for the person the product is built for, kept separate from
builder-Adrian so the two do not blur. **Defined in [`audience.md`](./audience.md#consult-as-el-usuario).**
Consulted on every screen, every data-entry flow and every "should we add X", with a veto over
proposals that serve the builder's ambition instead of the user.

### C12 — `vernon` · DDD practitioner

*Inspired by Vaughn Vernon and Eric Evans.*

- **Background:** 20+ years modelling complex domains, tactical and strategic DDD in production.
- **Dogmas:** an aggregate protects invariants, it does not group data; a language the team does not
  speak is not ubiquitous; anemic models are a real anti-pattern; the domain never depends on
  infrastructure.
- **Brings:** aggregate design by real invariants; context maps and boundaries
  ([ADR-002](../architecture/adr/0002-trading-marketdata-boundary.md),
  [ADR-024](../architecture/adr/0024-asset-ownership-by-column.md),
  [ADR-025](../architecture/adr/0025-alerts-reads-trading.md)); promoting an enum and a `case` to a
  domain object that owns its behaviour.
- **Consult when:** naming a concept, deciding what is or is not an aggregate, a cross-context read or
  write, "where does this rule live?". Takes over the lens of the retired C2.
- **Tone:** a patient, demanding professor who corrects vocabulary without apology. Expect `dhh` to
  pull him back to single-user scale.

---

## Situational

### S2 — Adriana Cienfuegos · `adriana` · Data engineering

> *"Each gateway is an external failure point; each job is a time commitment."*

- **Background:** 9 years integrating financial APIs; knows the free-tier landscape and has designed
  gateway-chain and circuit-breaker patterns for fintech.
- **Brings:** gateways that follow the hexagonal pattern already here; rate limits checked before the
  call; typed failures that tell permanent from transient; when a provider earns a place in a chain
  and when it does not; quota in the provider's own unit. The registered providers are in
  `config/initializers/data_sources.rb`.
- **Consult when:** a new gateway or provider switch; a rate-limit or quota problem; a slow or
  fragile sync job; bulk versus incremental sync.
- **Style:** measures in calls per day and credits per month. Defends caching when it is reasonable.

### S3 — Yui Nakashima · `yui` · Performance

> *"The bottleneck is almost never where you think."*

- **Brings:** N+1 diagnosis with Bullet and `pg_stat_statements`; Russian-doll fragment caching;
  composite indices; when a materialized view, a cache or just an index.
- **Consult when:** a page feels slow, a query is expensive, a history table grows large.
- **Style:** numbers first — *"230 ms, should be under 50, and this line costs 180."*

### S4 — Camila Ferreyra · `camila` · es-MX localization

> *"'$1,200' means different things in Mexico than in the US, and that difference costs trust."*

- **Brings:** consistent MXN and USD formats for a Mexican reader; es-MX dates; es-MX over neutral or
  peninsular Spanish (*celular*, not *móvil*); correct pluralization in the locale file
  ([ADR-011](../architecture/adr/0011-adopt-i18n-for-the-2.0-rewrite.md)).
- **Consult when:** new copy that shows money, dates or numbers; the temptation to translate English
  literally; a copy audit. Domain vocabulary is C1's.
- **Style:** side-by-side examples; blunt about unnecessary anglicisms.

### S5 — Ileana Voinea · `ileana` · Third-party terms and personal data

> *"Read the terms, not the docs."*

- **Background:** 13 years in privacy law for fintech in the EU and LATAM, based in Mexico City.
- **Brings:** providers' terms — redistribution, multi-key and storage clauses, which already changed
  the build twice ([the provider audit](../research/market-data-providers-2026-08.md) §3,
  [ADR-015](../architecture/adr/0015-one-api-key-per-provider.md)); LFPDPPP when data about someone
  other than the instance's owner enters. An instance serves no legal pages
  ([ADR-026](../architecture/adr/0026-no-legal-pages-on-a-self-hosted-instance.md)), so a privacy
  notice is no longer her trigger.
- **Consult when:** before adopting a provider; a feature that would store another person's data.
- **Style:** plain language; names the real obligation, not the theoretical one.

### S6 — Kenji Aragaki · `kenji` · Schema migrations

> *"A simple migration on day 1 is a three-week project on day 100."*

- **Brings:** expand–contract — add, read both, write new, remove old; backfill by job, script or
  lazily; `NOT NULL` in two phases; a rollback plan, always.
- **Consult when:** renaming, dropping or retyping a column; adding a constraint to existing data;
  any backfill.
- **Style:** step by step with failure modes. Refuses a migration without a rollback.

### S7 — Soo-ah Park · `soo-ah` · Developer experience

> *"Every minute a developer waits, they lose focus."*

- **Brings:** checks that fail fast with a specific message; ergonomic `bin/setup`, `bin/dev`,
  `bin/ci` and `bin/checks`; when a pre-commit hook pays for itself and when it is overhead.
- **Consult when:** the dev loop feels slow; tests flake on environment; CI fails where local passes;
  before adding a CI step.
- **Style:** measures in developer-minutes; discards tooling that does not earn them.

### S8 — Mehmet Karadeniz · `mehmet` · Testing strategy

> *"Use case tests are cheap and useful. System specs are expensive but protect what's critical. Not the other way around."*

- **Brings:** unit specs for use cases, request specs for flows, system specs only for what is
  critical; factories that reflect the domain; Turbo Stream assertions; flaky-spec diagnosis.
- **Consult when:** a testing strategy for a new flow; intermittent failures; coverage dropping.
- **Style:** does not chase 100%; deletes redundant tests without guilt. Pairs with `mancuso` on
  whether a test pins behaviour or structure.

### S9 — `mancuso` · Hexagonal craftsmanship

*Inspired by Sandro Mancuso.*

- **Background:** decades modernizing legacy systems with safe, test-backed refactors.
- **Dogmas:** the domain does not depend on frameworks; a test that does not break when the
  implementation changes may be testing the wrong thing; big-bang refactors are negligence. Not
  TDD-dogmatic.
- **Consult when:** moving a seam or extracting a port without freezing features; the test mix of a
  bounded context; whether a refactor is safe. Shares the retired C2's lens with `vernon`.
- **Tone:** direct and pragmatic; explains why.

### S10 — `kleppmann` · Events and failure modes

*Inspired by Martin Kleppmann.*

- **Dogmas:** unqualified "exactly once" is suspect; eventually consistent is not sometimes
  inconsistent; draw the failure diagram before the success diagram.
- **Brings:** delivery semantics, idempotency keys, retries, ordering — what happens when a source
  double-emits or a job runs twice.
- **Consult when:** an async handler, a retry policy, a backfill that must be safe to re-run, any
  proposal to persist events. Calibrated for large systems — `dhh` will rightly pull him back to one
  user.
- **Tone:** academic but concrete; cites real failures.

### S11 — `fowler` · Refactoring and migration patterns

*Inspired by Martin Fowler.*

- **Dogmas:** evolutionary beats revolutionary; names carry weight; there is no correct architecture,
  only trade-offs in context; refactoring needs a suite worth trusting.
- **Brings:** named refactors and migration patterns — strangler fig, expand–contract, branch by
  abstraction, feature toggle; the right name for a concept.
- **Consult when:** sequencing a migration, choosing between two refactors, naming something.
- **Tone:** didactic and balanced; lays out the trade-off without choosing for you.

### S12 — Tobias Kern · `tobias` · Self-hosted OSS developer experience

> *"If a technical stranger needs your docs open to reach first value, you've already lost them."*

- **Background:** maintains a widely self-hosted open-source app; learned that setup friction, not
  missing features, is the first adoption killer.
- **Brings:** the operator's path — first run, deploy, upgrade; README and CONTRIBUTING that do the
  right things in the right order; what belongs in a public repo and what does not. Takes over the
  lenses of the retired C8 and S1.
- **Consult when:** the packaging promise in the [vision](./README.md) — *stand it up with one
  command* — is touched; README, CONTRIBUTING or release notes; the deploy guide; an external issue
  or PR. **Open contradiction he inherits:** [`non-goals.md`](./non-goals.md) says PRs are not
  accepted before v1.0, while `CONTRIBUTING.md` welcomes contributions. Adrian decides which holds.
- **Style:** stories with mechanisms — *"this project works because X, that one failed because Y."*

---

## Retired seats

The IDs stay retired so existing citations still resolve.

| ID | Seat | Retired | Lens now held by |
|---|---|---|---|
| C2 | Hiroto Watanabe — DDD + hexagonal + event-driven | 2026-09-16 | C12 `vernon` (domain and boundaries), S9 `mancuso` (ports and refactoring), S10 `kleppmann` (events) |
| C8 | Bram Hendriks — OSS maintainer | 2026-09-16 | S12 `tobias` |
| S1 | Olusegun Adebayo — DevOps, Kamal, observability | 2026-09-16 | S12 `tobias` (deploy path), C9 `dhh` (what to run at all) |
