# Open Source Security Checklist

Use this checklist before making the repository public and before major releases.

## One-Time Before Public Launch

- [ ] Confirm no real secrets are tracked: `git ls-files | rg -n '\.env($|\.)|config/master\.key|config/credentials.*\.key|\.pem$|\.p12$|\.pfx$|\.key$'`
- [ ] Confirm no secrets in history: `gitleaks git --redact --config .gitleaks.toml` — scans every
      commit with the full default ruleset plus this repo's allowlist, which is what
      `bin/pre-commit` already uses on staged changes. A hand-written `git grep` over
      `$(git rev-list --all)` covers three patterns and re-walks the whole tree once per commit;
      prefer the tool the repo already configures.
- [ ] Enable GitHub Secret Scanning and Push Protection
- [ ] Enable GitHub Private Vulnerability Reporting
- [ ] Verify `.gitignore` includes `.env*` and key files
- [ ] Ensure `config/master.key` and `config/credentials/*.key` are never committed
- [ ] Review public docs for personal data exposure (emails, phone numbers, IP addresses)

## Every Pull Request

Two workflows run, and only one of them can block a merge. Know which is which before treating a
green checkmark as a clearance.

**Gates — a failure fails the PR** (`.github/workflows/ci.yml`):

- [ ] `bin/brakeman --no-pager` passes (job `scan_ruby`)
- [ ] `bin/bundler-audit` passes (job `scan_ruby`)
- [ ] `bin/importmap audit` passes (job `scan_js`)
- [ ] `bundle exec rspec` and `bin/rubocop` pass

**Report-only — read the findings by hand** (`.github/workflows/quality.yml` → `rodacato/sector-7g`
reusable `security.yml`, called with `blocking: false`, which sets `continue-on-error` on all three):

- [ ] Reviewed the **Semgrep** (SAST) findings
- [ ] Reviewed the **Trivy** (deps + secrets + IaC) findings
- [ ] Reviewed the **Gitleaks** (secret scan) findings

> Gitleaks **cannot fail a PR here.** A leaked secret shows up as a passing check with findings
> buried in the job log. The blocking defence is `bin/pre-commit` on your machine — install it.
> Flipping any of the three to enforcing is a one-line change (`blocking: true`) in
> `quality.yml`; it is a deliberate decision, not an oversight to fix in passing.

SonarQube also lives in `quality.yml` but is `workflow_dispatch`-only — it does not run on a PR at
all.

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
