# Strategic Audit Synthesis — 2026-05-23

> Cross-cutting findings from 8 expert reports, mapped against Adrian's stated goal: **"Stockerly as my principal site for informed investment decisions on a MXN+USD portfolio, polished + extended with the right data sources."**
>
> 1 day after S11 close. 2 days after first beta amigo invite (zero response). Audit run because Adrian asked: *"what we have, what delivers value, what's missing, what doesn't work"* — with expert help.

---

## Cross-cutting findings (mentioned by ≥2 experts)

### F1 — Multi-currency calculators are incomplete and the dashboard may be lying

**Surfaced by:** C1 Lucía (primary), C6 Esther (cross-reference).

Trade capture stores `fx_rate_at_execution` correctly. `Position#avg_cost_in()` calculates correctly. But the 8 downstream calculators (`PortfolioSummary#total_invested`, `unrealized_gain`, `daily_gain`, period returns, allocation by sector/type, monthly/inception gain, comparison helpers) **may still be using the pre-fix arithmetic**. Lucía traces a concrete scenario where the numbers could diverge from the broker's statement.

The risk surface: a beta amigo opens the dashboard, sees a number that doesn't match their broker's statement, never opens the app again. Trust decay with no recovery.

**Status:** Needs audit-then-fix. Could be already correct in some calculators (S08 #105 fixed some); needs a per-calculator scenario trace.

**Severity:** P0 if any calculator still wrong. Blocks more invites.

---

### F2 — Visual coherence migration is only ~60% done

**Surfaced by:** C5 Renata (primary), C6 Esther (mentions "looks beautiful but"), S2 Adriana (donut chart hardcoded hex).

S11 closed the CSS-token migration (#142) and 6 design completions, but:
- Card chrome uses `bg-white dark:bg-slate-900` literals instead of `bg-bg-surface` token names (~30 files)
- Sidebar headings use pre-Lumen typography (no eyebrow pattern)
- Auth pages use `shadow-xl` (too heavy per brand) and cold-slate dark
- Portfolio allocation donut uses hardcoded `#005A98` (pre-Lumen primary)
- Some English strings still leak (`title="Open"/"Closed"` in `index_card`)

**Severity:** P1 — micro-inconsistencies add up to "Stockerly feels assembled from different sources" in a beta amigo's eye. Renata calls it 6.5/10 today, 8.5/10 after the fixes.

**Effort:** Renata estimates ~3 hours total across 3 PRs.

---

### F3 — Invite-code flow has ops gaps (race-condition finding RETRACTED)

**Surfaced by:** C7 Fadia (enumeration), S1 Olusegun (no expiration, no click tracking).

**CORRECTION (added after gemini-code-assist review of PR #178):** Fadia's "race condition" finding is a false positive. [`Register#persist_with_invite`](../../../app/contexts/identity/use_cases/register.rb#L17-L36) wraps the flow in `ActiveRecord::Base.transaction` and uses `InviteCode.lock.find_by(code:)`, which generates `SELECT ... FOR UPDATE`. PostgreSQL acquires a row-level lock that blocks any concurrent transaction trying to read the same row until commit. By the time a second registration's lock is granted, the row reflects the first registration's `used_at` update, and the `if invite.used?` guard catches it. Fadia's evidence (citing the `.lock` call) is what defeats her own conclusion — `.lock` inside an explicit transaction is the textbook fix to the race she described. Lesson: even 12-year-experience expert personas can misread `.lock` outside of an explicit transaction context. Always verify expert findings against the actual code.

**What remains real in this finding:**
- **C7 HIGH:** Distinct error messages leak whether a code exists / is used (enumeration). 30 min to normalize.
- **S1 MEDIUM:** No expiration timestamp; codes live forever. 1 hour to add.
- **S1 HIGH:** No tracking of whether the invite email was delivered/opened/clicked. 2-3 hours via Resend webhooks (separate issue, F5).

These compound: the invite flow is the single gate to the beta cohort and currently has weak observability + enumeration leak.

**Severity:** P1 (downgraded from P0 — the race-condition fear was the P0 driver, and it's not real).

**Effort:** ~1.5 hours for enumeration + expiration. Resend webhooks (3h) tracked separately as F5.

---

### F4 — Banxico FX is not authoritative

**Surfaced by:** C1 Lucía (primary), S2 Adriana (cross-reference).

`FxRatesGateway` hardcodes exchangerate-api.com (free, generic). Banxico's `TC_TC002` series publishes the official MXN/USD fix daily at 10:30 AM Mexico City — free, authoritative, and we already have the Banxico integration in place from #133. Drift is 0.5-1% daily.

For an MX-focused product where the dashboard is the trust signal, this is the single highest-leverage data-source fix.

**Severity:** P1 — not breaking math today (within margin), but trust differentiator.

**Effort:** ~2 hours.

---

### F5 — Zero usage data exists; we're building blind

**Surfaced by:** C6 Esther (primary — the "silent failure" framing), S1 Olusegun (instrumentation gap), C1 Lucía (suggests render-pass-spot-check ritual).

Esther's evidence: JTBD #2 (drawdown alerts) shipped 4 sprints ago, Adrian has never opened the badge despite having positions down 25-30%. Silent non-use across 4 sprints. Olusegun's framing: "you'll only know they're using it when something fails."

The S10 retro already flagged this ("we shipped capacity for use, not use itself") but no instrumentation followed. Now there's a real beta amigo using/not-using and we can't tell which.

**Severity:** P0 for decision-making capacity — every future sprint's scope decision depends on this signal.

**Effort:** ~3 hours for a basic `UserActivity` table per Olusegun.

---

### F6 — Sync jobs fail silently into SystemLog with no alerting

**Surfaced by:** S1 Olusegun (primary), S3 Yui (Bullet only in dev), C1 Lucía (stale data risk).

`SystemLog` captures errors. The `/health` endpoint flags `degraded` / `critical` after thresholds. But neither raises an alert proactively — Adrian only learns when:
- He opens `/health` manually, OR
- Pablo (the amigo) messages "the data looks wrong"

Combined with F5: the system is correct most of the time, but when it breaks we won't know until a human notices.

**Severity:** P1.

**Effort:** ~1-2 hours for the hourly `CheckSyncHealthJob`.

---

### F7 — Stockerly does NOT route to a real support email

**Surfaced by:** S5 Ileana (primary, legal).

`Stockerly::SUPPORT_EMAIL` points at `support@notdefined.dev`. If Adrian doesn't actually own/monitor this address, the published privacy notice references an unreachable channel — Art. 32 LFPDPPP violation the moment anyone exercises an ARCO right (access/rectification/cancellation/opposition).

**Severity:** P0 legal risk.

**Effort:** 15 minutes.

---

## Items mentioned by single experts (still worth flagging)

### From C7 Fadia
- No audit log UI (admin can't read AuditLog rows). P2.
- Session cookie `Secure` flag conditional on `Rails.env.production?` only. P2, 5 min fix.
- Password reset token reusable until expiry. P2.

### From S2 Adriana
- **Alpha Vantage at 25 calls/day** is dangerously under-provisioned for the fundamentals job. P1.
- Polygon news gateway is redundant with Finnhub — wastes 500 calls/day. P2, 1 hour cleanup.
- No minute-throttle on Yahoo Finance (only daily limit). P2.
- **Bitso integration** for native BTC/MXN pricing. Not urgent but high-value-add for MX investor. P3.
- CETES sync overwrites prior week's yield (one asset per term, not per auction). P2 if Adrian buys CETES frequently.

### From S3 Yui
- Two missing indexes (`alert_rules` partial-on-status, `positions` composite with maturity_date). P2, 1 hour.
- Bullet not enabled in staging. P2, 5 min.
- Solid Queue worker count not tuned (1 worker default). P2.

### From S5 Ileana
- No in-app "delete account" flow (ARCO Cancelación). P1 before cohort >5.
- No "export my data" flow (ARCO Acceso). P1 before cohort >10.
- Cookie disclosure missing from privacy notice. P3.
- Resend DPA not on file. P3.

### From C5 Renata
- Fear & Greed card visually dense. P3.
- No interactive affordance on sparklines (cursor-pointer or none). P3.

### From C6 Esther
- **JTBD #2 (drawdown alerts) should be killed** if Adrian doesn't actually use it. 2 hours of cleanup. P2.
- 8 "while we're here" features (news, watchlist, analyst targets, F&G, statements) are unvalidated. Wait for amigo feedback before building on top of them. Policy, not effort.

---

## P0/P1/P2 priority bands

### P0 — Ship before next invite or amigo discovers it

| Item | Source | Effort |
|---|---|---|
| F7 — Real support email | S5 | 15 min |
| F1 — Audit/fix multi-currency calculators | C1, C6 | 4-8h |
| F5 — Basic UserActivity tracking | C6, S1 | 3h |

**P0 total:** ~7-11h. (F3 race-condition finding retracted post-gemini-review; enumeration + expiration moved to P1.)

### P1 — Ship within next 2 sprints, before cohort hits 5

| Item | Source | Effort |
|---|---|---|
| F2 — Lumen migration completion (cards/sidebars/auth) | C5 | 3h |
| F4 — Banxico FX rates | C1, S2 | 2h |
| F6 — Sync job failure alerting | S1, S3 | 1-2h |
| Email delivery webhooks (Resend) | S1 | 2-3h |
| Invite code expiration + enumeration fix | S1, C7 | 1.5h |
| In-app account deletion | S5 | half day |
| Alpha Vantage right-sizing | S2 | 2-4h |

**P1 total:** ~12-17h.

### P2 — Ship when convenient

(JTBD #2 cleanup, admin AuditLog UI, performance indexes, Bullet in staging, Solid Queue tuning, Polygon news cleanup, cookies disclosure, Resend DPA, etc.)

---

## Cross-cutting strategic insights

### Insight #1 — The product is structurally complete; the gaps are quality, trust, and feedback loops

Every expert independently said some version of "the foundation is right". 11 sprints shipped:
- 4 of 6 JTBDs working (Esther) ✅
- Multi-currency architecture correct (Lucía) ✅
- IDOR-safe controllers (Fadia) ✅
- Solid hexagonal architecture for gateways (Adriana) ✅
- Above-average Rails performance posture (Yui) ✅
- Lumen design system 60% wired (Renata) ⚠️
- Privacy notice published + ARCO documented (Ileana) ✅
- Lograge + Sentry + health endpoint (Olusegun) ✅

The pattern: **structure is done; calibration is missing**. Calculators that read but don't write through the new fields. CSS tokens that exist but aren't applied. Gateway chains that work but aren't observed. Privacy notices that name an unreachable email.

This is the *single most consistent finding* across 8 independent lenses. It's the same gap S11 closed for visual (tokens defined, never wired) — now repeating in 4-5 other layers.

### Insight #2 — Adrian is the bottleneck, not the codebase

Esther's "silent failure" of JTBD #2 + Olusegun's "no usage data" + the S10 retro's "preparing-but-not-sending invites" all point at the same meta-pattern: Adrian builds features, then doesn't validate them against his own use. Two of the eight experts independently recommended a recurring **render-pass-spot-check ritual** (Lucía: "15 min in browser per sprint", S11 retro action item).

Until Adrian (and now beta amigos) actually generate usage signals, S12+ scope decisions remain guesses. **Instrumentation isn't a feature — it's the only thing that turns the next sprint from a guess into a decision.**

### Insight #3 — Beta amigo silence is the actionable signal we have

48 hours since invite. Zero #150 traffic. The S11 retro framed this as "wait and see". But Olusegun's audit changes the framing: **we don't know if the amigo got the email, opened it, clicked the link, or hit a bug at registration.** The silence isn't necessarily "amigo busy"; it could be "amigo never made it to the dashboard."

Adding Resend webhooks (~3 hours) turns the silence from inscrutable to diagnosable. Combined with `UserActivity` (~3 hours), you'd know within hours of the second invite whether the channel is working.

### Insight #4 — There is no "kill what's dead" discipline

Esther: kill JTBD #2 (drawdown). Adriana: kill Polygon news. Both small features that exist but don't earn their keep. The bias in 11 sprints has been "ship more"; almost never "delete what nobody uses." This is the inverse of scope creep: zombie features.

A sprint that includes ONE explicit "kill what's dead" issue would be a healthy counterweight to the build-bias.

### Insight #5 — Compliance, security, observability are all "one good afternoon" of work

Fadia's race-condition fix: 1-2 hours. Ileana's support email fix: 15 min. Olusegun's email tracking: 2-3 hours. Yui's indexes: 1 hour. **These aren't multi-sprint architectures. They're small specific fixes that have been deferred because no failure has demanded them yet.**

The next failure (and there will be one) will demand them all at once on a Friday at 11pm. Shipping them proactively in a focused "hardening sprint" before cohort >5 is cheaper than any one of them under incident pressure.

---

## What this tells us about S12 shape

(Detailed proposal in `S12-proposal.md`.)

Two shapes possible:

**Shape A — "Hardening + Instrumentation" sprint (4-6 issues, ~15-20h):**
The P0/P1 bundle above. Ships invite-flow safety + calculator audit + Banxico FX + UserActivity + Lumen completion + support email. After this sprint, Adrian can invite cohort #2 with much higher confidence and actually know what they do.

**Shape B — "Wait for amigo" sprint (2 issues, ~3h):**
Only the legal blocker (F7 support email) and the security blocker (F3 invite race). Everything else waits for amigo feedback to validate priority. Smaller, more honest about the unknown.

My recommendation is Shape A: the P0/P1 work is high-confidence (8 independent experts agreed on the pattern) and unlocks the ability to learn from cohort #2 honestly. Shape B is too cautious — it leaves Adrian with the same dilemma in 2 weeks.

But this is Adrian's call.

---

## Appendix: where each item lives

- `C1-lucia-mx-financial-domain.md` — multi-currency calculators, FX, CETES, vocabulary
- `C5-renata-ux-fintech.md` — Lumen migration gaps, info hierarchy, copy
- `C6-esther-jtbd-value-audit.md` — JTBD scorecard, kill list, scope creep
- `C7-fadia-security.md` — invite race, IDOR, sessions, audit log
- `S1-olusegun-observability.md` — email tracking, sync alerts, disk monitor, runbook
- `S2-adriana-data-sources.md` — provider inventory, Banxico FX, Bitso, Alpha Vantage
- `S3-yui-performance.md` — N+1 risks, missing indexes, Bullet, Solid Queue tuning
- `S5-ileana-legal-mx.md` — privacy notice, ARCO flows, support email, cookies
