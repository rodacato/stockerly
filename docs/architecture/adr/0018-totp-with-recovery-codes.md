# ADR-018 — TOTP with recovery codes, because the audience is no longer one person

- **Status:** Accepted
- **Date:** 2026-08-27
- **Author:** Adrian Castillo
- **Supersedes:** the recommendation in [D23](../../../design/DECISIONS.md) (not a prior ADR)
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-015](./0015-one-api-key-per-provider.md), [ADR-019](./0019-self-contained-by-default.md)

---

## Context

`flows/auth.pen` has drawn a full TOTP screen since the redesign began, and its brief called
the choice *"settled: password + TOTP, email OTP fallback, no SMS"*. Nothing backed it. D23
verified the absence four ways on 2026-08-24: no gem (`rotp` or equivalent is absent from the
Gemfile), no column (`users` carries `password_digest` and nothing else auth-related), no route
and no line of code anywhere in `app/` or `lib/`, and no record — no ADR, no CODE_CHANGES
section, no issue. The only trace the feature existed was `design/README.md` listing the screen.

D23 recommended **not** building it, on two grounds:

1. **No documented trigger.** The 4-filter rule requires one, and the threat model that would
   justify a second factor had not been written down.
2. **Permanent lockout.** The instance has one account and no support desk. A lost
   authenticator locks the owner out of their own server forever, so TOTP could not ship
   without recovery codes — a second feature nobody had scoped.

Its 2026-08-25 amendment then weakened its own first ground. The entry had reasoned that the
box sits behind Cloudflare Tunnel and Tailscale, implying `/login` was unreachable; but
`config/deploy.yml` publishes `stockerly.notdefined.dev` through a **public** Cloudflare Tunnel
(`proxy.ssl: false`, TLS at the edge), and nothing in the repo records an Access policy in front
of it. The login form is very likely internet-facing, protected by a password of at least eight
characters and `rate_limit to: 5, within: 1.minute`. The amendment's answer was to put
**Cloudflare Access** in front of the tunnel *instead of* building TOTP.

## Decision

**Build TOTP, and ship recovery codes with it in the same scope.**

What changes the answer is not new evidence about the threat — it is who the product is for.
ADR-010 packages Stockerly so any technical self-hoster can run it. A packaged product cannot
answer a stranger's threat model with *"put Cloudflare Access in front of it"*: Access is one
maintainer's infrastructure, on one maintainer's Cloudflare account, and a self-hoster who
deploys this behind their own ingress inherits the exposed login and none of the mitigation.
D23's reasoning was sound for an audience of one. The audience of one is what ADR-010 retired.

Three boundaries, stated so they are not re-litigated per PR:

- **Recovery codes are in scope, not a follow-up.** D23's lockout risk is not dissolved by this
  decision — it is multiplied by every self-hoster, none of whom can be recovered by a
  maintainer who has no access to their instance. Generation, hashing, one-time consumption and
  regeneration all ship with enrollment. TOTP without them is the trap, not the door.
- **Email OTP is out of scope.** The `auth.pen` brief named it as the fallback; it is not one.
  It adds screens and a recovery path that dies on a self-hosted box whose mail is
  misconfigured — the same permanent lockout by another door, on a deployment where mail is
  the single most likely thing to be wrong. Recovery codes work with no outbound network at all.
- **No SMS.** Unchanged from the brief, and never in question.

**Sequencing settled 2026-08-28 by [ADR-019](./0019-self-contained-by-default.md).** Reviewing
whether this feature was justified, the analysis recommended verifying Cloudflare Access first, on
the grounds that it protects the maintainer's instance today for minutes of work. That was right
about Adrian's risk and wrong about the product's: **Access is a vendor dependency and TOTP ships
inside the product.** ADR-019 turns that into the vision's fourth hard rule, so the order is TOTP
first and it does not have to be re-argued. The discovery card this ADR says is owed is
[#391](https://github.com/rodacato/stockerly/issues/391).

**Cloudflare Access remains worth doing and is now independent of this.** It was proposed as
the alternative to TOTP; it becomes defence in depth for the maintainer's own instance. Whether
an Access policy already fronts the hostname is still an unanswered *fact* rather than a
decision, and it no longer blocks anything.

## Consequences

- A gem, a migration (`otp_secret`, an enrolled-at timestamp, and a recovery-codes table or
  column), routes, and an enrollment flow the app has never had.
- Recovery codes are a second feature with their own storage, display-once semantics and
  regeneration path. Scoping TOTP without budgeting for them reproduces exactly the gap D23
  identified.
- New artboards in `flows/auth.pen`: enrollment (QR, secret, verify), the one-time recovery-code
  display, and recovery-code entry at login. Per D4 none of them needs a desktop variant — only
  Login diverges on desktop; the rest keep the centred card.
- **Where the product asks for enrollment is deliberately left open.** Ajustes and a first-boot
  onboarding step are both defensible, and they are not equally priced: an onboarding step adds
  a `Stepper` stage and touches all nine wizard artboards. That call is owed before
  `flows/onboarding.pen` is opened, and blocks nothing before then.
- The `auth.pen` brief must lose the "settled" claim and the email-OTP fallback, and the D23
  amendment's Tunnel/Tailscale premise must not be repeated as though it still held.

## Notes

This ADR exists because the decision reverses one the registry had already published. D23 is
amended in place rather than deleted, per that file's own rule — the reasoning is the useful
part, and the reason this reversed is more instructive than the outcome: the decision was
correct, and its premise expired underneath it when the audience changed.
