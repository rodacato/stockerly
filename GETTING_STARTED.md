# Getting Started

Run Stockerly locally. For what it is, see [docs/vision/](docs/vision/); for how it's built,
[CLAUDE.md](CLAUDE.md) and [docs/architecture/](docs/architecture/).

`bin/setup` is idempotent and does the whole local setup: install gems, prepare the databases,
and start the server. It runs `bin/rails db:prepare`, which **seeds only when it creates the
database** — on an existing database it migrates and leaves the data alone. Use
`bin/setup --reset` to drop, recreate and reseed. No market-data API key is needed to run — the
app is fully functional without one.

## Prerequisites

- **Docker** (for the Dev Container path), or
- **Ruby 3.3.6** + **PostgreSQL 16** (for the bare-metal path)

Node.js is **not** required — JS ships via import maps and CSS via the `tailwindcss-rails`
standalone compiler.

## Path 1 — Dev Container (recommended)

Works in VS Code or GitHub Codespaces.

1. Clone, open the folder in VS Code, and run **Dev Containers: Reopen in Container**.
2. `.devcontainer/post-create.sh` runs automatically: `bundle install`, then
   `bin/setup --skip-server` (creates + migrates all databases, seeding them on first
   creation), then installs git hooks.
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
bin/setup        # installs gems, prepares the databases (seeding on first creation), starts the server
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

When `bin/setup` creates the database it seeds four demo users (`db/seeds.rb`, development
only). Sign in as:

```
demo@stockerly.com / password123
```

All four seeded users have `role: :user` — **none of them is an admin.** The seeds deliberately
do not create an admin (`db/seeds.rb`); the Setup Wizard does.

### Reaching the Setup Wizard

The wizard at `/setup` creates the single account and bootstraps the instance, but
`SetupController#require_no_users` redirects away as soon as **any** user exists. Because the
seeded dev path always creates four, the wizard is not reachable after a normal `bin/setup`.
To walk the first-boot experience a self-hoster gets, delete the users:

```bash
bin/rails runner 'AuditLog.delete_all; SiteConfigChange.delete_all; User.destroy_all'
bin/dev
```

`User` declares `dependent: :destroy` for portfolios, alert preferences, alert rules, alert
events, notifications and watchlist items, but **not** for `audit_logs` or
`site_config_changes` (`admin_id`) — both hold a foreign key to `users`, so clearing them first
is what keeps `destroy_all` from raising.

Then open `http://localhost:4100`. `ApplicationController#redirect_to_setup` sends every
request to `/setup` while no user exists, so the wizard runs. (This mirrors what the 2.0
production cutover did: drop the user-dependent rows, keep the accumulated market data.)

Don't reach for `db:drop db:create db:migrate` to get an empty instance — the Solid Cache,
Queue and Cable databases load from `db/*_schema.rb` via `db:prepare`, not from migrations, so
plain `db:migrate` leaves them without tables.

To exercise the admin-only screens (Integrations, Logs, Settings, Jobs) on a seeded database,
promote a seeded user instead:

```bash
bin/rails runner 'User.find_by!(email: "demo@stockerly.com").update!(role: :admin)'
```

## Optional configuration

**Market-data API keys** are all optional and are configured in the Setup Wizard or later under
**Admin → Integrations**. Without them the app runs but shows no live market data. The
registered sources are in `config/initializers/data_sources.rb`; several need no key at all.

## First-run check

1. `bin/dev` logs the Puma server listening on port **4100**.
2. `http://localhost:4100` loads — the login page on a seeded database, or the Setup Wizard on
   an empty one.
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
