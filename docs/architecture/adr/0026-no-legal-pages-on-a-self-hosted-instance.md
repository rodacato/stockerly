# ADR-026 — A self-hosted instance serves no legal pages; the license carries what applies

- **Status:** Accepted
- **Date:** 2026-09-13
- **Author:** Adrian Castillo
- **Supersedes:** [ADR-008](./0008-privacy-notice-domicile-disclosure.md)
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-013](./0013-action-labels-on-persisted-observations.md), [ADR-019](./0019-self-contained-by-default.md), [`LICENSE`](../../../LICENSE)

---

## Context

`/privacy`, `/terms` and `/risk-disclosure` were written for the closed beta (#73, #102, #104): a
hosted instance where Adrian held other people's data. A privacy notice under the LFPDPPP, an ARCO
procedure, terms naming him as the provider and CDMX courts as the venue — all of it answered a real
relationship between one person and the friends using his server.

ADR-010 removed that relationship on 2026-08-20. ADR-008 noticed its own premise had moved and
concluded its option was *more* right, but nothing asked whether the pages themselves still had an
addressee.

**The trigger, 2026-09-13.** Making the repo independent of the maintainer's infrastructure moved the
public hostname to `APP_HOST`. `SUPPORT_EMAIL` could not follow it: every instance, whoever runs it,
publishes *"Adrian Castillo, persona física con domicilio en la Ciudad de México"* as the data
controller and routes ARCO requests to his inbox. `docs/ops/arco-procedure.md` told self-hosters to
edit the ERB by hand, which the next pull overwrites. Making the operator configurable was drafted;
Adrian questioned the premise instead:

> *"no estoy seguro pero me inclino a que no son necesarios si es open source self hosted under your
> own risk, es más parte de license del repo, no?"*

Checked against each page:

- **Privacy notice and ARCO.** Data-protection duties fall on whoever processes *other people's*
  personal data. A single-user instance holds the data of exactly one person, who is also the one
  operating it. The software's author receives nothing: there is no telemetry, and error tracking
  runs inside the instance (ADR-020). There is no controller facing a data subject, so a notice has
  nobody to address. The 2010 LFPDPPP excluded processing for exclusively personal use outright
  (Art. 2); whether the 2025 text keeps that wording was **not verified**, and the argument does not
  rest on it.
- **Terms of service.** Terms are a contract between a provider and its client. ADR-013's legal
  condition is that Stockerly is never presented as a service to third parties; a page titled
  *Términos del servicio* contradicts it. What the terms said that still binds — no warranty, no
  liability for losses — is the MIT license's own text.
- **Risk disclosure.** Not a legal need for the same reason, but its core sentence is product copy
  with a reader: since ADR-013 and D113 the app shows verbs like `compra`, and saying that this is
  information and not advice serves the person reading the screen.

## Decision

**An instance serves no privacy notice, no terms of service and no risk-disclosure page.** The routes,
`LegalController`, the `legal` layout, the footer's Legal column, the login's terms line,
`Stockerly::SUPPORT_EMAIL` and the unused `users.consents_data_processing_at` column are removed.

What remains, and where:

| Need | Carried by |
|---|---|
| No warranty, no liability | [`LICENSE`](../../../LICENSE) (MIT) |
| "Information, not investment advice" | the one-line notice on the asset screen (`market/_disclaimer`), and the README's Disclaimer section |
| A channel for bugs | `Stockerly::ISSUES_URL`, already the only one (D91) |
| Deleting one's own data | the in-app account deletion, which stays as a feature |

## Consequences

- **ADR-008 is superseded**, not amended: it decided how a privacy notice publishes a domicile, and
  there is no notice.
- `docs/ops/arco-procedure.md` is deleted. It described a relationship that no longer exists and told
  operators to patch views.
- **Not addressed: the name and logo.** MIT grants rights to the code, not to the brand, which only
  `/terms` §4 claimed. Nothing replaces that claim; if a fork's use of the name ever matters, a
  trademark note in the README is the place, and it is a separate decision.
- **Each operator stays responsible for their own instance.** If someone opens theirs to other
  people, the obligations are theirs, as with any self-hosted software — the README says so.

**Revisit when any of these holds** — each one reintroduces a data subject who is not the operator:

- Stockerly is offered as a hosted service, public or private, paid or free.
- The app gains more than one account per instance.
- Any data flows from an instance to the maintainer or a third party the operator did not configure.

### Panel

- **S5 Ileana (Legal/Compliance MX):** without an offer and without a second person there is no
  relationship for these pages to govern; keeping them implies one. Her condition: the README must
  say plainly that each operator answers for their own instance, and the revisit triggers above must
  not be softened.
- **C8 Bram (OSS maintainer):** this is the norm for self-hosted projects — the license is the
  contract with the people who run the code. He would add the trademark line only on evidence of a
  fork trading on the name.
- **C5 Renata (UX/copy):** the not-advice line earns its place because it sits where the verbs are.
  Her concern is that it stays on that screen and does not drift into a footer nobody reads.
