# ADR-011 — Adopt Rails I18n (single locale, es-MX) for the 2.0 rewrite

- **Status:** Accepted
- **Date:** 2026-08-24
- **Author:** Adrian Castillo
- **Supersedes:** [ADR-007](./0007-defer-i18n-adoption.md)
- **Related:** [ADR-001](./0001-descriptive-not-prescriptive-language.md), [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), `design/CODE_CHANGES.md`

---

## Context

ADR-007 deferred I18n with four explicit reversal triggers. Two now hold at once.

**Trigger 4 — Adrian asked for it.** Directly, on 2026-08-24: the site stays Spanish, the code
stays English including routes, and the copy runs through I18n managed with `i18n-tasks`.

**Timing, which is the argument that makes it cheap.** The 2.0 redesign is finished on the design
side — five flows, twenty decisions — and `design/CODE_CHANGES.md` carries nine sections of ERB
translation that has not started. **Every user-facing string in the app is about to be rewritten
anyway.** Adopting I18n during that rewrite costs a YAML line per string we were already touching;
retrofitting it afterwards costs a second full sweep of the same files. The cheapest moment to add
the layer is the moment the strings are already in your hands, and that moment is now.

ADR-007's reasoning was not wrong — *"an I18n layer for one locale is infrastructure without
payoff"* was true when the alternative was rewriting working screens for the sake of it. It stops
being true when the screens are being rewritten regardless.

## Decision

**Adopt Rails I18n with `es-MX` as the only locale, and manage the catalogue with `i18n-tasks`.**

1. **`config/locales/es-MX.yml` is the home of user-facing copy** — views, flashes, mailers, page
   titles, meta and OG tags, controller error strings.
2. **`i18n-tasks` is the tool**: `i18n-tasks health` runs in CI; `i18n-tasks normalize` keeps the
   file sorted; `i18n-tasks unused` / `missing` keep it honest. Without the tool, a single-locale
   YAML rots into dead keys nobody notices.
3. **Code stays English — routes included.** Paths are `/dashboard`, `/assets`, `/alerts`,
   `/settings`; the Spanish lives in the rendered labels, not in the URL. This closes the route-map
   question the redesign's four-tab navigation opened: the tabs read *Panorama · Activos · Reglas ·
   Ajustes* and resolve to English paths.
4. **Lazy lookups (`t(".title")`) are the default**, so a key's home is obvious from the template
   that renders it. Reach for an absolute key only for genuinely shared copy.
5. **Adopt it surface by surface, with the redesign.** A screen gets its keys when its slice is
   translated to the new design — not in a separate big-bang migration. Until a surface is
   rewritten, its hardcoded es-MX strings stay put and are not a defect.

## How to apply

- **New or redesigned surface:** copy goes to `es-MX.yml` under the lazy key of its template.
- **Untouched surface:** leave it. Mixed state is expected while the redesign lands and is not
  worth a cleanup PR of its own.
- **Review comments about I18n:** they are now correct — apply them. The redirect to ADR-007 is
  retired.
- **A second locale is still not a goal.** This is about where the strings live, not about
  translating the product. `en` gets added the day there is a reader for it, and the cost of that
  day is now a file rather than a sweep.

## Consequences

### Positive

- The 2.0 rewrite lands localizable from day one, at the marginal cost of the rewrite itself.
- Copy stops being scattered across ERB: one file to review when the voice changes (ADR-001 is a
  voice rule, and voice rules are easier to enforce over a catalogue than over 143 templates).
- `i18n-tasks` gives a real check for dead and missing copy, which hardcoded strings never had.

### Negative

- Indirection returns: `grep "Registrar movimiento" app/views` stops finding the string. Mitigated
  by lazy keys — the template path *is* the key path — and by `i18n-tasks`.
- A YAML edit joins the loop for every copy change.
- A mixed codebase during the transition: some surfaces on keys, some hardcoded. Accepted
  deliberately; the alternative is a big-bang migration that competes with the redesign.

### Follow-ups

- Reopen or supersede issue **#113** (closed wont-fix under ADR-007) pointing at this ADR.
- `CLAUDE.md`, `AGENTS.md` and the project memory carried the old rule and are updated with it.
