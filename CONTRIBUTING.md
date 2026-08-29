# Contributing to Stockerly

Thank you for your interest in contributing! Stockerly is 100% open source and welcomes contributions of all kinds: bug fixes, features, documentation, and testing.

## Getting Started

### Option 1: Devcontainer (Recommended)

1. Fork the repository
2. Clone your fork
3. Open in VS Code and select **"Reopen in Container"** (or launch in GitHub Codespaces)
4. The `postCreateCommand` script installs dependencies, creates the database, and runs migrations automatically

### Option 2: Manual Setup

1. Fork the repository
2. Clone your fork
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Set up the database:
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

## Development

### Running the App

```bash
bin/dev                # Rails server + Tailwind CSS watcher
```

Visit `http://localhost:4100` (`Procfile.dev` binds 4100, not Rails' default 3000). The seeds
create four demo users, all non-admin; sign in as `demo@stockerly.com` / `password123`. See
[GETTING_STARTED.md](GETTING_STARTED.md) for how to reach the Setup Wizard or get an admin.

### Running Tests

```bash
bundle exec rspec                                    # Full suite (3,007 examples as of 2026-08-29)
bundle exec rspec spec/contexts/trading/             # One context
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb      # One file
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb:15   # One example
```

### Linting & Security

```bash
bin/rubocop           # Linting (auto-correct with -A)
bin/ci                # setup + rubocop + bundler-audit + importmap audit + brakeman
```

**`bin/ci` does not run the tests.** `config/ci.rb` declares no RSpec step, so run
`bundle exec rspec` yourself alongside it. (The GitHub Actions workflow
`.github/workflows/ci.yml` is a different pipeline and *does* run RSpec — plus
`i18n-tasks health`, which fails on missing, unused, or unnormalized locale keys.)

### Background Jobs

```bash
bin/jobs              # Starts Solid Queue worker
```

## Project Architecture

Stockerly uses **DDD + Hexagonal Architecture**. Code is organized by bounded context, not by technical layer:

```
app/contexts/{context}/
├── contracts/     # Input validation (Dry::Validation)
├── domain/        # Pure business logic
├── events/        # Immutable domain events (Dry::Struct)
├── gateways/      # HTTP adapters (Market Data only)
├── handlers/      # Event reaction logic
└── use_cases/     # Orchestration (Dry::Monads Success/Failure)
```

### Key Patterns

- **Use Cases** inherit from `ApplicationUseCase` and return `Success`/`Failure` monads
- **Contracts** validate all input at system boundaries
- **Events** enable cross-context communication (no direct imports between contexts)
- **Controllers** are thin: delegate to Use Cases and pattern-match on results

See [CLAUDE.md](CLAUDE.md) for the complete architecture reference.

## Where work comes from

**GitHub is the system of record** ([ADR-022](docs/architecture/adr/0022-github-as-the-system-of-record.md)).
No markdown file in this repo states what is open — the private `Stockerly` Project holds every
outstanding item, and anything ready to build is promoted to a public Issue first.
[`docs/ops/github-workflow.md`](docs/ops/github-workflow.md) is the operational manual and is
required reading before opening an issue or a PR.

A feature needs all four filters before it becomes an issue: a documented personal trigger, a
JTBD, a usage metric, and a Definition of Done. Without them it stays a draft on the board. The
issue templates in [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) enforce this.

## Making Changes

1. Create a branch from the latest `master`:
   ```bash
   git fetch origin
   git checkout -b feat/your-change origin/master --no-track
   ```

   `--no-track` matters: without it the new branch's upstream becomes `origin/master`, and a later
   `git push -u origin <branch>` resolves against that upstream and pushes straight to `master`,
   bypassing branch protection. Push with an explicit refspec — `git push -u origin <branch>:<branch>`.

   Branch prefixes mirror the commit prefixes below: `feat/`, `fix/`, `chore/`, `docs/`,
   `refactor/`, `test/`.

2. Write your code with tests:
   - Use Case specs go in `spec/contexts/{context}/use_cases/`
   - Contract specs go in `spec/contexts/{context}/contracts/`
   - Request specs go in `spec/requests/`
   - System specs go in `spec/system/`

3. Run the full check — both commands, since `bin/ci` has no test step:
   ```bash
   bin/ci
   bundle exec rspec
   ```

4. Commit with a clear message and push the branch with an explicit refspec:
   ```bash
   git push -u origin feat/your-change:feat/your-change
   ```

5. Open a Pull Request against `master`. **Its body must carry `Closes #N`** (or `Fixes #N` /
   `Resolves #N`) for every issue it resolves — that keyword is the only thing that closes an
   issue on merge, and a missed one leaves the board lying about what is open.

6. If the change is visual, say which artboard in [`design/exports/`](design/exports/) it
   implements, or re-export the artboard if the design moved. The design system in
   [`design/`](design/) is the source of truth for what a screen should look like.

## Commit Messages

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the first line under 70 characters
- Add a blank line and a body for context if needed
- One commit per logical change
- No `Co-Authored-By` line, and no AI attribution anywhere in the message

**Prefixes.** Carried here from `docs/sprints/README.md` when that folder was retired — the
taxonomy outlived the sprint protocol that defined it.

| Prefix | For |
|---|---|
| `feat(<ctx>):` | new functionality |
| `refactor(<ctx>):` | internal change |
| `fix:` | bug fix |
| `chore:` | maintenance, cleanup |
| `docs:` | documentation only |
| `test:` | tests only |

`<ctx>` is the bounded context the change lands in — `trading`, `market-data`, `alerts`,
`identity`, `notifications`, `admin`. **Each commit references its issue**, e.g.
`feat(trading): capture FX at execution [#27]`.

Examples:
```
Add volume spike detection to AlertEvaluator

Evaluate volume_spike condition by comparing current volume against
5-day average multiplied by the configured threshold.
```

## Code Conventions

- **Language:** Code, comments, commits, issues, PRs and everything under `docs/` in **English**
  — including routes (`/dashboard`, `/tracked`, `/alerts`). Everything the user reads is **es-MX**
- **Copy goes through I18n:** user-facing strings live in `config/locales/es-MX.yml` behind lazy
  lookups (`t(".key")`), managed with `i18n-tasks` — CI runs `i18n-tasks health` and fails on
  missing, unused or unnormalized keys. Single locale; a second one is not a goal
  ([ADR-011](docs/architecture/adr/0011-adopt-i18n-for-the-2.0-rewrite.md), superseding ADR-007).
  Hardcoded es-MX in a view the 2.0 redesign has not reached yet is expected, not a defect
- **Descriptive, never prescriptive:** Stockerly reports what it observes; it does not tell the
  user what to do ([ADR-001](docs/architecture/adr/0001-descriptive-not-prescriptive-language.md))
- **Style:** Follow existing patterns — run `bin/rubocop` to verify
- **Testing:** Every Use Case and Contract should have specs
- **No over-engineering:** Only implement what's needed. See the [working principles](IDENTITY.md#working-principles)
- **No Devise:** Auth uses `has_secure_password`, with TOTP and recovery codes for the second
  factor ([ADR-018](docs/architecture/adr/0018-totp-with-recovery-codes.md))
- **No Ransack:** Search uses ActiveRecord scopes with ILIKE

## Security

Before committing, verify that you are **not** including:

- API keys, tokens, or passwords
- `config/master.key` or any `*.key` files
- `.env` files with real values
- Private SSH keys

Install local git hooks to catch accidental leaks:

```bash
bin/setup-hooks
```

See [SECURITY.md](SECURITY.md) for the full security policy and vulnerability reporting.

## Questions?

- Open an [issue](https://github.com/rodacato/stockerly/issues) for bugs or feature requests
- How work is tracked: [docs/ops/github-workflow.md](docs/ops/github-workflow.md) — the board, drafts, issues, PRs
- Review [docs/vision/](docs/vision/) to understand product direction
- Architecture map: [docs/architecture/](docs/architecture/) — bounded contexts and 19 ADRs
- Design system: [design/](design/) — Pencil files, ui-kit, and the exported artboards
- Product history: [docs/1.0-retrospective.md](docs/1.0-retrospective.md) — why Stockerly pivoted to a single-user tracker
