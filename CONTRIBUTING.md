# Contributing to Stockerly

## Getting Started

1. Fork the repository
2. Clone your fork and open it in a devcontainer (VS Code or GitHub Codespaces)
3. The `postCreateCommand` script handles setup automatically

## Development

- **Ruby on Rails 8** with PostgreSQL
- **Tailwind CSS 4** for styling
- **Solid Queue** for background jobs

### Running the app

```bash
bin/dev
```

### Running tests

```bash
bin/rails test
```

## Making Changes

1. Create a branch from `master`:
   ```bash
   git checkout -b your-feature-name
   ```
2. Make your changes
3. Run the test suite and make sure it passes
4. Commit with a clear message describing the change
5. Push and open a Pull Request against `master`

## Commit Messages

Follow this style:

- Use the imperative mood ("Add feature" not "Added feature")
- Keep the first line under 70 characters
- Add a blank line and a body for context if needed

## Security

Before committing, verify that you are **not** including:

- API keys, tokens, or passwords
- `config/master.key` or any `*.key` files
- `.env` files with real values
- Private SSH keys

See [SECURITY.md](SECURITY.md) for the full security policy.

## Code Style

- Follow existing patterns in the codebase
- Use Ruby LSP for formatting Ruby files
- Use Prettier for JavaScript/CSS files

## Questions?

Open an issue or reach out to the maintainers.
