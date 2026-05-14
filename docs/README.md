# Stockerly — docs/

> Living project documentation. **Every file here reflects the current reality.** Aspirational/historical material lives in `docs/archive/`.
>
> Structure established in Sprint 1 (2026-05-14).

---

## How to navigate

| If you're looking for... | Go to |
|---|---|
| Why Stockerly exists, for whom | [`vision/`](./vision/) |
| Immutable architecture decisions | [`architecture/adr/`](./architecture/adr/) |
| How bounded contexts are organized | [`architecture/README.md`](./architecture/README.md) |
| Design system: palette, typography, components, logos, decision record | [`design/`](./design/) |
| Research notes, code audits, expert panel | [`research/`](./research/) |
| Deploy, security, runbooks | [`ops/`](./ops/) |
| Sprint protocol, retros | [`sprints/`](./sprints/) |
| Screenshots for README/showcase | [`screenshots/`](./screenshots/) |
| Archived documents (NOT current source of truth) | [`archive/`](./archive/) |

---

## Hard rules

1. **One source of truth per type.** Vision in `vision/`, decisions in `architecture/adr/`, backlog in GitHub Issues, sprints in GitHub Projects. Never duplicate.
2. **If it's in `archive/`, it's not current truth.** Map it to its live equivalent above.
3. **Doc > 200 lines: audit it.** Is it a reference or fiction? Useful documentation fits on a single screen.
4. **Edits to `vision/` or `architecture/adr/`** require a commit message explaining the reason.

---

## Root-of-repo documents (referenced from here)

| Doc | Purpose |
|---|---|
| [`/IDENTITY.md`](../IDENTITY.md) | Role and commitments of the AI assistant |
| [`/CLAUDE.md`](../CLAUDE.md) | Technical context the AI assistant reads automatically |
| [`/README.md`](../README.md) | Public-facing project introduction |
| [`/CONTRIBUTING.md`](../CONTRIBUTING.md) | (Reserved — closed beta, no PRs accepted until v1.0) |
| [`/RELEASING.md`](../RELEASING.md) | Release process |
| [`/CHANGELOG.md`](../CHANGELOG.md) | Significant changes history |
| [`/SECURITY.md`](../SECURITY.md) | Vulnerability reporting |

---

## AI assistant's persistent memory

Lives at [`../.claude/memory/`](../.claude/memory/). Tracked in git and auto-loaded by the assistant. Contains user profile, vision, decisions, anti-patterns, and brutal-honesty mandate.
