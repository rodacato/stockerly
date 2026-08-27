# ADR-008 — Privacy notice does not publish the responsible party's full domicile inline

- **Status:** Accepted
- **Date:** 2026-05-18
- **Author:** Adrian Castillo
- **Supersedes:** —
- **Related:** [`app/views/legal/privacy.html.erb`](../../../app/views/legal/privacy.html.erb), [`docs/ops/arco-procedure.md`](../../ops/arco-procedure.md), [ADR-007](./0007-defer-i18n-adoption.md)

---

## Context

The Gemini auto-review on PR #110 flagged that Art. 16 Fracción I of the Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP, DOF 20-mar-2025) requires the privacy notice to state the **full domicile** of the responsible party (the person or entity that decides on the data processing), not just the city.

The current `/privacy` view names *"Adrian Castillo, persona física con domicilio en la Ciudad de México, México"* and the support email — it does not publish a street address, ZIP code, or apartment number.

Three options were considered:

1. **Publish the personal home address.** Direct literal compliance. Costs: permanent publication of a private individual's home address in a public GitHub repo and on the production website — a privacy and personal-security cost the law does not require Adrian to absorb personally.
2. **Rent a postal box or conventional mailbox.** Compliance with operational privacy preserved. Costs: ~MXN 500–1500/month for an open-source project with zero revenue, plus the operational overhead of maintaining the address.
3. **Document the omission as a conscious exception** with a disclosable mechanism: the privacy notice itself states that the full domicile is available *upon formal written request* via the support email, satisfying the substantive intent of Art. 16 (the data subject has a defined path to reach the responsible party) without putting the personal address on the public web.

## Decision

We take option 3. The `/privacy` view names CDMX as the jurisdiction and includes a one-line disclosure that the complete domicile is provided in response to a formal written request sent to `Stockerly::SUPPORT_EMAIL`.

This is a knowing departure from a literal reading of Art. 16 Fracción I in exchange for two things that matter more in the project's current state: the personal safety of a single-maintainer open-source project, and the avoidance of monthly recurring cost for a beta product with ≤20 users and no revenue.

## Consequences

**Positive**
- The aviso de privacidad is honest about the omission instead of silent — a regulator or data subject reading the notice sees both the missing field and the path to obtain it.
- The mechanism (email request) is the same one already established for ARCO requests, so no new operational surface is introduced.
- If a regulator does request the domicile formally, Adrian provides it privately — the substantive obligation is met.

**Negative / risk**
- A strict reading of Art. 16 Fracción I considers this non-compliant. A complaint to the data-protection authority could yield a request for amendment; the cost is publishing an address (option 1 or 2) at that point.
- Beta invitees who care about literal compliance may find the omission notable. The disclosure language makes the trade-off visible rather than hidden.

**Operational requirement**
- The support inbox must respond to formal domicile requests within the same 20-business-day window as ARCO requests (Art. 32 LFPDPPP). This is operationally cheap: the response is a one-paragraph email with the address.
- If the beta expands beyond a closed circle of personal friends, this ADR should be revisited — the larger the user base, the weaker the personal-safety argument carries against the compliance one.

## Revisit triggers

- Beta opens beyond invited friends (public sign-up or paid tier).
- A regulator formally requests the domicile.
- Adrian acquires a non-personal commercial address (coworking, mailroom, business location) and finds the cost acceptable.

When any of these fires, switch to option 1 or 2 and remove the disclosure language from the privacy notice.

---

## Amendment, 2026-08-27 — the beta this ADR reasons about no longer exists

**The decision still holds; its stated justification and its first revisit trigger do not.**

This ADR weighs personal safety against *"monthly recurring cost for a beta product with ≤20 users
and no revenue"*, and its first revisit trigger is *"Beta opens beyond invited friends (public
sign-up or paid tier)."* [ADR-0010](./0010-pivot-to-self-hosted-single-user-tracker.md) ran that
beta, found it failed, and dropped the audience on 2026-08-20. **There is no beta to open, so that
trigger can never fire.** The same goes for the "if the beta expands beyond a closed circle" line
under Operational requirement, and for the note about beta invitees finding the omission notable.

The conclusion survives the change of premise, and arrives at it more directly: Stockerly is now a
self-hosted single-user tracker with one user, who is the maintainer. There is no user base to weigh
against personal safety at all, and no revenue to fund a postal box. Option 3 is if anything more
clearly right than it was in 2026-05.

**Revised revisit triggers**, replacing the first bullet above:

- Stockerly is offered as a hosted service to anyone other than its maintainer — a public instance,
  paid or free — which reintroduces a data subject who is not Adrian. Self-hosters running their own
  instance do **not** fire this: they are their own responsible party, not Stockerly's data subjects.
- A regulator formally requests the domicile. *(unchanged)*
- Adrian acquires a non-personal commercial address and finds the cost acceptable. *(unchanged)*
