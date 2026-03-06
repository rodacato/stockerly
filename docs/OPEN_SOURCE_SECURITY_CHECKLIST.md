# Open Source Security Checklist

Use this checklist before making the repository public and before major releases.

## One-Time Before Public Launch

- [ ] Confirm no real secrets are tracked: `git ls-files | rg -n '\.env($|\.)|config/master\.key|config/credentials.*\.key|\.pem$|\.p12$|\.pfx$|\.key$'`
- [ ] Confirm no secrets in history: `git --no-pager grep -I -n -E 'AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY' $(git rev-list --all)`
- [ ] Enable GitHub Secret Scanning and Push Protection
- [ ] Enable GitHub Private Vulnerability Reporting
- [ ] Verify `.gitignore` includes `.env*` and key files
- [ ] Ensure `config/master.key` and `config/credentials/*.key` are never committed
- [ ] Review public docs for personal data exposure (emails, phone numbers, IP addresses)

## Every Pull Request

- [ ] CI security workflow passes (`Gitleaks`, `Brakeman`, `bundler-audit`)
- [ ] New env vars are documented only in `.env.example` without values
- [ ] No logs or screenshots include tokens, API keys, or user-sensitive data
- [ ] Any new integration stores credentials encrypted and masked in UI

## Every Release

- [ ] Rotate deployment/API credentials if team membership changed
- [ ] Audit GitHub repository secrets and remove unused entries
- [ ] Review dependency vulnerabilities (`bin/bundler-audit`, `bin/importmap audit`)
- [ ] Run static security scan (`bin/brakeman`)
- [ ] Verify alerting is configured for runtime errors and suspicious failures

## Local Developer Guardrails

- [ ] Install commit hook once per clone: `bin/setup-hooks`
- [ ] Keep local `.env` files untracked
- [ ] Use separate credentials for development vs production
- [ ] Never paste secrets into issues, PR comments, or commit messages
