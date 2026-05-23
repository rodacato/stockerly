# S1 Olusegun Adebayo — Observability & Ops Audit

> "Stockerly is operationally blind the moment an amigo clicks the invite link. You'll know something broke only when he tells you it's broken, and you'll have three hours of grep before you know what to fix."

## State of the product through my lens

Stockerly shipped the scaffolding for observability but missed the foundations. You have Sentry configured as a top-level error sink, JSON-structured logging to STDOUT with request IDs, and a `/health` endpoint that monitors data freshness — these are the right pieces. But there's a critical gap: **nothing tracks whether the beta amigo actually opened the invite email, clicked the link, or registered successfully.** The first 48 hours of the beta will be blind. Beyond that, observability is focused on **what breaks** (Sentry errors, log tails) rather than **whether anything is actually being used** (page views, feature adoption, button clicks). This is the meta-anti-pattern: you built the product for someone to use, but you'll only know they're using it when something fails.

The second flaw is subtler: **background jobs fail silently into SystemLog and disappear.** A sync job can miss data for three days and you won't wake up at 3am — you'll discover it at standup when your one beta amigo complains that prices are stale. The job retry logic exists (`retry_on Faraday::Error`), but errors go into SystemLog, which rotates after 90 days. You have no alerting on "sync job X hasn't succeeded in >24 hours."

Third flaw: **the incident runbook assumes you have time to debug.** It's operationally sound (Kamal rollback, log tails, console access all documented), but it's missing the first 60 seconds: "Did the database fill the disk? Did the container run out of memory? Is the Cloudflare tunnel down?" You have load logs at 50m max-file, which is reasonable, but no warning sign before the disk fills.

### What delivers value (already shipped)

1. **Structured JSON logging via Lograge.** One line per HTTP request with `request_id`, `user_id`, `ip` in the body. This is excellent for production triage. A bug report like "my portfolio is wrong" becomes `bin/kamal logs | grep '"user_id":123` and you get every action that user took.

2. **Request ID propagation.** The healthcheck endpoint skips logs, but all authenticated requests include `request_id` in the Rails tag prefix. If an amigo gives you a request ID from the browser header, you can tail that one conversation in production. This is a luxury in a small beta.

3. **Health endpoint (`/health`) monitors sync freshness.** Prices stale >15min? Status is "degraded". Prices stale >1 hour? Status is "critical". This is *exactly* the right metric for a data-driven product. The endpoint returns JSON with ISO8601 timestamp, making it machine-readable for a future healthcheck monitor.

4. **SystemLog model with scopes.** `SystemLog.errors`, `SystemLog.last_24h`, `SystemLog.by_module` are there. Sync jobs log success/failure with error messages. If you need to investigate "why did the FX sync fail on Thursday?", you can query it. This is queryable history, not just noise.

5. **Sentry configured with breadcrumbs and tracing.** `active_support_logger` breadcrumbs mean that exceptions include the last 10 log lines before the crash. If a trade-execution job throws, you see what it tried to do. Traces are sampled at 0% by default (`SENTRY_TRACES_SAMPLE_RATE=0.0`), which is correct for production — don't burn quota on tracing until you need it.

6. **Kamal deployment includes health checks.** The proxy pings `/up` every 10 seconds. If Rails fails to boot, the container is restarted automatically. This prevents the "app is wedged, nobody noticed" failure mode.

---

## What's missing (prioritized)

### 1. **No tracking: Did the beta amigo even click the invite link?**

**What we can't see:** Whether the invite email was delivered, opened, or the link was clicked. You sent an invite on 2026-05-21 at time T, the amigo's email is in your inbox, but you have no record that he accessed the registration link. He might be on a plane. He might have filtered the email as spam. Resend (your SMTP provider) can track this, but you haven't wired it.

**Why we need it:** The first 24 hours of beta are your best signal. "Did the amigo register?" is the simplest diagnostic question. Right now the only way to answer it is: open `bin/kamal db` and query `users.created_at > '2026-05-21'`. That's a single human amigo, so it's trivial today, but this doesn't scale to five amigos.

**Smallest-thing-that-could-work:** Wire Resend webhooks (bounce, delivered, complaint) to write a simple `EmailDeliveryLog` table with `(email, event_type, timestamp)`. When you send an invite, log the event. When Resend fires a webhook, log that. No fancy dashboards — just queryable history. Cost: 2 hours to add the webhook endpoint, 1 hour to test with Resend's test events.

---

### 2. **No alerting: If a sync job fails silently for 3 days, you won't know.**

**What we can't see:** A recurring job like `SyncEarningsJob` or `RefreshFxRatesJob` can hit a transient error (API rate-limited, provider down), fail to retry successfully, and just... stop running. The job logs to `SystemLog` with severity `:error`, but there's no alert rule. The health endpoint will eventually mark FX rates as "critical", but that's a lagging indicator — it takes 2 hours before the threshold triggers.

**Why we need it:** Prices matter. If the FX rate is 3 days stale and the amigo's portfolio is valued at stale rates, he'll notice before you do. The moment he says "these numbers look wrong", you're in firefight mode. Proactive alerts let you fix it in development before he sees it.

**Smallest-thing-that-could-work:** Add a Solid Queue recurring job `AlertOnFailedSyncJob` that runs hourly and checks for failing-without-success sync log entries in the last 24h; capture warnings to Sentry. Cost: 1 hour. No infrastructure changes, no dashboards, just a cron that looks at what you already log.

---

### 3. **No database size monitoring: You'll discover "disk full" when the app crashes.**

**What we can't see:** PostgreSQL on your Hetzner VPS is in a Docker container with a persistent volume. The volume has no quota set (implicit: "as big as the host disk"). You're writing 200+ rows/day to `SystemLog`, plus trade snapshots, plus price history. Nobody's watching the actual disk usage. The Kamal config has log rotation (50m per file, 3 files max), which is fine, but you're not asking: "What if the Postgres WAL grows unbounded? What if backups start failing silently?"

**Why we need it:** A full disk is a database crash. The app will try to write a trade and get an ENOSPC error, which will 500. By the time the amigo reports it, you've lost 15 minutes of writes. If this happens at 11pm Friday, you're rolling back and then investigating in the dark.

**Smallest-thing-that-could-work:**
- Add a `/health` sub-check: disk usage on the postgres volume, return "warning" if >80% used, "critical" if >95% used.
- Add a recurring job `MonitorDiskSpaceJob` that runs daily and logs current disk usage to `SystemLog`.
- Cost: 2 hours.

---

### 4. **No user activity tracking: You have no idea what features are actually used.**

**What we can't see:** Does the amigo look at the Earnings tab? Does he create any alerts? Does he ever visit the Market page? When you ship a feature, you have no signal that it's being used. All you know is: "He's logged in" (you can grep the request log for his `user_id`). Everything else is blind inference.

**Why we need it:** In three months when you have five amigos, you won't know which features are worth building on. Is the watchlist feature used? Are alerts set by anyone? Does anyone actually care about the Fear & Greed index? Without this data, you'll build the next feature by guessing.

**Smallest-thing-that-could-work:** Add a `UserActivity` table with `(user_id, action, timestamp)`. On every significant page load or action (dashboard view, alert created, trade executed, earnings clicked), write one row. No dashboards — just raw log data. You can count later. Cost: 3 hours (add table, add callbacks/event subscriptions, test). This is cheap enough to do before cohort > 1.

---

### 5. **No timeout configuration: If a price-sync job hangs, Solid Queue will wait forever.**

**What we can't see:** A `SyncSingleAssetJob` makes HTTP calls to external gateways (Polygon, Yahoo Finance, CoinGecko). Those HTTP calls have no timeout set. If a gateway is slow or hanging, the job can be stuck for minutes. With 100+ assets, you could have a dozen jobs hanging at once, blocking the queue. The healthcheck will eventually flag prices as stale, but that's after you've already lost 15 minutes to queuing.

**Why we need it:** Queue saturation kills availability. Slow requests lead to slow jobs lead to blocked queue lead to platform feels broken.

**Smallest-thing-that-could-work:** Set a timeout in the HTTP client. In `SyncSingleAssetJob`, wrap the gateway call with a timeout: `Timeout.timeout(5) { gateway.fetch_price(...) }`. If it times out, treat it as a transient error (retry). Cost: 30 minutes.

---

## What doesn't work (operationally)

### 1. **Invite code has no expiration; no tracking of "click attempts".**

The `InviteCode` model has `used_at` and `used_by_user_id`, but once a code is generated, it's valid forever. If you generate a code and the amigo sits on it for two weeks, the code still works. Fine for internal testing; brittle at 20 amigos.

**Incident scenario:** Adrian invites Amigo #3 on Monday. By Friday, Adrian doesn't know if Amigo #3 is slow, if the email was spam-filtered, or if Amigo #3 is traveling. Without invite code expiration + a cleanup job, your "who's been invited and active" list becomes unreliable by month 2.

**Fix:** Add expiration to `InviteCode`: `expires_at = created_at + 7.days`. When registration happens, validate `used_at is null AND expires_at > now`. Add a recurring job that marks expired codes as unusable. Cost: 1 hour.

---

### 2. **Solid Queue has no built-in alerting for dead-letter jobs.**

When a job exhausts retries, Solid Queue discards it (or marks it failed in the `solid_queue_jobs` table). You have the health endpoint monitoring data freshness, but no dedicated alert for "a sync job is permanently stuck."

**Incident scenario:** `SyncEarningsJob` fails due to a provider schema change. Retries exhaust. The job is gone from the queue. The health check still passes (FX rates are fresh, prices are fresh). But earnings are two weeks stale.

**Fix:** Add a recurring job that queries `SolidQueue::Job.where(finished_at: not null, status: failed)` and groups by `class_name`. If any class failed >5 times in the last 24h, log a warning to Sentry. Cost: 1 hour.

---

### 3. **No "warm-up" or "slow startup" protection.**

When the container starts, Rails has to boot, precompile bootsnap, load gems, initialize Sentry, etc. During this window (10-30 seconds), the app is alive but slow. The healthcheck `/up` returns 200 immediately (it's just Rails booting), but database queries are slow.

**Incident scenario:** A deploy finishes at 3pm. The container restarts. For 20 seconds, the app is "up" but slow. An amigo makes a request at second 15, hits the slow handler, times out. He refreshes and it's fast. But the first request was never logged to Sentry (wasn't an error, just slow).

**Fix:** Kamal's healthcheck already has a 5-second timeout and 10-second interval. You're already protected by Kamal restarting if healthcheck fails for 3 attempts. The gap is visibility, not functionality. Just note this in the runbook: "Early requests after deploy may be slow; this is normal for 30 seconds."

---

## Top 3 recommendations: minimum-viable observability before cohort > 5

### #1: Email delivery tracking (Effort: 2-3 hours, Unlocks: answer "did he get the invite?")

**What to instrument:**
- Wire Resend webhooks (delivered, bounce, complaint, open) to a simple `EmailEvent` table.
- Log every invite email sent: `InviteCodeMailer#send → log to EmailEvent`.
- Query: `EmailEvent.where(email: 'amigo@example.com', event_type: 'delivered').any?`

**Why it's first:** The first question Adrian will ask on day 1 is "did he get the email?" Without this, you're guessing. With it, you know in 10 seconds.

**Runbook implication:** When beta amigo doesn't show up by noon, Adrian can grep the email log and see: "Email delivered at 08:47, not opened, link not clicked." Then he can ping the amigo on WhatsApp with confidence: "Did you get my email?"

---

### #2: Sync job failure alerting (Effort: 1-2 hours, Unlocks: proactive detection of stale data)

**What to instrument:**
- Add a recurring job `CheckSyncHealthJob` that runs hourly.
- For each critical sync (FX Rates, Prices, Earnings, News), query `SystemLog` for the last success and last error.
- If (now - last_success) > 25h OR (last_error is recent AND no recent success), send an alert to Sentry at level `warning`.

**Why it's second:** The health endpoint flags stale data reactively. This flags stale data proactively, *before* the amigo notices.

**Runbook implication:** When an alert fires (e.g., "FX Rates sync failing"), Adrian opens the Sentry issue, sees the alert was triggered at 3:15pm, clicks through to the `SystemLog` entry, sees the exact error message, and either auto-fixes it or escalates.

---

### #3: Disk space monitoring (Effort: 1-2 hours, Unlocks: avoid "disk full" crashes)

**What to instrument:**
- Add a `/health/storage` endpoint that checks the postgres volume and returns `{"status": "ok|warning|critical", "used_percent": 75}`.
- Integrate into existing `/health` response: add `storage` key to the checks dict.
- Add a recurring job that logs disk usage daily to `SystemLog`.

**Why it's third:** Less frequent impact than sync failures, but catastrophic when it happens. A full disk at 11pm Friday is a production incident.

**Runbook implication:** Adrian looks at `/health`, sees `storage: critical` (>95%), and immediately SSHes in to clean up old Docker images or WAL logs.

---

## First-incident runbook (the one-page version)

**Scenario:** It's 11pm Friday. Your one beta amigo (let's call him Pablo) texts you on WhatsApp: "Stockerly está caído. No me carga nada."

**Do this, in order:**

1. **Is it actually down?** (10 seconds) — `curl -I https://stockerly.notdefined.dev/up`
   - 200 → app is up. Go to step 2.
   - 502 → Cloudflare tunnel is down or app is unreachable. Go to step 5.

2. **Is the app container running?** (10 seconds) — `bin/kamal details`
   - Container running + last deploy recent → go to step 3.
   - Container not running → `bin/kamal app start` and wait 30s, then curl `/up` again.

3. **What does the app say?** (30 seconds) — `bin/kamal logs --lines 50 | tail -20`
   - `PG::Error` → database is down or disk full. Go to step 6.
   - `Timeout` → external API timeout. Go to step 4.
   - `NoMethodError` → recent bad deploy. `bin/kamal rollback`, wait 30s, curl `/up`.
   - Nothing suspicious → go to step 3b.

3b. **Is the health check passing?** (10 seconds) — `curl https://stockerly.notdefined.dev/health | jq .`
   - status "ok" → app is fine, client-side issue. Tell Pablo to hard-refresh (Cmd+Shift+R). Go to step 7.
   - status "critical" or "degraded" → data sync is stale. Go to step 4.

4. **Why are syncs failing?** (2 minutes) — `bin/kamal console`
   ```
   SystemLog.where(severity: :error).last(5)
   SystemLog.where(task_name: "FX Rates Sync").last(3)
   ```
   - "Rate limited" → gateway is rate-limiting. Wait 15min or switch provider.
   - "Connection refused" → gateway is down. Acknowledge to Pablo.
   - "404" → gateway schema changed. File issue, escalate.

5. **Is the Cloudflare tunnel down?** (30 seconds) — Check tunnel status at cloudflare.dash, or SSH and `systemctl status cloudflared`. If down: `sudo systemctl restart cloudflared`.

6. **Is the disk full?** (30 seconds) — SSH and `df -h /`. If >90%: `docker system prune -a --volumes`, then `bin/kamal app restart`.

7. **Communicate to Pablo:**
   - If fixed: "Está arriba. ¿Me confirmas si ya te carga?"
   - If investigating: "Estoy en eso. Es un problema con el [proveedor de datos / servidor]. Te aviso en 30min."
   - If can't reproduce: "Probé y para mí está funcionando. ¿Puedes mandarme screenshot? ¿Qué navegador usas?"

8. **After Pablo confirms:**
   - File a GitHub issue with root cause + timeline if real incident.
   - Add a note to `docs/ops/beta-support.md` with the incident and what you did.
   - If you rolled back, re-deploy the same commit in the morning to test if it was transient.
