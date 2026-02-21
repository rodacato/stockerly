# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly. **Do not open a public issue.**

Send an email to **rodacato@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce the issue
- Any potential impact

You will receive a response within 48 hours.

## Sensitive Files

The following files contain or reference secrets and **must never be committed** with real values:

| File | Purpose |
|------|---------|
| `config/master.key` | Decrypts Rails credentials |
| `config/credentials/*.key` | Environment-specific credential keys |
| `.env*` (except `.env.example`) | Local environment variables |
| `.kamal/secrets` | References to deployment secrets (values come from environment) |

## What Is Already Protected

- **`.gitignore`** excludes `config/*.key`, `.env*` files, and `/storage/*`
- **Rails credentials** are encrypted at rest (`config/credentials.yml.enc`)
- **Deployment secrets** are stored in GitHub Actions Secrets and injected at deploy time — never hardcoded
- **Container images** are stored in GitHub Container Registry (ghcr.io) as private packages
- **Database passwords** are managed through environment variables, never in config files

## Guidelines for Contributors

1. **Never commit secrets** — no API keys, passwords, tokens, or private keys
2. **Use Rails credentials** (`bin/rails credentials:edit`) for application secrets
3. **Use environment variables** for infrastructure secrets (database, registry, etc.)
4. **Do not log sensitive data** — avoid logging params that may contain passwords or tokens
5. **Keep dependencies updated** — run `bundle audit` periodically to check for known vulnerabilities
6. **Review `.gitignore`** before committing — ensure no sensitive files are staged
