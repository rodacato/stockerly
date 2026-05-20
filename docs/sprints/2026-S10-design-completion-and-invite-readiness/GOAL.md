# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Close the design-pass arc on the four remaining mockup-ready screens (asset detail, alerts, earnings, notifications) and invite the first beta amigo during the sprint so any surfaced issues feed back into the same window — making S10 the first sprint that validates the product against a real (non-Adrian) human.

**Sprint period:** 2026-05-20 → TBD (close by QA + retro, not by date)

**Sprint number / milestone:** S10 — 2026-S10-design-completion-and-invite-readiness

---

## Why this goal and not another

After S09 the operational screens (dashboard, portfolio, trades, market, profile) and the entire auth family (login, register, password recovery) are es-MX + Lumen. The four remaining design issues (#93 asset detail, #94 alerts, #100 earnings, #101 notifications) are the last screens an invited beta amigo would reach but still wear pre-Lumen treatment and English copy in places. Leaving them for S11 would mean inviting on a half-revamped UI — exactly the inconsistency S08 + S09 spent two sprints fixing.

At the same time, the entire premise of S08 + S09 has been "preparing for the first invite". Continuing to polish without ever inviting is its own anti-pattern — design without user feedback is design-by-assumption. S10 puts the invite **inside the sprint window** so that anything that surfaces from real use (UX friction, broken flows, edge cases not covered by specs, things that worked in dev but break with real usage) lands in the **bug triage issue (#125) reserve capacity**, not in a separate "post-invite cleanup" sprint that defers feedback another week.

**Critical path priority:**

1. **#100 Earnings + #101 Notifications** first — both are read-only revamps, low complexity. Ship them early so they're done before the invite goes out.
2. **#93 Asset detail + #94 Alerts** second — both have backend implications (asset-type-adaptive routing for #93; MX-aware rule types for #94). Higher complexity but mockup-ready.
3. **First beta invite mid-sprint** — once the design-pass core is in, invite. Reactive fixes from feedback land in #125 reserve.

**Parallel work:**

- **#124 Logo audit** — visual consistency + fallbacks across user-facing surfaces. Paired with the design-pass core because the same eye that's reviewing screens for revamp can also catch logo inconsistencies.
- **#125 Bug triage reserve** — open-scoped capacity for whatever the first invite surfaces.

**What this unblocks:** the product becomes **fully** ready to invite beyond Adrian himself. The design-pass arc that started with S07 mockups + S08 #95/#96 auth + S09 dashboard-through-profile reaches every screen. The first-invite feedback loop closes inside one sprint, not staggered across two.

---

## What's NOT in this sprint (anti-scope)

Deliberately excluded:

- **Admin views Lumen migration** — admin is internal-only, low user-facing impact. Defer to S11+ when there's an admin-redesign reason.
- **i18n adoption** — closed wont-fix in S09 (#113). Re-visit triggers documented; don't re-litigate.
- **New JTBDs or features** — S10 is the design completion + invite-validation arc. New product surfaces wait for post-invite feedback to inform priorities.
- **Public landing / marketing site** — `/welcome` is the only public surface in scope; the marketing site is post-beta.
- **Performance benchmarking / load testing** — closed beta with ≤20 users doesn't generate load worth benchmarking. Defer until usage data exists.
- **Notification delivery (email/push) infrastructure** — #101 is inbox UI revamp only; actual email digest delivery is wired but not part of this sprint's scope to extend.

---

## 24h-pause rule note

S09 closed 2026-05-19. S10 opens 2026-05-20 — **24h-pause rule honored** (exactly 24h). Counter status:
- S05→S06: overridden
- S06→S07: overridden
- S07→S08: respected
- S08→S09: overridden (1st after the first respect)
- S09→S10: **respected** (today)

The rule is alive. Per the protocol, two consecutive overrides invalidate it; S09 was the override and S10 is the recovery. Honor maintained.
