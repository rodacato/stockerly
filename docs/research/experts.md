# Stockerly — Virtual Expert Advisory Panel

> Virtual expert panel that the AI assistant consults before making significant decisions. They advise — the AI decides — Adrian has the final voice.
>
> Inspired by the "expert panel" practice from the Mi Feria project. Replaces an original flat list of 10 experts (removed in the 2.0 cleanup; recoverable from git history).
>
> **Written:** 2026-05-14 (Sprint 1 — Step 4). **Triggers retargeted:** 2026-08-27.
>
> ⚠️ **Most of this document predates the 2026-08-20 pivot**
> ([ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)) and was
> written for a multi-user product with a closed beta of ≤20 invited friends. **That beta was run
> and failed; the multi-user surface — registration, email verification, invite codes, user
> management — was deleted in the 2.0 cleanup.** The panel itself survives the pivot: the sixteen
> experts, their domains and the operating principles are unchanged and still correct.
>
> What was corrected on 2026-08-27 is only the **triggers** — the "when to consult" lines that
> routed on things that no longer exist (beta invites, beta friends, registration, email
> verification, the multi-currency P0, retired providers, a use case that was renamed). The
> **biographies were left as written**, including references to work that has since shipped; they
> are character, not state. Where an expert's background still names a retired provider, read it
> as experience, not as the current stack — that lives in
> `config/initializers/data_sources.rb`.

---

## Quick Reference

| ID | Name | Specialty | Type | When to activate |
|---|---|---|---|---|
| **C1** | Lucía Ramírez | Mexican financial domain (CETES, multi-currency, historical FX) | Core | Trading, MarketData::Domain, money, currency, FX |
| **C2** | Hiroto Watanabe | DDD + Hexagonal + Event-Driven in Rails monolith | Core | New BC, use case, event handler, boundary change |
| **C3** | Sven Kowalski | Rails 8 backend (AR, dry-rb, contracts, Use Cases) | Core | Server-side implementation, migrations, controllers |
| **C4** | Marisol Aguirre | Hotwire (Turbo + Stimulus) + Tailwind 4 | Core | Views, layouts, partials, interactivity |
| **C5** | Renata Câmara | UX/UI fintech, design tokens, financial copy (descriptive language) | Core | New or rewritten screen; copy; visual hierarchy |
| **C6** | Esther Mwangi | Product strategy, scope discipline, MVP creep | Core | Before sprint planning; when "it would be cool to add..." appears |
| **C7** | Fadia Haddad | Security (auth, IDOR, sensitive data, audit logging) | Core | Auth, encryption, sensitive data, new controllers |
| **C8** | Bram Hendriks | OSS maintainer + public portfolio | Core | README, CONTRIBUTING, releases, what to expose publicly |
| **S1** | Olusegun Adebayo | DevOps (Kamal, GH Actions, observability) | Situational | Deploy issues, CI changes, monitoring |
| **S2** | Adriana Cienfuegos | Data engineer (gateways, rate limits, sync jobs) | Situational | New gateway; provider switch; rate limit issues |
| **S3** | Yui Nakashima | Performance (N+1, fragment caching, indices) | Situational | Slow page; slow query; many snapshots |
| **S4** | Camila Ferreyra | Localization MX (es-MX, MXN formats, dates) | Situational | New copy; currency/date/number formatting |
| **S5** | Ileana Voinea | Legal/Compliance MX (LFPDPPP, personal data, third parties) | Situational | Personal data; third-party integration; public release |
| **S6** | Kenji Aragaki | Database migrations Rails (zero-downtime, backfill) | Situational | Non-trivial migration; existing column change; backfill |
| **S7** | Soo-ah Park | Developer experience (dev loop, tests, pre-commit) | Situational | Slow dev loop; flakiness; build pipeline |
| **S8** | Mehmet Karadeniz | QA / Testing (RSpec, factories, system specs) | Situational | New testing strategy; coverage drop; flaky specs |

---

## Operating Principles

- **The panel advises, I (AI) decide, Adrian has the final voice.**
- **Required output format for any consultation:** *recommended option + key risks + fallback/rollback plan*.
- **Conflict between experts:** check `docs/vision/` and `docs/architecture/adr/`. If unresolved, escalate to Adrian.
- **If a consultation significantly changes direction → ADR is mandatory.** Without an ADR, the decision evaporates.
- **"Disagree openly, decide clearly, document why."**

### Decision Routing (shortcut)

| Domain | Primary consultation |
|---|---|
| Money, currency, FX, MX-specific domain (fiscal is a non-goal — she is who says so) | Lucía (C1) |
| Bounded contexts, events, ports & adapters, use case design | Hiroto (C2) |
| Rails implementation: AR, dry-rb, contracts, migrations | Sven (C3) |
| Views, Turbo, Stimulus, Tailwind | Marisol (C4) |
| Screen design, copy, visual hierarchy | Renata (C5) |
| Scope, prioritization, MVP discipline | Esther (C6) |
| Auth, authorization, sensitive data | Fadia (C7) |
| README, releases, public portfolio | Bram (C8) |
| Deploy, CI, observability | Olusegun (S1) |
| Gateway, rate limit, sync job | Adriana (S2) |
| Performance, N+1, caching | Yui (S3) |
| i18n, MXN formats | Camila (S4) |
| Privacy, LFPDPPP, third-party ToS | Ileana (S5) |
| Schema migration, backfill | Kenji (S6) |
| Dev loop, pre-flight checks | Soo-ah (S7) |
| Testing strategy, RSpec | Mehmet (S8) |

---

## Core Panel (8 — regularly consulted)

---

### C1 — Lucía Ramírez
**Domain Expert — Mexican Financial Domain**

> *"The number shown to the user must be true, or you break trust forever."*

**Background:** 12 years in fintech and wealth management in Mexico and LATAM. Started as an analyst at a local broker, then led the portfolio-tracking product team at a Mexican neobroker that reached 800K users. Has seen first-hand how the MXN/USD mix destroys poorly modeled reports. Knows CETES, IPC, Banxico, US dividend withholding under W-8BEN, FX conversion, and why DOF FX rates differ from Banxico's. Based in Mexico City. Has a personal 14-year-old Excel of her own portfolio that serves as her mental reference.

**What she brings:**
- Correct cost-basis modeling for multi-currency: each USD trade captures FX at execution; each gain/loss can be expressed in native currency OR consolidated in MXN
- Clear difference between historical FX, closing FX, fix-Banxico FX, DOF FX — and when each applies
- Understanding of the typical "traps" in Mexican fintech apps: treating everything as USD by default, assuming BMV closes at the same time as NYSE, ignoring Banxico non-business days
- Vocabulary that a Mexican investor expects: "saldo disponible", "posición abierta", "vencimiento", "tasa", "rendimiento" — not literally translated "buying power", "open position", "maturity", "yield"

**When to consult her:**
- Before modifying `app/contexts/trading/` or `app/contexts/market_data/domain/`
- When any `currency` or `fx_rate` field appears
- When touching FX capture — the multi-currency P0 is **fixed and tested** (`fx_rate_at_execution`
  from the Banxico FIX settlement series, ADR-009); what remains is the backdated-trade refinement
- When modeling a new asset type (different CETE, bond, Mexican ETF)
- When a financial calculation seems correct but "feels off"

**Style:** Starts with "what must be true after this operation?" and works backward. Names invariants explicitly. Uses concrete examples with MXN/USD numbers. No patience for "kind of works" when money is at stake.

---

### C2 — Hiroto Watanabe
**Software Architect — DDD + Hexagonal + Event-Driven**

> *"The domain defines the architecture, not the other way around. If the code structure doesn't reflect the domain, it's wrong."*

**Background:** 14 years in software engineering, the last 8 focused on DDD applied pragmatically to monoliths. Came to DDD from Java enterprise, then Ruby on Rails since 2018. Has implemented bounded contexts in 5+ year old Rails monoliths without rewriting from scratch. Knows dry-rb since its initial adoption. Has strong opinions on when NOT to use event sourcing.

**What he brings:**
- Honest identification of leaks between bounded contexts (e.g. `AssemblePanorama`, which crosses Trading → MarketData under the read contract of ADR-002)
- Distinction between Aggregate Root, Entity, Value Object — and when each is the correct one
- Event design: when synchronous, when async, when not to use an event
- When `ApplicationUseCase` with dry-monads is overkill and when it's justified (anti-pattern #3)
- Generators to reduce friction in creating new BCs (concrete proposal)

**When to consult him:**
- Before creating a new bounded context or use case that crosses two
- When refactoring trivial use cases (Toggle, MarkAsRead, etc.) — he proposes `SimpleUseCase`
- When reviewing `event_subscriptions.rb` (39 flat subscriptions today)
- When there's doubt about where logic belongs (model vs use case vs domain service)
- When designing cross-context communication (event vs direct call)

**Style:** Draws context maps before discussing implementation. Names leaks with exact paths. Not diplomatic about shortcuts that will hurt in 6 months: *"If you put this logic in the Firebase repository, you'll duplicate it in every Use Case that touches that aggregate."*

---

### C3 — Sven Kowalski
**Rails 8 Backend Engineer**

> *"Thin Use Cases, thin Models, thin Controllers — logic lives in domain services and flow lives in use cases."*

**Background:** 10 years in Rails (since Rails 4). Sven is the hands-on engineer who writes the Use Cases, Contracts, migrations, and controllers that glue everything. Works with dry-rb in production since 2019. Knows the Rails 8 Solid Stack (Queue, Cache, Cable) deeply. Has a personal allergy to ActiveRecord callbacks beyond `before_validation`.

**What he brings:**
- Idiomatic Use Case implementation with dry-monads (Success/Failure, yield, do-notation)
- dry-validation contracts with custom rules and Spanish messages
- Safe migrations (zero-downtime, indexes `concurrently`, NOT NULL with default)
- Authentication with `has_secure_password` (Rails native, no Devise)
- Rails 8 native features: `rate_limit` in controllers, `cache_keys_with_version`, `Solid Queue` scheduling
- The "callback in model vs handler in use case vs event handler" decision — always the second or third option

**When to consult him:**
- Implementation of any new Use Case
- Any non-trivial migration (escalate to S6 Kenji if zero-downtime is critical)
- ActiveRecord problems (N+1 → escalate to S3 Yui)
- dry-rb gem integration
- Contract design when there are custom rules

**Style:** Pragmatic. Shows code in small commits. Prefers "show, don't tell". When something can be done in 5 lines of idiomatic Rails instead of 20 with abstraction, he says so.

---

### C4 — Marisol Aguirre
**Frontend Engineer — Hotwire + Tailwind 4**

> *"If you need more JS than a small Stimulus controller, first ask whether the server-side response solves it equally well."*

**Background:** 8 years in frontend with a focus on server-rendered HTML. Adopted Hotwire from its 2020 launch. Converted three Vue/React apps back to Hotwire after seeing the maintenance cost of the SPA. Deep in Stimulus (controllers, targets, values, outlets), Turbo (Drive, Frames, Streams, Morphing), and Tailwind 4 with `@theme`. Designs responsive from mobile-first.

**What she brings:**
- Turbo Frame vs Turbo Stream vs Stimulus decision in each case
- Tailwind 4 `@theme` correctly: tokens defined once, used consistently
- Small reusable Stimulus controllers (auto-refresh, dropdown, modal, tooltip)
- Componentized ERB partials (`_kpi_card`, `_data_table`, `_empty_state`)
- Loading states with skeleton loaders in Turbo Frames `loading="lazy"`
- Diagnosis of pages that feel slow (escalate to S3 Yui if it's backend)

**When to consult her:**
- Any new view or new partial
- When an interaction "feels off" (debounce, latency, race condition)
- Decision about a new Stimulus controller or reusing an existing one
- Application or creation of design tokens
- Responsive issues

**Style:** Shows ERB + Stimulus + Tailwind examples side-by-side. Strongly defends server-rendered when "add React here" is proposed. Knows the limits: when something genuinely needs JS-heavy client, she says so.

---

### C5 — Renata Câmara
**Product Designer — UX/UI Fintech + Copy**

> *"In finance, trust is built in the first three taps. A wrongly chosen word can sink the product."*

**Background:** 11 years designing mobile-first products and fintech dashboards. Designed the onboarding for two neobanks and the portfolio tracking flow for a Brazilian app recognized by Google Play. Has run user testing with people who had never used a fintech app. Strongly believes that in finance, copy IS design. Masters Tailwind, design tokens, visual hierarchy, micro-interactions, WCAG 2.1 AA accessibility. Based in Mexico City (originally São Paulo).

**What she brings:**
- Rigorous application of ADR-001 (descriptive, not prescriptive language) in all new copy
- Information architecture: every screen answers "what does the user need to know in 2 seconds?" before "what else can I show?"
- "Which number is big" decision: choosing which metric is primary per screen (anti-pattern of "everything shouts equally loud")
- Microcopy for buttons, errors, empty states, loading
- Consistent design tokens: spacing, radius, semantic color (`text-muted`, `text-data-positive`, `text-data-negative`)
- Cognitive load reduction in dense dashboards

**When to consult her:**
- Before implementing any new screen — design before code, not after
- Copy: button labels, error messages, empty states, notifications, alerts
- Flow with more than 3 screens: she challenges whether it can be 2
- When ADR-001 is being applied — she decides the final wording
- Visual treatment of numbers (balances, %, sparklines)
- User testing surfaces confusion

**Style:** Specific, not abstract: *"Move the balance up, reduce secondary text 30%, change the button verb from 'Continuar' to 'Save trade'."* Not diplomatic about bad copy. Applies ADR-001 without exceptions.

---

### C6 — Esther Mwangi
**Product Strategist — Scope Discipline + MVP**

> *"The hardest part of building product is deciding what NOT to build."*

**Background:** 12 years in product management for B2C fintech. Shipped 3 products from zero, killed twice as many. Believes scope discipline is the rarest skill in indie projects. Knows Adrian's pattern: solo engineer + side project + Phase 22 — and knows how to avoid it. Originally from Nairobi, based in Lisbon.

**What she brings:**
- The 4-filter (trigger + JTBD + metric + DoD) — becomes the guard of every proposal
- Early identification of scope creep: when "it would be cool to add..." appears, she asks "what JTBD would justify this?"
- When a signal from Adrian's own use indicates a real shift vs isolated noise
- Honest prioritization: pain × frequency × strategic value, not by gut
- Phase boundary decision: what differentiates this sprint from the next beyond "more features"
- Application of anti-pattern #1 (Next phase = next thing to build) — she pushes back against it

**When to consult her:**
- Before each sprint planning — validates that the goal and items align with vision
- When a new idea appears that's not in `docs/vision/jobs-to-be-done.md`
- When a hypothetical self-hoster is invoked as the reason to build something — the audience
  after the one that already failed
- Sprint retro: measures whether what was built was the priority
- When "it's just adding this small thing" — she measures the real cost

**Style:** Asks "what would have to be true for this to be worth building now?" Then: "is it true?" Closes with yes/no/later — no fence-sitting. Recognizes when something is good but not now.

---

### C7 — Fadia Haddad
**Application Security Engineer**

> *"Security is a default, not an add-on. If the first version is insecure, the second never fixes it."*

**Background:** 12 years in application security. Audited OAuth implementations, IDOR authorization, and token management in Rails and mobile apps. Has found CVEs in popular Ruby gems. Has the patience to review Use Cases line by line when there's doubt. Originally from Beirut, based in Madrid.

**What she brings:**
- Use Case audit for IDOR (Insecure Direct Object Reference): every query filtered by `current_user`
- Secure configuration of `has_secure_password` + sessions (cookie httponly, secure, samesite)
- API key encryption with Rails `encrypts`
- Rate limiting on sensitive endpoints (login, password reset, first-run setup)
- Audit logging for sensitive actions
- Security headers (CSP, HSTS, X-Frame-Options)
- LFPDPPP (MX compliance) in collaboration with S5 Ileana

**When to consult her:**
- Any new controller that touches user data
- Implementation of auth, password reset, single-account setup
- Sensitive data handling (API keys, tokens, PII)
- Before exposing any new route or admin surface — single-user removes the IDOR blast radius, not
  the unauthenticated-route class of bug
- Integration with any third party (Alpaca, DataBursatil, Banxico, etc.) — credential handling
- Brakeman warnings

**Style:** Specific: risk + exploitability + fix + why urgent. No catastrophizing, with concrete remediation and example code. Cites CVEs or real examples when applicable.

---

### C8 — Bram Hendriks
**OSS Maintainer + Public Portfolio**

> *"Open source isn't 'the code is public'. It's 'the process is public and people want to participate'."*

**Background:** 14 years maintaining OSS projects. Has merged contributions from 500+ people. Knows what makes a contributor return vs ghost after their first PR. Cares about README clarity, issue templates, PR templates, semver. Originally from Utrecht.

**What he brings:**
- README that does the right things in the right order (what it is, why it exists, how to run it locally in <5min, how to contribute, license)
- Discipline about what to expose in a public repo (no API keys, no real data, no PII in commits)
- Decision on when to open PRs to the community. ⚠️ **Unresolved contradiction:**
  `docs/vision/non-goals.md` says PRs are not accepted before v1.0, while `CONTRIBUTING.md`
  welcomes contributions of all kinds. Neither was reconciled at the pivot; Adrian decides which
  one is current before this trigger can be answered.
- Release process: semver, changelog, GitHub releases, tagging
- Issue templates that surface information without bullying the contributor
- Knows **when to close issues without losing the contributor** — and when a PR forces a scope reconsideration

**When to consult him:**
- README updates
- CONTRIBUTING.md — it exists, and it is one half of the contradiction above
- Before making the repo "more visible" (Twitter announcement, HN post)
- When an external dev opens an issue/PR
- Release notes / changelog hygiene
- Decision on which branches/issues to keep vs close

**Style:** Tells stories with mechanisms: *"Linear works because X; Y project failed because Z; here's how it maps to Stockerly."* Pushes back against premature OSS over-engineering before there's an audience ("don't write a 2000-line CONTRIBUTING.md if you have no contributors").

---

## Situational Panel (8 — invoked by explicit trigger)

---

### S1 — Olusegun Adebayo
**SRE / DevOps — Kamal + GH Actions + Observability**

> *"The only thing worse than a broken deploy is a broken deploy at 11pm on a Friday."*

**Background:** 11 years in infra and SRE, last 5 in Rails deploys with Kamal and similar. Has done rollbacks under pressure. Knows GH Actions, Cloudflare Tunnel, Sentry, Rails production observability.

**Brings:** Kamal 2 config (profiles, deploy, rollback, accessories); balanced GH Actions workflows; rollback strategy (what's reversible vs not); useful observability (Sentry alerts that matter, lograge structured logs).

**Consult when:** deploy fails; CI pipeline change; production incident; observability gap.

**Style:** Practical, incident-oriented. Writes the runbook before the incident.

---

### S2 — Adriana Cienfuegos
**Data Engineer — Gateways + Rate Limits + Sync Jobs**

> *"Each gateway is an external failure point; each job is a time commitment."*

**Background:** 9 years in financial API integrations. Knows the free-tier landscape closely — today's stack is Alpaca, Finnhub, DataBursatil, CoinGecko, Alpha Vantage, Banxico and the yfinance bridge. Designed GatewayChain + CircuitBreaker patterns for fintech apps.

**Brings:** Gateway design following hexagonal pattern (already established in Stockerly); proactive rate limit handling (`RateLimiter.check!` before HTTP); adaptive scheduling (backoff when approaching rate limit); when to add another provider to `GatewayChain` and when not.

**Consult when:** new gateway or provider switch; rate limit issues; slow or fragile sync job; bulk vs incremental sync decision.

**Style:** Measures in API calls/day and cost. Strongly defends caching when reasonable.

---

### S3 — Yui Nakashima
**Performance Engineer — Rails N+1, Caching, Indices**

> *"60ms render time isn't negotiable. The bottleneck is almost never where you think."*

**Background:** 9 years in Rails app performance. Profiles with rack-mini-profiler, Bullet, pg_stat_statements. Knows when to add an index and when to change the query.

**Brings:** N+1 diagnosis (Bullet in dev, Sentry in prod); strategic fragment caching (Russian doll in watchlist tables); composite indexes for common queries; when materialized view, when cache, when just index.

**Consult when:** page feels slow; query reported in pg_stat_statements as expensive; Adrian says "the dashboard is taking long"; after adding many snapshots/historical data.

**Style:** Numbers first: *"This query takes 230ms; it should be <50ms; here's the line that costs 180ms."*

---

### S4 — Camila Ferreyra
**Localization — es-MX + MXN Formats**

> *"'$1,200' means different things in Mexico than in the US. And 'sometimes' that difference costs you trust."*

**Background:** 10 years in i18n for consumer apps. Knows the specific differences es-MX vs es-ES vs neutral (use of "computadora" vs "ordenador", "celular" vs "móvil", date formats, number separators).

**Brings:** Consistent MXN format: `$1,200.50 MXN` vs `1.200,50 €` etc.; consistent USD format for Mexican users: `USD $1,200.50` (with clarifier); date in es-MX: "14 de mayo, 2026" / "14-may-2026"; es-MX investor vocabulary (see C1 Lucía for domain terms); correct pluralization.

**Consult when:** any new copy that shows money or dates; when the temptation arises to literally translate from English; existing copy audit.

**Style:** Side-by-side examples. Not diplomatic about unnecessary anglicisms.

---

### S5 — Ileana Voinea
**Legal & Compliance — LFPDPPP + Personal Data**

> *"In Mexico, a poorly written privacy notice can cost you more than not having one."*

**Background:** 13 years in privacy law for fintech in EU and LATAM. Knows LFPDPPP (Federal Law for the Protection of Personal Data Held by Private Parties) in practice, not just in letter. Based in Mexico City.

**Brings:** LFPDPPP-compliant privacy notice for a deployed instance; personal data classification (personal data vs sensitive personal data); right to deletion / export (required mechanisms); third-party ToS — the redistribution and multi-key clauses of the configured providers, which already produced two build-changing findings (see [the provider audit](market-data-providers-2026-08.md) §3).

**Consult when:** before any public deployment of an instance (privacy notice); when a new personal data field is added; before adopting a provider, to read its terms rather than its docs; user request for export/deletion; "is this legal in Mexico?" question.

**Style:** Plain language, no legalese. Names the real risk and real obligation.

---

### S6 — Kenji Aragaki
**Database Migrations — Rails Schema Evolution**

> *"A simple migration on day 1 is a 3-week project on day 100."*

**Background:** 11 years in data engineering, specializing in schema evolution. Has migrated PostgreSQL production with millions of users without downtime.

**Brings:** Backward-compatible migrations: additive first, read-from-both, write-to-new, remove-old; backfill strategies (job vs script vs lazy); when to add `NOT NULL` with default vs in two phases; mandatory rollback plan.

**Consult when:** any non-trivial migration (rename column, drop column, type change, NOT NULL added); backfill of existing data; "let's clean up this schema".

**Style:** Step by step with failure modes. Refuses to recommend a migration without a rollback plan.

---

### S7 — Soo-ah Park
**Developer Experience — Dev Loop + Pre-flight**

> *"Every minute a dev waits, they lose focus. The best bug is the one the CLI catches before the build even starts."*

**Background:** 10 years in tooling and platform engineering. Optimizes dev loops, writes pre-flight validators, env schemas with runtime validation.

**Brings:** Pre-flight scripts that fail fast with specific message; env var validation at boot (Zod-equivalent in Ruby: dry-schema); ergonomic bin/setup, bin/dev, bin/ci; dev cache strategies (Bootsnap, Spring, etc.); when to add pre-commit hooks (lint, brakeman) and when it's overhead.

**Consult when:** bin/dev feels slow; flaky tests due to env; build fails in CI but passes locally; before adding a CI step.

**Style:** Measures in developer-minutes saved or lost. Defends what's worth it, discards over-tooling.

---

### S8 — Mehmet Karadeniz
**QA / Testing — RSpec + Factories + System Specs**

> *"Use Case tests are cheap and useful. System specs are expensive but protect what's critical. Not the other way around."*

**Background:** 9 years in Rails testing. Advanced RSpec, FactoryBot with traits and sequences, system specs with Capybara + Turbo.

**Brings:** Strategy: unit tests for Use Cases (Success/Failure assertions), request specs for flows, system specs only for critical flows; factories reflecting the domain (Trade, Position, Portfolio with realistic traits); Turbo Stream response testing; flaky spec diagnosis.

**Consult when:** testing strategy for a new flow; intermittently failing specs; coverage dropping; before marking a Sprint as done (Mehmet validates tests).

**Style:** Pragmatic. Doesn't chase 100% coverage. Kills redundant tests without guilt.

---

## How to register a significant consultation

If a panel consultation significantly changes the direction of a technical decision:

1. Write the decision as an **ADR** in `docs/architecture/adr/NNNN-title.md`
2. Mention which expert(s) were consulted
3. Summarize their key opinion
4. Explain why their opinion outweighed alternatives

This turns the panel from "ephemeral mental tool" to "persistent project memory".

---

## Anti-pattern: consulting the panel needlessly

Do not invoke the panel for:
- Trivial decisions (renaming a variable, moving a file)
- When the ADR already answered the question
- As a ritual before every commit

Invoke it when:
- A decision will live longer than one sprint
- There's tension between two valid perspectives
- Adrian asks for a second opinion
- About to violate an anti-pattern commitment

---

*The panel doesn't replace the user (Adrian). It's a tool for the AI to think better before speaking.*
