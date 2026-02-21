# Deployment Guide

Stockerly deploys to a Hetzner VPS using **Kamal 2** via a **GitHub Actions** workflow.

## Architecture

```
GitHub (push to master)
  |
  v
GitHub Actions (build Docker image + kamal deploy)
  |
  v
Hetzner VPS (kamal-proxy + app container + PostgreSQL container)
```

## Prerequisites

- Hetzner VPS (Ubuntu 22.04+ recommended, minimum 2GB RAM)
- Docker Hub account
- Domain DNS pointing to the server IP

## 1. Provision the Server

SSH into your fresh server and run the provisioning script:

```bash
ssh root@46.225.67.253 < bin/provision-server
```

This installs Docker, configures UFW firewall (ports 22/80/443), adds 2GB swap, and enables automatic security updates.

## 2. Configure DNS

Create an A record pointing your domain to the server:

```
stockerly.notdefined.dev → 46.225.67.253
```

## 3. Set Up GitHub Environment Secrets

Go to **GitHub repo > Settings > Environments > New environment** and create `production`.

Add these secrets:

| Secret | How to get it |
|---|---|
| `KAMAL_REGISTRY_PASSWORD` | Docker Hub > Account Settings > Personal Access Tokens > Generate (Read & Write) |
| `RAILS_MASTER_KEY` | Content of `config/master.key` in the project |
| `POSTGRES_PASSWORD` | Generate a strong password (e.g., `openssl rand -hex 32`) |
| `SSH_PRIVATE_KEY` | Private SSH key that matches the public key on the server |

## 4. First Deploy (kamal setup)

The first deploy needs `kamal setup` instead of `kamal deploy` because it bootstraps kamal-proxy and accessories (PostgreSQL).

Run it locally (requires SSH access and secrets exported):

```bash
# Export secrets locally
export KAMAL_REGISTRY_PASSWORD=your-docker-hub-token
export RAILS_MASTER_KEY=$(cat config/master.key)
export POSTGRES_PASSWORD=$(openssl rand -hex 32)

# Bootstrap everything
bin/kamal setup
```

This will:
- Install kamal-proxy on the server
- Start the PostgreSQL accessory container
- Build and push the Docker image
- Deploy the app
- Provision SSL certificate via Let's Encrypt

## 5. Subsequent Deploys (automatic)

After the first `kamal setup`, every push to `master` triggers the GitHub Actions workflow at `.github/workflows/deploy.yml` which runs `kamal deploy` automatically.

You can also deploy manually from the Actions tab using "Run workflow".

## 6. Useful Kamal Commands

```bash
# Check app status
bin/kamal details

# Tail logs
bin/kamal logs

# Open Rails console
bin/kamal console

# Open bash shell in container
bin/kamal shell

# Open database console
bin/kamal dbc

# Rollback to previous version
bin/kamal rollback

# Restart the app
bin/kamal app restart

# Restart accessories (PostgreSQL)
bin/kamal accessory restart postgres
```

## Troubleshooting

**Deploy fails with SSL error:**
Make sure DNS is pointing to the server and ports 80/443 are open. Let's Encrypt needs HTTP access.

**Container fails healthcheck:**
Check logs with `bin/kamal logs`. Common issues: missing env vars, database not migrated.

**Database connection refused:**
Verify the PostgreSQL accessory is running: `bin/kamal accessory details postgres`.
