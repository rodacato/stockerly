# Security Policy

## Supported Versions

Only the latest released version receives security patches. Stockerly is self-hosted, so the
version that matters is the one on your instance, not the one on `master`.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly. **Do not open a public issue.**

Use **GitHub Private Vulnerability Reporting**:

1. Go to the repository's **Security** tab
2. Click **Report a vulnerability**
3. Include:
	- A description of the vulnerability
	- Steps to reproduce the issue
	- Any potential impact

If private reporting is unavailable, open a private discussion with maintainers before disclosure.

### Disclosure timeline

- **0 days** — reported
- **48 hours** — acknowledgment
- **7 days** — assessment and fix development
- **30 days** — fix released and **advisory published**

The advisory is not optional and it is not a leak. Stockerly is self-hosted: whoever stood up an
instance learns they must upgrade from the published advisory and from nothing else, because that
is what `bundler-audit` and Dependabot read. It is drafted privately and published only once the
fix has shipped — the opposite of describing an unpatched weakness in public, which is what an
issue would do and why issues are not the channel.

### Scope

In scope: authentication and authorization bypass, injection (SQL, command, template), XSS and
CSRF, SSRF through a market-data gateway, exposure of one instance's holdings or credentials, and
anything that lets an unauthenticated caller reach trading or portfolio data.

Out of scope: vulnerabilities in third-party dependencies (report those upstream), denial of
service, social engineering, and anything requiring access to the host the operator already
controls.

## Sensitive Files

The following files contain or reference secrets and **must never be committed** with real values:

| File | Purpose |
|------|---------|
| `config/master.key` | Decrypts Rails credentials |
| `config/credentials/*.key` | Environment-specific credential keys |
| `.env*` (except `.env.example`) | Local environment variables |
| `.kamal/secrets` | References to deployment secrets (values come from environment) |

## What Is Already Protected

- **`.gitignore`** excludes `/config/*.key` (the master key), `/config/credentials/*.key` (the
  per-environment keys), `/.env*` except `/.env.example`, and `/storage/*` except `/storage/.keep`.
  All of these patterns are **anchored to the repository root** — `/config/*.key` alone does not
  match a key nested under `config/credentials/`, which is why both key patterns are listed.
  Verify any pattern you rely on with `git check-ignore -v <path>` rather than assuming.
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

## What CI Does Not Block

The Gitleaks, Semgrep and Trivy jobs in `.github/workflows/quality.yml` are **report-only**
(`SECURITY_BLOCKING: "false"`): a leaked secret shows up as a passing check with findings in the job
log. The blocking defence is the local pre-commit hook — install it once per clone with
`bin/setup-hooks`. The PR gates are `brakeman`, `bundler-audit` and `importmap audit` in `ci.yml`.

## Secret Leak Response

If a secret is accidentally committed:

1. Revoke and rotate the secret immediately
2. Remove it from git history (`git filter-repo`), then force-push
3. Invalidate affected sessions/tokens
4. Document impact and remediation in a private incident note
