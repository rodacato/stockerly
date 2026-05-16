# ADR-007 — Defer I18n adoption until multi-locale is real

- **Status:** Accepted
- **Date:** 2026-05-16
- **Author:** Adrian Castillo (formalizing the position taken across S07 PR reviews)
- **Supersedes:** —
- **Related:** [`docs/design/brand.md`](../../design/brand.md) §9 (Spanish-MX UI conventions), [`docs/vision/audience.md`](../../vision/audience.md), [ADR-001](./0001-descriptive-not-prescriptive-language.md)

---

## Context

Across Sprint S07 (closed 2026-05-16), Gemini code review flagged the absence of Rails I18n infrastructure four consecutive times — once per PR that introduced new user-facing copy:

- PR #85 (`/privacy` controller strings)
- PR #86 (`Identity::UseCases::Register` Spanish error messages)
- PR #87 (welcome body + bug-report form errors — two comments)

In each case the recommendation was the same shape: move user-facing strings to `config/locales/*.yml`, use `I18n.t(...)` lookups, "ensure the application remains maintainable and localisable". Each time the recommendation was rejected with the same core argument. Rejecting the same recommendation four times in two days is a signal: the underlying decision has not been formalized at the architecture level, so reviewers (human or AI) keep raising it.

This ADR codifies the position so that future reviews can be redirected here in one line.

### Facts framing the decision

1. **Single-locale target.** `docs/vision/audience.md` scopes Stockerly to **MX investors only**. The closed beta is ≤20 invited friends, all Mexican. There is no roadmap entry for multi-locale expansion in S07–S09.
2. **Spanish-MX is canonical, not a translation.** `docs/design/brand.md` §9 explicitly defines the es-MX UI vocabulary as the brand voice — *"Posiciones abiertas"*, *"Saldo disponible"*, *"Buenas tardes, &lt;nombre&gt;"*, the F&G heatmap copy, the date-stamp format. The language is part of the brand, not an interchangeable layer.
3. **Adopting I18n for one locale has cost without payoff.** A YAML lookup layer adds (a) the indirection between source and surfaced string, (b) the translator workflow ceremony, (c) the `I18n.t` call site noise, (d) the `config/locales/` migration step for every new screen. None of those costs are offset until a **second locale** exists to translate INTO.
4. **The current transitional state is acknowledged but bounded.** Some legacy code still has English strings (parts of `/register`, `/login`, `shared/_public_footer`, dry-validation default error messages). The direction is es-MX, not bilingual. New code lands in es-MX directly. Existing English residue gets translated when each surface is reworked, not retrofitted via I18n now.
5. **The retrospective audit data.** S07's design workflow demonstrated that paste-ready hardcoded es-MX prompts produce design-tool output and ERB implementations with zero translation friction. Adding I18n would not have improved any S07 deliverable; it would have added one indirection layer between the prompt and the rendered text.

### Options considered

- **A. Adopt I18n now, single locale.** Mainstream Rails recommendation. Plausible if multi-locale were imminent. **Rejected:** premature abstraction for a real cost without payoff. The "easier to start now than to retrofit later" argument is real but weak — Rails I18n retrofit is a mechanical pass (find string → wrap in `t(...)` → add to YAML) that's tractable when the trigger is real.
- **B. Adopt I18n only for *some* strings (the ones likely to vary).** Half-measure. **Rejected:** inconsistent codebase is worse than a fully-hardcoded one because the rule for "which string lives where" decays. Either every string is I18n-managed or none is.
- **C. Defer adoption with explicit triggers for revisit.** **Selected.** Keeps the codebase consistent (everything hardcoded es-MX), documents the position so future reviews can redirect here, defines what changes the calculus.

---

## Decision

**Stockerly does not adopt Rails I18n in S07–S08. User-facing strings are written in Spanish-MX directly in templates, controllers, contracts, and mailers.** This applies to:

- View templates (ERB)
- Controller flash messages
- Mailer subjects and body content
- `dry-validation` error messages (when written explicitly via `key.failure("...")` — defaults remain English until a contract is migrated)
- Stimulus-rendered runtime strings

### Triggers for revisit

This decision is revisited (and an ADR-008 may overturn it) when **any one** of the following becomes real:

1. **A second locale exists in production.** A real user base or invite cohort in a different language requires the platform to render. Not a hypothetical "we might want English someday".
2. **A translator workflow is in place.** A non-developer needs to update copy without touching ERB files. This implies YAML or a CMS, and YAML is the lower-friction choice in a Rails app.
3. **A copy-management tool is adopted.** Phrase, Lokalise, Crowdin, or similar are integrated. Hardcoded strings become a friction point at that moment.
4. **Adrian explicitly requests it for a reason not covered above.** Architecture decisions ride explicit user requests as well as data triggers.

In the absence of any of those, the ADR stands and reviewers should redirect questions here.

### How to apply

- **For new code (S08+):** write strings directly in es-MX. Do not wrap in `I18n.t`. Do not add `config/locales/es-MX.yml` entries.
- **For existing English residue:** when reworking a surface, translate to es-MX as part of that surface's PR. Do not introduce I18n during translation. See the S07 retro carry-over "Auth-flow translation to es-MX" for the concrete file list of remaining residue.
- **For review comments suggesting I18n adoption:** cite this ADR in the reply. The reviewer is not wrong — they are pointing at a real architectural question. The answer is documented here and the answer is "not yet, with triggers".

---

## Consequences

### Positive

- Codebase remains consistent (one rule: es-MX hardcoded).
- Zero indirection between source and rendered string — grep finds it directly.
- New screens compose faster (no YAML edit step in the workflow).
- Review noise drops: this ADR is the canonical answer to a recurring class of comments.

### Negative (acknowledged)

- A future multi-locale migration will be a mechanical pass touching most ERB files. The cost lives in the future, but it's real and finite.
- Hardcoded `dry-validation` defaults in English continue to surface when a contract uses built-in validators (e.g., `min_size?: 3` emits `"size cannot be less than 3"` in English). These are user-visible on 422 responses. Mitigation: contracts that have user-visible error paths should write custom es-MX `key.failure(...)` messages explicitly, rather than relying on defaults. Captured as a carry-over but not a blocker.
- A second locale request would require both the YAML migration **and** redesign of the brand voice for the new language. The brand voice currently encodes es-MX assumptions (greeting format, sector vocabulary, currency placement); a new locale isn't just translation.

### Neutral

- Memory entry: this ADR is the formal expression of the position previously held informally across 4 PR reviews. The `feedback` memory category was not the right home for this — it's an architectural decision, not a recurring correction.

---

## Decision Record

- **Selected:** Option C — Defer adoption with explicit triggers.
- **Rejected:** A (adopt now, premature), B (partial, inconsistent).
- **One-line rationale:** *"Spanish-MX is the brand, not a translation; an I18n layer for one locale is infrastructure without payoff."*
