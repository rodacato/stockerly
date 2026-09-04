# Mirroring production locally

Production is the only instance that spends API quota — the rule is
[ADR-0024](../architecture/adr/0024-production-is-the-only-instance-that-spends-quota.md),
and this is how it is obeyed. Production already syncs prices, fundamentals and
FX on a schedule; local work reads a copy of what it fetched instead of fetching
again. That is what `bin/prod-sync` is for.

When the copy is missing history rather than freshness, deepen it **in
production** and re-sync:

```bash
bin/rails 'data:deepen[NVDA,10]'    # one symbol
bin/rails 'data:deepen_all[10]'     # every active asset, paced
```

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

### 2. Nothing, if the Kamal environment already loads

`bin/prod-sync` sources `.devcontainer/kamal-env.sh`, which is where `HOST_IP`
and the GitHub slug already come from — the same file Kamal itself depends on.
If `bin/kamal config` renders, the sync has what it needs. Everything else has a
default: `PROD_SSH_USER=deploy`, `PROD_PG_CONTAINER=stockerly-postgres`,
`PROD_PG_DB=stockerly_production`, `PROD_PG_ROLE=stockerly_ro`.

That environment is wired into the shell by `.devcontainer/post-create.sh`, and
only when the container is created. A container older than that hook has no
`STOCKERLY_ROOT` in its `~/.bashrc`, and Kamal fails there with
`image: should be a string` — which reads like a config error and is a missing
environment. Append the two lines the hook writes, or rebuild.

## The sync

```bash
bin/prod-sync           # dump if SSH is reachable, then restore
bin/prod-sync dump      # the half that needs SSH
bin/prod-sync restore   # the half that needs the local Postgres
bin/prod-sync status    # what the mirror currently holds
```

Run with no arguments and it does what it can from where it is. The devcontainer
forwards the SSH agent, so both halves usually run there in one command; where
the agent is absent the dump half is skipped and the newest file in `tmp/prod/`
is restored instead, which is why the halves are separable at all.

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
number, go through SSH rather than open a port — a one-off query needs no
tunnel at all:

```bash
ssh deploy@$HOST_IP "docker exec -i stockerly-postgres \
  psql -U stockerly_ro -d stockerly_production -c 'SELECT ...'"
```

The accessory exposes 5432 on the Docker network and publishes nothing to the
host, so `ssh -L 5433:localhost:5432` reaches nothing. A real tunnel has to name
the container's address on that network:

```bash
PGIP=$(ssh deploy@$HOST_IP "docker inspect -f \
  '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' stockerly-postgres")
ssh -L 5433:$PGIP:5432 deploy@$HOST_IP
```

Either way the access arrives over SSH. Publishing 5432 would be the one inbound
port on a host whose ingress is a Cloudflare Tunnel precisely so it has none.

## What the dump contains

Everything production holds: trades, positions, and the encrypted columns for
integrations and the second factor. It is your own data on your own machine, and
`tmp/` is gitignored — but it is a real copy, so treat a stray dump the way you
would treat a database backup.
