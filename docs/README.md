# Stockerly — docs/

> Living project documentation. **Every file here reflects the current reality.** For the history that led to the current single-user pivot, see [`1.0-retrospective.md`](./1.0-retrospective.md).

---

## How to navigate

| If you're looking for... | Go to |
|---|---|
| Why Stockerly exists, for whom | [`vision/`](./vision/) |
| Immutable architecture decisions | [`architecture/adr/`](./architecture/adr/) |
| How bounded contexts are organized | [`architecture/README.md`](./architecture/README.md) |
| Design system (source of truth, Pencil-based) | [`../design/`](../design/) |
| Research: expert panel, competitive survey | [`research/`](./research/) |
| Deploy, security, runbooks | [`ops/`](./ops/) |
| Sprint protocol and template | [`sprints/`](./sprints/) |
| Screenshots for README/showcase | [`screenshots/`](./screenshots/) |
| Why Stockerly pivoted to a single-user tracker | [`1.0-retrospective.md`](./1.0-retrospective.md) |

---

## Hard rules

1. **One source of truth per type.** Vision in `vision/`, decisions in `architecture/adr/`, backlog in GitHub Issues, sprints in GitHub Projects. Never duplicate.
2. **Doc > 200 lines: audit it.** Is it a reference or fiction? Useful documentation fits on a single screen.
3. **Edits to `vision/` or `architecture/adr/`** require a commit message explaining the reason.

---

## Root-of-repo documents (referenced from here)

| Doc | Purpose |
|---|---|
| [`/IDENTITY.md`](../IDENTITY.md) | Role and commitments of the AI assistant |
| [`/CLAUDE.md`](../CLAUDE.md) | Technical context the AI assistant reads automatically |
| [`/README.md`](../README.md) | Public-facing project introduction |
| [`/CONTRIBUTING.md`](../CONTRIBUTING.md) | How to contribute (open source) |
| [`/RELEASING.md`](../RELEASING.md) | Release process |
| [`/CHANGELOG.md`](../CHANGELOG.md) | Significant changes history |
| [`/SECURITY.md`](../SECURITY.md) | Vulnerability reporting |

---

## AI assistant's persistent memory

Lives at [`../.kwik-e/memory/`](../.kwik-e/memory/). Tracked in git and auto-loaded by the assistant. Contains user profile, vision, decisions, anti-patterns, and brutal-honesty mandate.
