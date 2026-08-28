# Deployment Guide

Stockerly deploys to a Hetzner VPS using **Kamal 2** with **Cloudflare Tunnel** for traffic routing and SSL.

## Architecture

```
Internet → Cloudflare (SSL termination)
              |
              v
         Cloudflare Tunnel (encrypted)
              |
              v
         Hetzner VPS
              |
         cloudflared → localhost:80 (kamal-proxy) → web:3000 (Puma)
                                                  → PostgreSQL (accessory)

         job role (Solid Queue worker, same host, no inbound traffic)
```

Two Kamal roles run on the same host: `web` (Puma, behind kamal-proxy) and `job` (a Solid Queue
worker started with `rails solid_queue:start`). Only `web` is reachable through the tunnel.

No inbound ports 80/443 needed on the server. Only SSH (22) is open for Kamal deployments.

## Prerequisites

- Hetzner VPS (Ubuntu 22.04+, minimum 2GB RAM)
- GitHub account (GHCR is used as the container registry)
- Cloudflare account with the domain added

## 1. Provision the Server

```bash
ssh root@YOUR_SERVER_IP < bin/provision-server
```

> **Note:** The provision script runs as root but creates a `deploy` user with Docker access.
> All subsequent SSH access (Kamal, manual operations) uses the `deploy` user.

This installs:
- Docker
- cloudflared
- `deploy` user (with Docker group access)
- UFW firewall (only port 22 open)
- 2GB swap
- Automatic security updates

### 1b. Authorize your SSH key for the `deploy` user

The script creates `deploy` but **does not install any key for it** — that step is yours, and its
closing output says so. Skip it and every later `bin/kamal` command fails to connect, because
`config/deploy.yml` sets `ssh.user: deploy`.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@YOUR_SERVER_IP
```

If `deploy` has no password (the usual case), append the key as root instead:

```bash
ssh root@YOUR_SERVER_IP 'mkdir -p /home/deploy/.ssh && cat >> /home/deploy/.ssh/authorized_keys \
  && chown -R deploy:deploy /home/deploy/.ssh && chmod 700 /home/deploy/.ssh \
  && chmod 600 /home/deploy/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
```

Verify before continuing: `ssh deploy@YOUR_SERVER_IP 'docker ps'`.

The **private** half of this same key is what goes into the `SSH_PRIVATE_KEY` secret in step 3.

## 2. Create Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust](https://one.dash.cloudflare.com) > **Networks** > **Tunnels**
2. Click **Create a tunnel** > select **Cloudflared**
3. Name it `stockerly` and click **Save tunnel**
4. Copy the **tunnel token** (starts with `eyJ...`)
5. SSH into your server and install the tunnel:

```bash
ssh root@YOUR_SERVER_IP
cloudflared service install <TUNNEL_TOKEN>
```

6. Back in Cloudflare dashboard, add a **Public hostname**:

| Field | Value |
|---|---|
| Subdomain | `stockerly` |
| Domain | `notdefined.dev` |
| Type | `HTTP` |
| URL | `localhost:80` |

7. Go to **SSL/TLS** settings for `notdefined.dev` and set encryption mode to **Full**

The tunnel is now running as a systemd service and will auto-start on reboot.

## 3. Set Up GitHub Environment Secrets

Go to **GitHub repo > Settings > Environments > New environment** and create `production`.

Add these secrets:

| Secret | Required | How to get it |
|---|---|---|
| `HOST_IP` | yes | Your Hetzner server IP |
| `SSH_PRIVATE_KEY` | yes | Private SSH key whose public half you installed for `deploy` in step 1b |
| `POSTGRES_PASSWORD` | yes | Generate with `openssl rand -hex 32` |
| `SECRET_KEY_BASE` | yes | Generate with `bin/rails secret` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | yes | `bin/rails db:encryption:init` prints all three at once |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | yes | idem |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | yes | idem |
| `SENTRY_DSN` | no | From the Sentry project settings — error tracking is off without it |
| `SENTRY_AUTH_TOKEN` | no | Only needed to create a Sentry release on deploy; the step skips silently without it |
| `RESEND_API_KEY` | no | From the Resend dashboard |
| `METRICS_TOKEN` | no | Generate with `openssl rand -hex 32` — enables the Prometheus endpoint |

> **The encryption keys are not optional and Kamal will not tell you they are missing.**
> `.kamal/secrets` resolves every entry as `NAME=$NAME`, so an unset variable becomes the **empty
> string** rather than a `Missing secret` error. Deploying without them boots an app with empty
> encryption keys, and every provider API key saved afterwards through **Admin > Integrations** is
> written under those empty keys — unrecoverable once you set the real ones. Generate them once with
> `bin/rails db:encryption:init` and keep them forever; rotating them orphans existing ciphertext.

The same silent-empty behaviour applies to the optional rows: no warning, the feature is just
absent. Without `SENTRY_DSN` there is no error tracking at all.

### Environment **variables** (not secrets)

These are plain values, so set them under **Variables**, not Secrets, in the same environment:

| Variable | Default if unset | Effect |
|---|---|---|
| `SENTRY_ENVIRONMENT` | `production` | Tags events in Sentry |
| `SENTRY_TRACES_SAMPLE_RATE` | `0` | Performance-trace sampling |
| `SENTRY_ORG` / `SENTRY_PROJECT` | — / `stockerly` | Target of the release step |
| `METRICS_ENABLED` | `false` | Master switch for the Prometheus endpoint |

> **Note:** The registry uses GHCR (GitHub Container Registry) with `GITHUB_TOKEN` — no Docker Hub credentials needed.

## 4. First Deploy (kamal setup)

The first deploy needs `kamal setup` to bootstrap kamal-proxy and accessories.

Run locally (requires SSH access as `deploy` and every secret exported).

Generate the encryption keys **first** — the command prints all three and you paste them below and
into the GitHub Environment. Use the same values in both places:

```bash
bin/rails db:encryption:init
```

Then export everything and run setup:

```bash
export KAMAL_REGISTRY_PASSWORD=your-github-pat   # GitHub PAT with packages:write scope
export GITHUB_REPOSITORY=rodacato/stockerly
export GITHUB_ACTOR=rodacato
export HOST_IP=YOUR_SERVER_IP
export SECRET_KEY_BASE=$(bin/rails secret)
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Required — from `bin/rails db:encryption:init` above. Omit any of these and Kamal
# does NOT fail; it ships an empty string and the app encrypts with no key.
export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=...
export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=...
export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=...

# Optional — each is silently absent if unset
export SENTRY_DSN=...
export RESEND_API_KEY=...
export METRICS_TOKEN=...

bin/kamal setup
```

`DATABASE_URL` is not exported by hand: `.kamal/secrets` builds it from `POSTGRES_PASSWORD`.

This will:
- Install kamal-proxy on the server (listens on port 80)
- Start the PostgreSQL accessory container
- Build and push the Docker image
- Deploy the app

After this, verify at `https://stockerly.notdefined.dev`

## 5. Initial Setup

After the first deploy, visit `https://stockerly.notdefined.dev/setup` to run the **Setup Wizard**. It is only accessible when no users exist in the database and will:

1. Create your admin account (name, email, password)
2. Bootstrap platform defaults (site config, integrations, market indices, FX rates)
3. Guide you through API key configuration and asset selection

> **Note:** Seeds (`db/seeds.rb`) are **not** run in production — the Setup Wizard handles all bootstrapping.

> **There is no registration.** The pivot to a single-user tracker (ADR-010) deleted the sign-up
> route along with the rest of the multi-user surface; there is no toggle for it anywhere. `/setup`
> is the only path that creates an account, and it stops answering as soon as one exists.

Once the Banxico key is configured, seed the FX history so a backdated trade values at its own day's rate:

```bash
bin/kamal app exec 'bin/rails data:backfill_fx_history'
```

It is one free request for the whole USD/MXN FIX back to 1991, and it is idempotent — re-run it any time a gap appears.

### Starting over from an empty database

Only when you mean to destroy every trade, alert and encrypted provider key on the instance —
there is no undo and no backup step below. The entrypoint runs `bin/rails db:prepare` on boot,
which rebuilds an *empty* database to the current schema but will not wipe an existing one, so
the database is dropped and recreated first:

```bash
bin/kamal app stop
bin/kamal accessory exec postgres --interactive \
  'psql -U stockerly -d postgres -c "DROP DATABASE IF EXISTS stockerly_production; CREATE DATABASE stockerly_production OWNER stockerly;"'
bin/kamal deploy
```

The Solid Queue / Cache / Cable databases are separate (`*_queue`, `*_cache`, `*_cable`); if they
carry stale state, recreate them the same way — otherwise `db:prepare` handles them. On the next
boot the instance has no users, so it answers at `/setup` again.

## 6. Subsequent Deploys

`.github/workflows/deploy.yml` triggers on **push to the `production` branch** — not `master`.
Merging to `master` runs CI and nothing else; production only moves when you advance `production`:

```bash
git fetch origin
git checkout production && git merge --ff-only origin/master && git push origin production
```

The workflow gates the deploy on the suite, brakeman and bundler-audit, then runs Kamal and creates
a Sentry release on success.

You can also trigger it from the GitHub Actions tab with **Run workflow**, which takes an `action`
input:

| Action | Runs | When |
|---|---|---|
| `deploy` (default) | `kamal deploy` | Normal release |
| `setup` | `kamal setup` | First-time bootstrap on a new host |
| `redeploy` | `kamal redeploy` | Restart the current image without rebuilding |

Deploys are serialized (`concurrency: deploy`, no cancel-in-progress).

## 7. Useful Kamal Commands

All Kamal commands run from your **local machine** (not the VPS). Commands that *change* the
deployment need the same variables the first deploy needed — `.kamal/secrets` reads them straight
from your shell. Read-only commands do not; see [From the devcontainer](#from-the-devcontainer).

There is no `.env.production` in this repo: nothing creates it and `.gitignore` ignores `/.env*`, so
`source .env.production` fails. Either re-export the step 4 block in the shell you are working in,
or keep your own untracked file and source it:

```bash
set -a && source ~/.stockerly.production.env && set +a   # your own file, outside the repo
```

At minimum `HOST_IP`, `POSTGRES_PASSWORD` and `SECRET_KEY_BASE` must be set, or the command
connects to the wrong place or boots a container with empty secrets.

Then:

```bash
bin/kamal details        # Check app status
bin/kamal logs           # Tail logs
bin/kamal console        # Open Rails console
bin/kamal shell          # Open bash shell
bin/kamal db             # Open psql on the postgres accessory
bin/kamal migrate        # Run pending migrations
bin/kamal rollback       # Rollback to previous version
bin/kamal app restart    # Restart the app
bin/kamal accessory restart postgres  # Restart PostgreSQL
```

The aliases are defined in `config/deploy.yml` under `aliases:` — that block is the authority if
this list ever drifts.

### Locked out: resetting a password without working mail

`/forgot-password` sends a link by email, which is exactly what is most likely to be unconfigured
on a fresh self-hosted box — so it is not the recovery path to rely on. Reset from the box instead:

```bash
bin/kamal shell
bin/rails "stockerly:reset_password[you@example.com]"
```

It prompts twice, echoes nothing, and refuses to run without a TTY rather than printing the
password into your scrollback. **Two-factor stays enrolled** — this replaces a password, not a
second factor; if you also lost your authenticator, use one of the recovery codes shown at
enrolment. The companion task is `stockerly:promote_admin[you@example.com]`.

This exists because a required third-party service — including your own mail — may not be there on
someone else's instance ([ADR-019](../architecture/adr/0019-self-contained-by-default.md), D55).

### From the devcontainer

The devcontainer can run the read-only commands without holding any secret. Copy the example file
once and set the server IP:

```bash
cp .devcontainer/local.env.example .devcontainer/local.env
$EDITOR .devcontainer/local.env      # set HOST_IP; the file is gitignored
```

`.devcontainer/kamal-env.sh` is sourced by every shell and supplies what GitHub Actions supplies for
free in CI: `GITHUB_REPOSITORY` and `GITHUB_ACTOR` derived from the git remote, plus `HOST_IP` from
that file. Without it the ERB in `config/deploy.yml` renders nil and Kamal aborts with
`image: should be a string`.

Available, since these only read:

```bash
bin/kamal config                      # Resolved config — verify before changing anything
bin/kamal app details                 # Running containers, image and uptime
bin/kamal accessory details postgres  # PostgreSQL accessory status
bin/kamal app logs -r job -n 200      # Production logs, per role
bin/kamal audit                       # Deploy history with timestamps
```

Not available, because they need the secrets or a local Docker daemon: `deploy`, `rollback`,
`migrate`, `build`, and the interactive aliases (`console`, `shell`, `db`). Run those from the host,
or deploy through GitHub Actions as usual.

## Prometheus Metrics (optional)

The app can expose Prometheus metrics (Yabeda) for an external, self-hosted
Prometheus to scrape. The feature is **opt-in and decoupled from infrastructure** —
treat it like any third-party metrics endpoint: a standard HTTPS URL guarded by a
bearer token. No tunnel changes, no private port, no VPN required.

- **Enable it:** set the `METRICS_ENABLED` Environment **variable** to `true`
  **and** add the `METRICS_TOKEN` **secret**. Both are required. Leave
  `METRICS_ENABLED` unset (the default) and the whole feature stays off — no
  endpoint, no middleware, no overhead. The flag is separate from the token so
  you can toggle metrics off (flip the variable) without deleting the secret;
  enabling without a token fails closed (stays off, logs a warning).
- **Endpoint:** `GET https://stockerly.notdefined.dev/metrics`
- **Port inside the container:** `3000` (same Puma the app runs on; routed by
  kamal-proxy). No extra port is published.
- **Auth:** `Authorization: Bearer <METRICS_TOKEN>`. Without a valid token the
  endpoint returns `401`; when `METRICS_TOKEN` is unset it returns `404`
  (fail-closed — never exposed by accident).

Example Prometheus scrape config:

```yaml
scrape_configs:
  - job_name: stockerly
    scheme: https
    metrics_path: /metrics
    authorization:
      type: Bearer
      credentials: "<METRICS_TOKEN>"
    static_configs:
      - targets: ["stockerly.notdefined.dev"]
```

Exposed metrics include `stockerly_data_age_seconds` (age of the freshest
market-data sync), Rails request metrics (yabeda-rails), and per-worker Puma
metrics (yabeda-puma-plugin, clustered only). Under clustered Puma
(`WEB_CONCURRENCY > 0`) a shared file store aggregates workers so a single scrape
reflects the whole instance.

## Troubleshooting

**Site not loading after deploy:**
1. Check tunnel status: `systemctl status cloudflared`
2. Check kamal-proxy: `bin/kamal details`
3. Check app logs: `bin/kamal logs`

**502 Bad Gateway from Cloudflare:**
The app container probably isn't running or failed healthcheck. Check `bin/kamal logs`.

**Container fails healthcheck:**
Common causes: missing env vars, database not migrated. Check `bin/kamal logs`.

**Database connection refused:**
Verify PostgreSQL is running: `bin/kamal accessory details postgres`.

**Tunnel not connecting:**
```bash
ssh deploy@YOUR_SERVER_IP
systemctl status cloudflared
journalctl -u cloudflared -f
```

**A page returned a 500 and you want to know why:**
Turn on **Modo desarrollador** in Ajustes → Estado y mantenimiento, then open Ajustes → Errores
(`/admin/errors`). Every unhandled exception from a request or a job is recorded there with its
class, the failing application line, the full backtrace and the request that caused it, grouped so
a bug that fired forty times is one entry. Entries are kept for 30 days and purged nightly
(ADR-020).

The switch controls the screen, not the recording: errors are captured whether it is on or off, so
turning it on after the fact still shows what already happened.

**The error screen is empty but you know something failed:**
The tracker stores rows in PostgreSQL, so a failure that happens while the database is unreachable
cannot be recorded — by construction, not by oversight. For that class of failure the fallback is
the container log:
```bash
bin/kamal logs -f
bin/kamal accessory details postgres
```
