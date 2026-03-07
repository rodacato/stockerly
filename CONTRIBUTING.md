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

Visit `http://localhost:3000`. The seed creates an admin user: `admin@stockerly.com` / `password123`.

### Running Tests

```bash
bundle exec rspec                                    # Full suite (~2080 specs)
bundle exec rspec spec/contexts/trading/             # One context
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb      # One file
bundle exec rspec spec/contexts/trading/use_cases/execute_trade_spec.rb:15   # One example
```

### Linting & Security

```bash
bin/rubocop           # Linting (auto-correct with -A)
bin/ci                # Full CI pipeline (rubocop + bundler-audit + importmap audit + brakeman + rspec)
```

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

## Making Changes

1. Create a branch from `master`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Write your code with tests:
   - Use Case specs go in `spec/contexts/{context}/use_cases/`
   - Contract specs go in `spec/contexts/{context}/contracts/`
   - Request specs go in `spec/requests/`
   - System specs go in `spec/system/`

3. Run the full CI check:
   ```bash
   bin/ci
   ```

4. Commit with a clear message and push:
   ```bash
   git push origin feature/your-feature-name
   ```

5. Open a Pull Request against `master`

## Commit Messages

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the first line under 70 characters
- Add a blank line and a body for context if needed
- One commit per logical change

Examples:
```
Add volume spike detection to AlertEvaluator

Evaluate volume_spike condition by comparing current volume against
5-day average multiplied by the configured threshold.
```

## Code Conventions

- **Language:** All code, comments, and documentation in English
- **Style:** Follow existing patterns — run `bin/rubocop` to verify
- **Testing:** Every Use Case and Contract should have specs
- **No over-engineering:** Only implement what's needed. See the [working principles](IDENTITY.md#principios-de-trabajo)
- **No Devise:** Auth uses `has_secure_password`
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
- Check the [ROADMAP.md](ROADMAP.md) to see what's planned
- Review [docs/spec/EXPERTS.md](docs/spec/EXPERTS.md) for domain-specific guidance
