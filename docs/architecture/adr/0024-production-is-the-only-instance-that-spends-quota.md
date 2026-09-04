# ADR-0024 — Production is the only instance that spends quota

**Status:** Accepted · 2026-09-04
**Context:** Market Data · Operations

## The rule

> **Production is the only instance that spends quota. The data stays there, and
> local work mirrors it down.**

No development checkout, worktree, CI run or research script calls a market-data
provider. When local work needs data it does not have, the fetch happens in
production — through a job, a sync, or `data:deepen` — and the result is pulled
down with `bin/prod-sync`.

## Why

Every provider in the stack meters something, and the meters are per account, not
per machine. [ADR-0015](0015-one-api-key-per-provider.md) already settled that
there is one key per provider; this settles who is allowed to spend it.

A development checkout that fetches has three costs, and only the first is
obvious:

1. **It burns a shared quota** on data production already has or will fetch
   anyway — Alpha Vantage's 25 calls a day is exhausted by one afternoon of
   iteration, and DataBursatil bills in KiB against a monthly balance.
2. **It produces data nobody keeps.** A backfill run in a worktree dies with that
   worktree's database. The same call made in production is a permanent asset,
   and every future checkout inherits it for free.
3. **It splits provenance.** [ADR-0016](0016-canonical-market-data-observations.md)
   binds every row to the source that produced it. Rows fetched locally are rows
   nobody can later audit, because the database they live in is not the one the
   product runs on.

Sibling worktrees make the third cost concrete: this repository gives each
checkout its own database on purpose (#486), so N checkouts fetching the same
year of history is N times the quota for one copy that survives.

## What this means in practice

| Need | Where it happens |
|---|---|
| More history, one symbol | `bin/rails 'data:deepen[NVDA,10]'` in production |
| More history, everything | `bin/rails 'data:deepen_all[10]'` in production |
| A routine sync | the scheduled jobs, in production |
| Local analysis, backtests, probes | `bin/prod-sync`, then read `prodmirror_development` |

`data:deepen` routes through `DataSourceRegistry.for_capability(:historical, …)`
rather than naming a gateway, so each asset deepens from the source that already
owns it — Alpaca for US equities, DataBursatil for the BMV, Yahoo only where
neither serves. It inserts the dates an asset lacks and never rewrites a row it
already has, which keeps provenance stable and makes the task safe to re-run.

`bin/prod-sync` and the mirror are documented in
[`docs/ops/prod-mirror.md`](../../ops/prod-mirror.md).

## The exception, and its shape

A **provider probe** — establishing whether an endpoint exists, what a response
looks like, what a plan actually serves — is not covered by this rule. It is a
handful of calls whose product is knowledge, not rows, and it has to happen
wherever the person doing the work is. `redesign/probes/` is where those live.

The line is what the call is *for*: filling the database is production's job;
finding out what a provider does is not.

## Consequences

- A local checkout with no API keys is a fully working development environment.
  Missing keys stop being a setup failure and become the normal state.
- Research is reproducible, because everyone reads the same mirrored rows rather
  than each fetching their own slightly different copy.
- The cost is a round trip: needing deeper history means deepening production
  first and re-syncing, rather than fetching on the spot. That round trip is the
  point — it is what turns a one-off local fetch into data the product keeps.
