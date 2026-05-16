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
| Filter logs by request | `bin/kamal logs \| grep "request_id=<ID>"` | `config/environments/production.rb` sets `config.log_tags = [ :request_id ]`. User can find their `request_id` in HTML response headers (`X-Request-Id`) and forward it. **There is no `user_id` in log tags today** — see §3.3 gap |
| Rails console in prod | `bin/kamal console` | **Read-only by discipline**, not by enforcement. Use it to inspect, not to mutate, unless you have a fix-script and a backup |
| Bash shell in prod | `bin/kamal shell` | For diagnostic shell access (e.g., disk space, running processes) |
| PostgreSQL console | `bin/kamal dbc` | Direct `psql` on the production DB. Same discipline — read first, mutate only with explicit intent |
| App status | `bin/kamal details` | Is the container up? Last deploy? |

**Hard rule before any mutation in `bin/kamal console` or `bin/kamal dbc`:**

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

- [ ] **No structured admin UI to look up a specific user's recent activity.** Today: open `bin/kamal dbc` and write SQL. Issue worth opening if it happens 3+ times in S07.
- [ ] **`user_id` not in log tags.** Production logs tag `request_id` only. Filtering by user means asking the user for their `X-Request-Id` header (most users won't know how) or correlating manually via timestamp + DB user record. Cheap fix: add `:user_id` to `config.log_tags` in `production.rb` and wrap controllers with `tagged_logger { |l| l.tagged("user:#{current_user&.id}") { yield } }`. Defer to S08 if friction appears.
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
5. Open `bin/kamal dbc` and query for the test user — can you confirm what you saw in logs?
6. Write a reply to yourself following §1.5 acuse-de-recibo guidelines.

If any step has a gap (email doesn't arrive, log filtering doesn't work, DB query is awkward) — that's a real gap, fix before closing #78.
