# ADR-019 — Self-contained by default: the fewest vendors a self-hoster can inherit

- **Status:** Accepted
- **Date:** 2026-08-28
- **Author:** Adrian Castillo
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-018](./0018-totp-with-recovery-codes.md), [ADR-017](./0017-python-bridge-for-yahoo-finance.md)

---

## Context

ADR-010 made Stockerly a self-hosted single-user tracker, packaged so any technical self-hoster
can stand it up. It said nothing about what that instance is allowed to *depend on*, and the gap
went unnoticed until a decision hit it.

**The decision that exposed it, 2026-08-28.** ADR-018 approved TOTP. Reviewing whether the feature
was justified, the analysis recommended a cheaper first step: verify whether a Cloudflare Access
policy already fronts `stockerly.notdefined.dev`, since Access protects the maintainer's own
instance today and costs minutes against the days TOTP costs. The reasoning was sound about
*Adrian's* risk and wrong about *the product's*, and Adrian rejected it in one sentence:

> *"es un proyecto self-hosted, quiero pedir lo menos posible vendors, no hay garantía de que
> quieran o tengan cloudflare"*

That is a constraint, not a preference, and it decided the sequencing: **Access is a vendor
dependency; TOTP is a mitigation that ships inside the product.** A self-hoster inherits the exposed
login and none of the maintainer's Cloudflare account.

Nothing in `docs/vision/` said so. The three hard rules cover multi-currency, building for the real
user, and the 4-filter; none of them constrains dependencies. `non-goals.md` rejects aggregators,
but on **cost** — the Plaid/Maybe Finance argument — not on independence, so it does not generalize.
The principle existed and had to be re-derived in conversation to be applied, which is the failure
mode D53 names in the design folder and this ADR ends for the product.

## Decision

**An instance must run with the fewest external dependencies a self-hoster can be asked to accept.
When a capability can be met inside the app or by a vendor, the in-app answer wins unless the
in-app answer is not viable.**

Three clauses, so this is applied rather than admired:

1. **A required third-party service is a scope change and needs its own ADR.** "Required" means the
   instance is degraded or broken without it. Adding one is not an implementation detail a PR can
   settle.
2. **Optional is fine, and must degrade honestly.** Market-data providers are the model: keys are
   per-provider, absent keys are shown as absent, and the screen says which block needs what rather
   than rendering broken cards. An optional vendor never becomes a silent precondition.
3. **The maintainer's own infrastructure is not the product's answer.** Cloudflare Tunnel, Tailscale
   and Access are how *this* instance is deployed. They are defence in depth for one operator and
   may never be cited as the mitigation for a risk every instance carries.

**This is not a ban on vendors.** Stockerly already depends on market-data providers and cannot do
its job without at least one; that dependency is real, optional per provider, and degrades visibly.
The rule is about who bears the cost of a dependency the owner did not choose.

## Consequences

- `docs/vision/README.md` gains a **fourth hard rule** citing this ADR, and `non-goals.md` gains the
  matching entry. Per the vision README's own process, a scope change requires an ADR — this one.
- **ADR-018's sequencing is settled, not just argued:** TOTP first, Access independent. The
  unanswered question of whether an Access policy already fronts the hostname stays a *fact* worth
  knowing and stops being a decision that blocks anything.
- **A live example of the rule working, already in the tree:** [ADR-017](./0017-python-bridge-for-yahoo-finance.md)
  runs a Python subprocess rather than adopting a hosted scraping service. It was decided before this
  rule existed and satisfies it.
- **A live tension it does not resolve:** the app requires PostgreSQL and Solid Queue, and the deploy
  assumes Kamal and GHCR. Those are the operator's own infrastructure choices, not services the
  product phones home to, so clause 1 does not bite. If that line ever blurs — a hosted queue, a
  managed search — it is an ADR.
- Reviewers get a question they can ask without re-deriving it: **would a self-hoster have to sign
  up for something to get this?** If yes, it needs an ADR before it needs code.
