# Stockerly — docs/

> Living project documentation. `vision/`, `architecture/` and `ops/` are kept current. **`research/` is not** — each research note is a dated snapshot of what was known on
> the day it was written, and carries an as-of banner naming what has superseded it since. Read
> those for how a decision was reached, not for what the code does today. For the history that
> led to the current single-user pivot, see [`1.0-retrospective.md`](./1.0-retrospective.md).

---

## How to navigate

| If you're looking for... | Go to |
|---|---|
| Why Stockerly exists, for whom | [`vision/`](./vision/) |
| Immutable architecture decisions | [`architecture/adr/`](./architecture/adr/) |
| How bounded contexts are organized | [`architecture/README.md`](./architecture/README.md) |
| Design system (source of truth, Pencil-based) | [`../design/`](../design/) |
| Research: expert panel, competitive survey, provider audit (**dated snapshots**) | [`research/`](./research/) |
| Deploy, security, runbooks | [`ops/`](./ops/) |
| How work moves: the board, issues, research | [`ops/github-workflow.md`](./ops/github-workflow.md) |
| Artboards used as the README's imagery | [`../design/exports/`](../design/exports/) |
| Captures of a running instance (only where no artboard exists) | [`screenshots/`](./screenshots/) |
| Why Stockerly pivoted to a single-user tracker | [`1.0-retrospective.md`](./1.0-retrospective.md) |

---

## Hard rules

1. **One source of truth per type.** Vision in `vision/`, decisions in `architecture/adr/`, and
   **all outstanding work in the private `Stockerly` GitHub Project** — never in a markdown file.
   See [ADR-022](./architecture/adr/0022-github-as-the-system-of-record.md) and
   [`ops/github-workflow.md`](./ops/github-workflow.md). Never duplicate.
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

Lives at `../.kwik-e/`, which is **gitignored** (`.gitignore`) — it is not part of this repo and
is not visible to anyone cloning it. It is Adrian's private working memory, synced separately, and
auto-loaded by the assistant at session start. Anything a contributor needs belongs in `docs/`
instead. Documents here may not link into it: those links resolve for nobody else.
