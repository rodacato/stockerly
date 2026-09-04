# Mirroring production locally

Production is the only instance that should spend API quota. It already syncs
prices, fundamentals and FX on a schedule; local work reads a copy of what it
fetched instead of fetching again. That is what `bin/prod-sync` is for.

## The one-time setup

### 1. A read-only role in production

The dump does not need — and should not have — write access. Create the role
once, through the Kamal alias:

```bash
bin/kamal db
```

```sql
CREATE ROLE stockerly_ro LOGIN;
GRANT CONNECT ON DATABASE stockerly_production TO stockerly_ro;
GRANT USAGE ON SCHEMA public TO stockerly_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO stockerly_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO stockerly_ro;
```

No password: the accessory container authenticates local socket connections by
trust, which is the same reason `bin/kamal db` opens a `psql` without one. The
role is reachable only from inside that container, and the only way in is SSH.

### 2. `HOST_IP` on the machine that deploys

`bin/prod-sync` reads it from the environment or from `.env`. Everything else
has a default: `PROD_SSH_USER=deploy`, `PROD_PG_CONTAINER=stockerly-postgres`,
`PROD_PG_DB=stockerly_production`, `PROD_PG_ROLE=stockerly_ro`.

## The sync

```bash
bin/prod-sync           # dump if SSH is reachable, then restore
bin/prod-sync dump      # the half that needs SSH
bin/prod-sync restore   # the half that needs the local Postgres
bin/prod-sync status    # what the mirror currently holds
```

Run with no arguments and it does what it can from where it is. The devcontainer
has no SSH keys, so inside it the dump half is skipped and the newest file in
`tmp/prod/` is restored — which means the usual rhythm is `bin/prod-sync dump`
on the host, then `bin/prod-sync` in the container. The repository is mounted
into the container, so the file needs no copying.

`FORCE=1` skips the confirmation before the mirror is replaced.

## Reading the mirror

The mirror is a database named `prodmirror_development`, and
`Stockerly::Checkout` already resolves the database name from `DATABASE_PREFIX`.
So the whole app points at it with an environment variable:

```bash
DATABASE_PREFIX=prodmirror bin/rails console
DATABASE_PREFIX=prodmirror bin/rails runner 'puts AssetPriceHistory.count'
```

Nothing else changes: same models, same queries, same code. The prefix is
outside the scope `db:worktrees` walks, so `db:worktrees:prune` will never
offer to drop it.

## Live reads, when a copy will not do

Historical bars are immutable, so a backtest wants the copy — it reads the same
rows thousands of times and has no business doing that over the network against
a 4 GB box that also runs the app. When something genuinely needs *today's*
number, tunnel rather than open a port:

```bash
ssh -L 5433:localhost:5432 deploy@$HOST_IP
```

Publishing 5432 would be the one inbound port on a host whose ingress is a
Cloudflare Tunnel precisely so it has none. The tunnel gives the same access,
to the same read-only role, and closes when you close it.

## What the dump contains

Everything production holds: trades, positions, and the encrypted columns for
integrations and the second factor. It is your own data on your own machine, and
`tmp/` is gitignored — but it is a real copy, so treat a stray dump the way you
would treat a database backup.
