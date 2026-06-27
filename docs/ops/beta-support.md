# Beta Support Runbook

> Operational runbook for handling bug reports and service incidents during the **closed beta** (≤20 invited friends). Internal-only — guidelines, not commitments to users.
>
> **Established:** Sprint S07 (2026-05-16).
> **Goal:** when a beta user reports something, don't improvise — follow this.

---

## Scope

This runbook covers two flows:

1. **Bug reports** — a user reports something not working as expected. Triggered by the `/report-bug` form, by direct email to `support@notdefined.dev`, or by a personal message.
2. **Service incidents** — Stockerly is down, slow, or producing wrong data for multiple users at once. Triggered by Sentry/Honeybadger alerts, Cloudflare tunnel failures, or a beta user reporting "no me carga nada".

**Out of scope** (for now): destructive changes (data reset, breaking migration). These are handled ad-hoc and the runbook will be extended when the first case appears.

---

## 1. Bug reports

### 1.1 How they arrive

The canonical channel is the **`/report-bug` form** inside the app (issue #77). When a logged-in user submits it, `BugReportMailer` sends an email to `support@notdefined.dev` with:

- `title` — the user's short summary
- `description` — the user's detailed explanation
- `user_email` — auto-attached for context
- `user_id` and current session info — for DB lookups during diagnosis

Out-of-band channels (direct email, WhatsApp message, in-person mention): valid but always **funnel them back into the email inbox** by replying "te escribo a `support@notdefined.dev` para tener registro" and continuing from there. Don't manage reports across multiple chat threads.

### 1.2 Triage

For each report, assign **one** severity tag in your head (no formal ticket system; severity is just how soon you respond):

| Severity | Definition | Response timing target (best effort) |
|---|---|---|
| **Blocker** | User cannot use the platform at all. Login broken, dashboard 500s, register fails, data corruption. | Same day or next morning |
| **Major** | A core feature is broken or wrong. Wrong portfolio math, alert never fires, FX rate stuck. User can use other parts of the app. | Within 48 hours |
| **Minor** | Visual glitch, copy typo, edge-case error message, browser inconsistency. | When time allows, batched |

Reproducibility check: before diving in, try to **reproduce the bug locally** with the user's reported steps. If you can't reproduce:

1. Reply asking for **one more clarifying question** — never two at once. Pick the highest-leverage gap (browser, OS, exact ticker, time of attempt).
2. Mark the report as "needs more info" mentally and move on. Don't burn time speculating.

### 1.3 Accessing logs and database in production

All commands run from your **local machine** (not the VPS). Load production env vars first:

```bash
set -a && source .env.production && set +a
```

Then:

| Need | Command | What it does |
|---|---|---|
| Tail current app logs | `bin/kamal logs` | Live tail; Ctrl-C to exit |
| Filter logs by request | `bin/kamal logs \| grep "request_id=<ID>"` | `config/environments/production.rb` sets `config.log_tags = [ :request_id ]`. User can find their `request_id` in HTML response headers (`X-Request-Id`) and forward it |
| Filter logs by user | `bin/kamal logs \| grep '"user_id":<ID>'` | `user_id` is included in the structured JSON body by Lograge (`config/environments/production.rb` lines 51-59 + `ApplicationController#append_info_to_payload`), so grepping the body works even though it's not in the Rails tag prefix |
| Rails console in prod | `bin/kamal console` | **Read-only by discipline**, not by enforcement. Use it to inspect, not to mutate, unless you have a fix-script and a backup |
| Bash shell in prod | `bin/kamal shell` | For diagnostic shell access (e.g., disk space, running processes) |
| PostgreSQL console | `bin/kamal db` | Direct `psql` on the production DB. Same discipline — read first, mutate only with explicit intent |
| App status | `bin/kamal details` | Is the container up? Last deploy? |

**Hard rule before any mutation in `bin/kamal console` or `bin/kamal db`:**

1. Take a snapshot of the relevant table(s) first (`pg_dump` of just those tables, or a `SELECT ... INTO` to a backup table).
2. Write the mutation as a transaction with explicit `BEGIN; ... ROLLBACK;` first to see what it would do.
3. Only then run with `COMMIT;`.

If you're tempted to skip these because "it's just a small fix", that's exactly when it goes wrong.

### 1.4 Fix workflow

1. **Open or update a GitHub issue.** If the user's report maps to an existing issue, comment on it; otherwise open a new one with `bug` + `ctx:*` labels. Reference the report email in the issue body.
2. **Branch from `master`:** `fix/<short-slug>` or `fix/<issue-number>-<slug>`.
3. **Reproduce in test first.** Write the spec that fails, then fix. If you cannot reproduce in test (genuine production-only condition like a race), document it in the PR description.
4. **PR with `Fixes #N`** and a clear "before/after" description. Self-review before requesting Gemini if it's a Blocker.
5. **Merge to master** → GitHub Actions deploys automatically via `.github/workflows/deploy.yml`.
6. **Verify in production.** Open the page, run the action, confirm. If it doesn't behave correctly after deploy: rollback (`bin/kamal rollback`), don't pile more changes on top.
7. **Communicate the fix** to the reporter (see §1.5).

### 1.5 Communicating with the reporter

Don't use templates — every reply is personal during the closed beta. **But follow these guidelines so the voice stays consistent**:

**Acuse de recibo** (within a few hours of receiving the report):

- Use `tú`, not `usted`.
- First-person from Adrian — this is a personal project.
- Acknowledge specifically what they reported, don't paraphrase it generically.
- State what's next: are you reproducing now, or will you look at it tomorrow? Don't promise a fix time unless you're sure.

Good example (acknowledge):
> Hola Pablo, gracias por reportarlo. Voy a tratar de reproducirlo hoy en la tarde y te aviso qué encuentro.

Bad example (faceless / generic):
> ¡Gracias por tu reporte! Nuestro equipo lo revisará en 24-48 horas hábiles.

**Mid-fix update** (only if it's taking longer than the user might expect — Blocker stuck >24h, Major stuck >72h):

- One line, no apology theater. Just status.

Good:
> Sigo en esto. El bug está en cómo calculamos el FX cuando hay un trade en USD el mismo día; estoy escribiendo el fix.

Bad:
> Lamento mucho los inconvenientes que esto te haya causado. Estamos trabajando con toda nuestra prioridad para resolverlo.

**Fix shipped** (after deploy + verification):

- Tell them what changed and how to verify on their end.
- Ask them to confirm; don't assume.

Good:
> Listo, el fix ya está en producción. Si vuelves a entrar a `/portfolio` deberías ver el valor correcto. ¿Me confirmas si ya te aparece bien? Si no, mándame screenshot.

**Cannot reproduce / closing without fix**:

- Honest about it. No "we couldn't replicate the issue at this time" template language.
- Leave the door open for the user to come back with more info.

Good:
> Probé varias veces con tu mismo ticker y no me pasa. ¿Puedes mandarme screenshot del error y el navegador que usas? Si vuelve a pasar, también ayuda saber la hora exacta.

---

## 2. Service incidents

### 2.1 Detection

Three signals, in order of who notices first:

1. **Sentry** (if `SENTRY_DSN` configured): unhandled exceptions surface in the Sentry project. Most common detection vector. Configure alerts to email/Slack for `error` and above.
2. **Honeybadger** (if `HONEYBADGER_API_KEY` configured): alternate error tracker — only one of Sentry/Honeybadger should be wired at a time to avoid duplicate alerts.
3. **Cloudflare tunnel status**: if the tunnel is down, the site returns 502 from Cloudflare. Check at `https://one.dash.cloudflare.com` → Networks → Tunnels.
4. **Healthcheck failures**: Kamal pings `/up` every 10 seconds; sustained failures trigger container restart. Inspect with `bin/kamal details`.
5. **A beta user reports "no me carga"**: when this happens before you got an alert, your alerting setup has a gap. Fix the alerting before fixing anything else.

### 2.2 Triage

When you suspect an incident, run this check sequence in under 60 seconds:

1. `curl -I https://stockerly.notdefined.dev/up` — does the app respond 200?
2. `bin/kamal details` — is the container running? Last deploy time?
3. Cloudflare dashboard → Tunnels → is `stockerly` tunnel "Healthy"?
4. `bin/kamal logs --lines 200` — recent errors at the app layer?
5. `bin/kamal accessory details postgres` — is PostgreSQL up?

If all five pass and you still suspect something: it's probably not an incident, it's a specific bug — go to §1.

If any fails: that's where to dig first. Don't tail logs hoping for clarity until you know which layer is broken.

### 2.3 Restoration

Restoration is **always preferred over fix-forward** during an incident. Get the site back up first, debug the root cause after.

Decision tree:

| Symptom | Action |
|---|---|
| Container down after recent deploy | `bin/kamal rollback` immediately |
| Container running but failing healthcheck | `bin/kamal logs --lines 500` → identify cause → if it's recent change: rollback; if it's env/config: fix env first, then `bin/kamal app restart` |
| Cloudflare tunnel down | `ssh deploy@<HOST_IP>` → `systemctl status cloudflared` → `sudo systemctl restart cloudflared` if needed. Verify with `journalctl -u cloudflared -f` |
| PostgreSQL down | `bin/kamal accessory restart postgres` — and check why; if disk is full, that's a different incident |
| Disk full on VPS | SSH in, identify what's eating disk (`du -h --max-depth=1 /`), usually old Docker images: `docker system prune -a` |
| Memory exhaustion | `bin/kamal app restart` for immediate relief; then investigate which process is leaking |

After restoration, **wait 10 minutes** before declaring it resolved. The same incident often re-fires when the underlying cause hasn't been addressed.

### 2.4 Communicating with affected users

During a closed beta with ≤20 friends, individual emails are appropriate. Use the same first-person voice as §1.5.

**During the incident** (if it lasts >15 minutes and is user-visible):

- Send one email to the active beta users.
- State what's happening and that you're on it. Don't speculate on cause.

Good:
> Hey, Stockerly está caído desde hace un rato. Estoy en eso, te aviso cuando vuelva.

**After resolution**:

- One line saying it's back up. If it was a data issue (e.g., portfolio values wrong for a window), be explicit about what was affected and what to verify.

Good:
> Ya está arriba. Si entraste entre las 14:00 y 14:25 y viste valores raros en tu portafolio, los recálculos ya se hicieron correctamente — refresca la página.

---

## 3. Appendices

### 3.1 Current production setup (summary)

| Component | Stack | Where |
|---|---|---|
| Hosting | Hetzner VPS, Ubuntu 22.04+ | Single server |
| Deploy | Kamal 2 | Triggered on push to `master` via GitHub Actions |
| Reverse proxy | kamal-proxy (Docker) | Bound to localhost:80 |
| Traffic ingress | Cloudflare Tunnel | No inbound 80/443 on VPS; only SSH (22) open |
| App container | Rails 8.1.2 + Puma | Port 3000, healthcheck `/up` |
| Worker container | Solid Queue | Same image as app, different command |
| Database | PostgreSQL 16 (Kamal accessory) | On-host container, persistent volume |
| Container registry | GHCR (GitHub) | `ghcr.io/rodacato/stockerly` |
| Error tracking | Sentry (preferred) / Honeybadger (alternate) | One at a time |
| Email | ActionMailer over SMTP (Resend if configured) | `RESEND_API_KEY` in env |
| Domain | `stockerly.notdefined.dev` | Cloudflare DNS |

Detail walkthrough lives in [`deploy.md`](./deploy.md) — this runbook references it; do not duplicate.

### 3.2 Internal SLA (not communicated publicly)

Stockerly does **not commit publicly** to response times during the closed beta. Internally, treat these as targets:

- **Blocker**: respond within the same day, fix attempt within 24 hours.
- **Major**: respond within 24 hours, fix attempt within 72 hours.
- **Minor**: respond within 72 hours, batch fix when convenient.

If you miss these, that's data for the retro — not an apology to write. The beta users are friends; they don't expect 24/7 ops.

### 3.3 Gaps and TODOs (S08+)

Known limitations of the current support setup, to address in future sprints if they become real friction:

- [ ] **No structured admin UI to look up a specific user's recent activity.** Today: open `bin/kamal db` and write SQL. Issue worth opening if it happens 3+ times in S07.
- [ ] **`user_id` not in Rails log tag prefix (cosmetic).** `user_id` is already in the structured JSON body via Lograge (`production.rb:51-59` + `ApplicationController#append_info_to_payload`), so filtering by user works today: `bin/kamal logs | grep '"user_id":<ID>'` (see §1.3 table). The remaining gap is cosmetic — `user_id` doesn't appear in the human-readable Rails tag prefix. If that becomes triage friction in S07, add `:user_id` to `config.log_tags` in `production.rb`.
- [ ] **No "freeze writes" mode** for the app during data-corrupting incidents. Today the only stop is `bin/kamal app stop` which takes the whole site down.
- [ ] **No status page** for beta users to check independently. Today: they email and ask. Acceptable for ≤20 users; reconsider if beta opens to more.
- [ ] **No automated digest of received bug reports** in the inbox. Today: read each email; works for ≤5/week.
- [ ] **No "Sentry vs. Honeybadger" decision made.** `deploy.md` mentions both; commit to one and remove the other from the env to avoid duplicate alerts.
- [ ] **No log retention policy.** Kamal logs are container-bound; if the container restarts, logs are gone. Consider shipping to a remote log sink before opening to >20 users.

---

## 4. Exercising this runbook

This document is only useful if it's been **exercised end-to-end at least once before a real report arrives.**

**Exercise** (run before declaring the runbook "done" on first read):

1. Open the app as `support@notdefined.dev` (test user).
2. Open `/report-bug` and submit a fake report: title `Test runbook`, description `Verifying runbook flow`.
3. Check the inbox at `support@notdefined.dev` — does the email arrive with `user_id` and email attached?
4. Open `bin/kamal logs` and grep for the test user's `user_id` — can you find their recent activity?
5. Open `bin/kamal db` and query for the test user — can you confirm what you saw in logs?
6. Write a reply to yourself following §1.5 acuse-de-recibo guidelines.

If any step has a gap (email doesn't arrive, log filtering doesn't work, DB query is awkward) — that's a real gap, fix before closing #78.

---

## 5. Support email routing (LFPDPPP Art. 32 obligation)

The published support address — `Stockerly::SUPPORT_EMAIL` in `config/initializers/stockerly.rb` — appears in:

- Privacy notice (`app/views/legal/privacy.html.erb`) — primary ARCO contact
- Terms of service (`app/views/legal/terms.html.erb`) — general inquiries
- Risk disclosure (`app/views/legal/risk_disclosure.html.erb`) — broker-discrepancy reports
- In-app welcome / help (`app/views/shared/_welcome_body.html.erb`) — general support
- Bug-report mailer recipient (`app/mailers/bug_report_mailer.rb`)
- ARCO procedure (`docs/ops/arco-procedure.md`)

**LFPDPPP Art. 32 obligation:** when a user exercises an ARCO right (Acceso / Rectificación / Cancelación / Oposición), the data controller must respond within **20 business days**. If `support@notdefined.dev` doesn't actually route to Adrian's monitored inbox, the obligation is violated the moment the first ARCO request is sent.

### Required pre-flight check (before each new beta-cohort invite)

1. From an external address (Gmail, personal email — anything outside `*.notdefined.dev`), send a test message to `support@notdefined.dev` with subject `[Stockerly ops] routing check YYYY-MM-DD`.
2. Confirm it lands in Adrian's monitored inbox within 5 minutes.
3. If it bounces or doesn't arrive: the alias is broken. Fix the DNS forwarder / Resend configuration before sending any beta invite.
4. Note the date of the last successful routing check in this file (replace the line below).

**Last verified:** `_pending Adrian's confirmation (issue #169)_`

### When changing `Stockerly::SUPPORT_EMAIL`

If the constant is updated to a different address:

1. Run the pre-flight check above against the new address.
2. Grep the entire repo for any remaining hardcoded references to the old address (e.g., `grep -r "support@old-address" .`). All consumer code should reference the constant; ops docs may have literal historical references that are fine — review case by case.
3. Update the runbook and ARCO procedure if the address change has operational implications (e.g., new monitored inbox owner, different SLA).

---

## 6. UserActivity queries

> Added Sprint S12 (#172). The `user_activities` table records (a) page views on tracked authenticated controllers (`dashboard#show`, `market#index|show`, `portfolios#show`, `alerts#index`, `earnings#index`, `notifications#index`, `profiles#show`) and (b) three event-driven actions: `trade_executed`, `alert_rule_created`, `watchlist_item_added`.
>
> Use these from `bin/kamal console` when a beta-amigo report is vague ("no me funciona") and you need to know what the user actually touched before they reported.

### Canonical queries

**1. What did user N do this week?**

```ruby
UserActivity
  .where(user_id: N)
  .where("occurred_at > ?", 7.days.ago)
  .order(occurred_at: :desc)
```

Returns the user's full activity stream — page views interleaved with action events. Read top to bottom to reconstruct the session.

**2. Is anyone touching the watchlist feature?**

```ruby
UserActivity.by_action("watchlist_item_added").last(20)
```

Swap the action string to triage other features: `"trade_executed"`, `"alert_rule_created"`, `"page_view:earnings#index"`, etc. If the count is zero over the last week, that feature is effectively dead in the beta — useful signal for S13 prioritization.

**3. Which user is most active this month?**

```ruby
UserActivity
  .where("occurred_at > ?", 30.days.ago)
  .group(:user_id)
  .count
  .sort_by { |_, v| -v }
  .first(5)
```

Returns the top-5 user_ids by row count. Combine with `User.where(id: ids).pluck(:id, :email)` to put names on the numbers.

### Conventions

- `action` strings are technical identifiers in English (`"trade_executed"`, `"page_view:dashboard#show"`), not user-facing copy. Stable across releases — safe to grep, group, and filter.
- `params` is JSONB and varies by action. Trade rows carry `asset_symbol`, `side`, `shares`. Page-view rows carry `controller` + `action`. Don't depend on a key existing for every row.
- All inserts go through `ActivityRecorder.call(user:, action:, params:)`. New actions plug in by calling it from a handler or controller. Direct `UserActivity.create!` from caller code is a smell — funnel through the recorder so the nil-user guard and error swallowing are uniform.

## 7. Sync health alerts

Recurring `CheckSyncHealthJob` (runs hourly at `:45`) inspects the `SystemLog` table for each critical data sync and fires a Sentry warning when a sync has been silently failing — that is, **errors in the last 25 hours AND zero successes in the same window**. The goal is for Adrian to learn about stale FX rates / prices / news / earnings / CETES *before* a beta amigo notices an outdated number on the dashboard.

### What triggers the alert

For each task name in `CheckSyncHealthJob::CRITICAL_SYNCS`:

- `"FX Rate Refresh"`
- `"Bulk Stock Sync"`
- `"Bulk BMV Sync"`
- `"Bulk Crypto Sync"`
- `"News Sync"`
- `"Earnings Sync"`
- `"CETES Sync"`
- `"Market Indices Sync"`

The job runs this rule:

```ruby
logs = SystemLog.where(task_name: task).where("created_at > ?", 25.hours.ago)
alert if logs.where(severity: :error).exists? && !logs.where(severity: :success).exists?
```

A single recent success "cures" prior errors — a sync that hiccupped at 3am but recovered at 4am is healthy and silent.

**Dedup:** alerts are suppressed for **6 hours** per task via `Rails.cache` (Solid Cache in production). Two consecutive hourly runs against the same stuck sync produce one Sentry event, not 24/day.

### Where to see it

- Sentry project dashboard (Adrian's account; DSN configured via `SENTRY_DSN`)
- Look for warnings with message `Sync failing: <task name>`
- The `extra` payload includes `task_name`, `last_error_at`, `last_error_message`, `last_success_at`, `lookback_window`

### How to investigate when it fires

1. Pull the last few SystemLog rows for the failing task:

   ```ruby
   # bin/rails console (prod)
   SystemLog
     .where(task_name: "FX Rate Refresh")
     .where("created_at > ?", 25.hours.ago)
     .order(created_at: :desc)
     .limit(5)
     .pluck(:created_at, :severity, :error_message)
   ```

2. Cross-check the upstream gateway — most failures map to:
   - `FX Rate Refresh` → ExchangeRate API key / quota (`Integration.find_by(provider_name: "ExchangeRate")`)
   - `Bulk Stock Sync` / `Bulk BMV Sync` → AlphaVantage / Polygon rate limits
   - `Bulk Crypto Sync` → CoinGecko rate limits
   - `News Sync` → NewsAPI quota
   - `Earnings Sync` → AlphaVantage `EARNINGS_CALENDAR`
   - `CETES Sync` → Banxico SIE (returns null on weekends/holidays — false-positive risk on Mondays only if it actually didn't recover Sunday)
   - `Market Indices Sync` → Polygon
3. If the upstream is healthy, check `bin/kamal logs | grep <JobName>` for stack traces.
4. Re-run the job manually to confirm fix: `bin/rails runner "RefreshFxRatesJob.perform_now"` (substitute the affected job).

### How to silence a known-broken sync temporarily

If a sync is broken upstream and you don't want the hourly Sentry noise until the fix ships:

1. Open `config/recurring.yml` and comment out the failing job entry (e.g. `# sync_cetes:` block) so it stops producing new error rows.
2. Optionally clear the dedup key so the next genuine failure alerts immediately when the sync resumes:

   ```ruby
   Rails.cache.delete("sync_health_alert:CETES Sync")
   ```

3. Re-deploy. Document the silenced sync + ETA in the deploy notes so it doesn't stay silenced forever.

To add a new monitored sync, append its exact `task_name` string to `CheckSyncHealthJob::CRITICAL_SYNCS` — must match the literal string used in the corresponding `SystemLog.create!` / `log_sync_success` / `log_sync_failure` call (see `app/jobs/concerns/sync_logging.rb`).

## 8. Email delivery query

Resend webhooks (`POST /webhooks/resend`) persist every email lifecycle event to the `email_events` table. Use it to answer "did the amigo get the invite?" without poking through provider dashboards.

**Setup requirement.** `RESEND_WEBHOOK_SECRET` (the `whsec_...` signing secret from the Resend dashboard) MUST be set in the production env. The controller rejects every request with `401` when it's missing — no dev fallback. The webhook URL to register in Resend is `https://stockerly.notdefined.dev/webhooks/resend`.

**Common queries** (run from `bin/kamal console` on prod):

```ruby
# "Did amigo X get the invite?"
EmailEvent.for_email("amigo@example.com").recent.pluck(:event_type, :occurred_at)

# "Was a specific message delivered?"
EmailEvent.for_message("email_abc123").by_type("delivered").any?

# "Did anyone bounce in the last week?"
EmailEvent.by_type("bounced").where("occurred_at > ?", 7.days.ago).pluck(:email, :occurred_at)

# "Show me the full lifecycle of one message (sent → delivered → opened → clicked)"
EmailEvent.for_message("email_abc123").recent.pluck(:event_type, :occurred_at)
```

**Event types** mirror Resend with the `email.` prefix stripped: `sent`, `delivered`, `bounced`, `complained`, `opened`, `clicked`.

**Limitations.** Stockerly sends mail via Resend SMTP (no Ruby SDK), so we have no programmatic `message_id` at send time. The `sent` row is created by the webhook itself when Resend fires `email.sent`. If a webhook is dropped, that send is silently missing from the table — diagnose via Resend's own dashboard log retention.
