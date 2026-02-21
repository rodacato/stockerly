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
- Docker Hub account
- Cloudflare account with the domain added

## 1. Provision the Server

```bash
ssh root@YOUR_SERVER_IP < bin/provision-server
```

This installs:
- Docker
- cloudflared
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
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub > Account Settings > Personal Access Tokens > Generate (Read & Write) |
| `RAILS_MASTER_KEY` | Content of `config/master.key` in the project |
| `POSTGRES_PASSWORD` | Generate with `openssl rand -hex 32` |
| `SSH_PRIVATE_KEY` | Private SSH key matching the public key on the server |
| `DOCKER_REGISTRY_USER` | Your Docker Hub username (e.g., `rodacato`) |
| `SERVER_IP` | Your Hetzner server IP |

## 4. First Deploy (kamal setup)

The first deploy needs `kamal setup` to bootstrap kamal-proxy and accessories.

Run locally (requires SSH access and secrets exported):

```bash
export KAMAL_REGISTRY_PASSWORD=your-docker-hub-token
export DOCKER_REGISTRY_USER=rodacato
export SERVER_IP=YOUR_SERVER_IP
export RAILS_MASTER_KEY=$(cat config/master.key)
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

bin/kamal setup
```

This will:
- Install kamal-proxy on the server (listens on port 80)
- Start the PostgreSQL accessory container
- Build and push the Docker image
- Deploy the app

After this, verify at `https://stockerly.notdefined.dev`

## 5. Subsequent Deploys (automatic)

Every push to `master` triggers `.github/workflows/deploy.yml` which runs `kamal deploy`.

You can also trigger manually from the GitHub Actions tab using "Run workflow".

## 6. Useful Kamal Commands

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
ssh root@YOUR_SERVER_IP
systemctl status cloudflared
journalctl -u cloudflared -f
```
