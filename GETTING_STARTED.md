# Getting Started

Run Stockerly locally. For what it is, see [docs/vision/](docs/vision/); for how it's built,
[CLAUDE.md](CLAUDE.md) and [docs/architecture/](docs/architecture/).

`bin/setup` is idempotent and does the whole local setup: install gems, create + migrate the
databases, seed demo data, and start the server. No LLM key or market-data API key is needed
to run — the app is fully functional without them.

## Prerequisites

- **Docker** (for the Dev Container path), or
- **Ruby 3.3.6** + **PostgreSQL 16** (for the bare-metal path)

Node.js is **not** required — JS ships via import maps and CSS via the `tailwindcss-rails`
standalone compiler.

## Path 1 — Dev Container (recommended)

Works in VS Code or GitHub Codespaces.

1. Clone, open the folder in VS Code, and run **Dev Containers: Reopen in Container**.
2. `.devcontainer/post-create.sh` runs automatically: `bundle install`, then
   `bin/setup --skip-server` (creates + migrates all databases and seeds demo data), then
   installs git hooks.
3. Start the app:
   ```bash
   bin/dev
   ```

Open **`http://localhost:4100`**.

## Path 2 — Bare metal

Requires Ruby 3.3.6 and a PostgreSQL 16 reachable on `localhost` with a `postgres` role.

```bash
git clone https://github.com/rodacato/stockerly.git
cd stockerly
bin/setup        # installs gems, prepares the databases, seeds demo data, starts the server
```

Open **`http://localhost:4100`**.

`bin/setup` connects with the `config/database.yml` defaults (`host=localhost`,
`user=postgres`, empty password). Override with `DATABASE_HOST` / `DATABASE_USERNAME` /
`DATABASE_PASSWORD` if your Postgres differs (copy `.env.example` to `.env` and edit).

## Databases

Stockerly uses **four** PostgreSQL databases in development — primary plus Solid Cache,
Solid Queue, and Solid Cable (Rails 8 runs cache, jobs, and Action Cable on Postgres, no
Redis). `bin/setup` (via `bin/rails db:prepare`) creates and migrates all four; you don't
manage them by hand.

## Background jobs

`bin/dev` starts only the web server and the Tailwind watcher (see `Procfile.dev`). To
process background jobs (alerts, notifications, data syncs) run the Solid Queue worker in a
second terminal:

```bash
bin/jobs
```

## First login

`bin/setup` seeds demo data, including an admin account:

```
admin@stockerly.com / password123
```

A fresh, unseeded instance instead shows the **Setup Wizard** at first visit, which creates
the first admin account and initializes the app.

## Optional configuration

- **Market-data API keys** (Polygon.io, Alpha Vantage, CoinGecko, FMP, Banxico) — all
  optional, configured in **Admin → Integrations** after setup. Without them the app runs
  but shows no live market data.
- **AI Intelligence** (Anthropic / OpenAI / any compatible endpoint) — optional, configured
  in **Admin → AI Intelligence**.

## First-run check

1. `bin/dev` logs the Puma server listening on port **4100**.
2. `http://localhost:4100` loads — the dashboard (demo admin) or the Setup Wizard.
3. For live alerts/notifications, confirm `bin/jobs` is running in another terminal.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Nothing at `http://localhost:3000` | The dev server runs on **4100** (`Procfile.dev`), not 3000. |
| `bin/setup` can't connect to Postgres | Set `DATABASE_HOST` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` (via `.env`) to match your local Postgres. |
| Background work never runs | `bin/dev` doesn't start workers — run `bin/jobs` separately. |
| Need a clean database | `bin/setup --reset` (drops, recreates, migrates, reseeds). |

## More

[docs/](docs/) · [CLAUDE.md](CLAUDE.md) (architecture) · [docs/ops/deploy.md](docs/ops/deploy.md)
(production) · [CONTRIBUTING.md](CONTRIBUTING.md)
