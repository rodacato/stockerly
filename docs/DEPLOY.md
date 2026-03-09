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
         cloudflared → localhost:80 (kamal-proxy) → app:3000
                                                  → PostgreSQL (accessory)
```

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

| Secret | How to get it |
|---|---|
| `HOST_IP` | Your Hetzner server IP |
| `SSH_PRIVATE_KEY` | Private SSH key for the `deploy` user on the server |
| `POSTGRES_PASSWORD` | Generate with `openssl rand -hex 32` |
| `SECRET_KEY_BASE` | Generate with `bin/rails secret` |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Generate with `bin/rails db:encryption:init` |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Generate with `bin/rails db:encryption:init` |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Generate with `bin/rails db:encryption:init` |
| `HONEYBADGER_API_KEY` | From Honeybadger project settings (optional) |
| `RESEND_API_KEY` | From Resend dashboard (optional) |

> **Note:** The registry uses GHCR (GitHub Container Registry) with `GITHUB_TOKEN` — no Docker Hub credentials needed.

## 4. First Deploy (kamal setup)

The first deploy needs `kamal setup` to bootstrap kamal-proxy and accessories.

Run locally (requires SSH access and secrets exported):

```bash
export KAMAL_REGISTRY_PASSWORD=your-github-pat   # GitHub PAT with packages:write scope
export GITHUB_REPOSITORY=rodacato/stockerly
export GITHUB_ACTOR=rodacato
export HOST_IP=YOUR_SERVER_IP
export SECRET_KEY_BASE=$(bin/rails secret)
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

bin/kamal setup
```

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

> **Note:** Seeds (`db/seeds.rb`) are **not** run in production — the Setup Wizard handles all bootstrapping. Registration is disabled by default and can be enabled from the admin panel.

## 6. Subsequent Deploys (automatic)

Every push to `master` triggers `.github/workflows/deploy.yml` which runs `kamal deploy`.

You can also trigger manually from the GitHub Actions tab using "Run workflow".

## 7. Useful Kamal Commands

All Kamal commands run from your **local machine** (not the VPS). Load env vars first:

```bash
set -a && source .env.production && set +a
```

Then:

```bash
bin/kamal details        # Check app status
bin/kamal logs           # Tail logs
bin/kamal console        # Open Rails console
bin/kamal shell          # Open bash shell
bin/kamal dbc            # Open database console
bin/kamal rollback       # Rollback to previous version
bin/kamal app restart    # Restart the app
bin/kamal accessory restart postgres  # Restart PostgreSQL
```

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
