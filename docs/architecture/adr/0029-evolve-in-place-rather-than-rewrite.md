# ADR-029 — Evolve Stockerly in place rather than rewrite it

- **Status:** Accepted
- **Date:** 2026-05-14 (decided) · 2026-08-22 (confirmed with evidence) · 2026-09-23 (recorded here)
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-016](./0016-canonical-market-data-observations.md), [ADR-022](./0022-github-as-the-system-of-record.md)

---

## Context

Stockerly had accumulated the shape of a multi-user SaaS it was never going to be, and the urge to
start over from a clean repo came up repeatedly. It came up again when the 2026-08-20 pivot cut the
product down to a self-hosted, single-user tracker ([ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md)):
a smaller product looks like an argument for a smaller codebase, written fresh.

This ADR is recorded late. The decision has governed the 2.0 work since May 2026 and the evidence
for it was gathered in August, but it lived only in the author's private working notes — so the one
decision that gates every other one was invisible to the repository that twenty-eight lesser
decisions are recorded in. Recording it is the point: a gate nobody else can read is not a gate.

## Decision

**Correct Stockerly in place. No rewrite, no abandonment.**

The 2026-08-20 pivot reaffirmed this rather than reopening it: it changed the **audience**, not the
code, and it landed **in place** rather than in a fresh repository. The pre-2.0 state is tagged
`pre-2.0-evolve`, and the 2.0 work landed on `master` slice by slice.

**The gate is closed.** Reopen it only if the author explicitly wants a *learning* rewrite on a
different stack, or if the architecture is found to actively fight the single-user self-hosted
goal — with evidence, not before.

## Evidence

Confirmed 2026-08-22 by two independent reviews that were run without sight of each other:

- A **five-stage parallel code audit**, which returned **EVOLVE 5/5**.
- An **independent seven-expert panel**, which was **unanimous** for the same answer.

Both landed on the same finding: the target architecture's abstractions **already exist, under-wired
rather than absent**, and the multi-user surface that the pivot makes dead weight is FK-clean and
peripheral rather than load-bearing.

The audit's raw output lives in the author's private working notes and is not in this repository.
What it concluded is above; anyone re-opening this decision should re-run the analysis rather than
ask for that file.

## Alternatives considered

**Rewrite from scratch — rejected.** A rewrite would have to replicate roughly 2,760 specs, 14
working gateways, 6 bounded contexts, ~37 models, the branding, the Kamal deployment and CI. That is
months of evenings and weekends to arrive back where the project already is. Against that, the
diagnosis was explicit: **the process and the audience were broken, not the code.** "Empezar de
cero" was identified as emotional escape rather than strategy — a judgement the author made about
his own motivation, which is why it is recorded rather than left implicit.

**Rewrite on a different stack, as a learning exercise — not rejected, deferred.** It is a
legitimate reason to start over and it is not this decision's to refuse. It is simply not what the
2.0 work is for, and the two must not be confused with each other mid-flight.

**Keep the multi-user surface — rejected.** It is dead weight under [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md)
and it costs on every schema change and every audit.

## Consequences

**The subtraction the pivot authorised.** Most of `Administration` (invites, users) and the
multi-user surface of `Identity` (register, verify_email, first-admin), along with the `invite_code`,
`remember_token`, `email_event` and `user_activity` models. `MarketData` and `Trading` are what gets
reinvested in. The hexagonal boundaries are what made this affordable: every doomed foreign key is
outbound, so the cut is FK-clean rather than a migration project.

This work has been carried out. What each piece looks like now is the code's to answer, not this
file's — an ADR that describes current state starts lying the day after it is merged.

**One object that looked like part of that subtraction and was not.** `api_key_pool` read as
multi-user surface and was not: key rotation fed the gateways the FX path depends on, so deleting it
would have dark-failed every external source. The answer was rework rather than deletion, and
[ADR-015](./0015-one-api-key-per-provider.md) is where that rework was decided. The single-user
account was likewise already in-repo and was repurposed rather than rebuilt.

The reasoning is what generalises, and it is the reason this paragraph exists: **check what a
doomed-looking object actually feeds before deleting it.** The audit caught this one; a rewrite
would have had no such object to catch, and no such gateway either.

**Multi-currency correctness was found closed, not open.** It had been carried as open work and the
audit established it was not — the currency-correct seams already existed and were spec-covered.
That finding is part of why EVOLVE won: the foundation the rewrite would have been justified by
turned out to be sound.

**The cost of being wrong.** If the architecture does turn out to fight the single-user goal, this
decision will have spent evenings wiring abstractions that a rewrite would have skipped. That is the
trade being made knowingly: the audit says the abstractions are there, the rewrite's bill is certain,
and this one's is contingent.
