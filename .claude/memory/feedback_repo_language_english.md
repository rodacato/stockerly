---
name: repo-artifacts-in-english-conversation-in-spanish-ui-in-es-mx
description: "Adrian explicitly requested 2026-05-14: communication with him in Spanish, but anything committed to the repo (commits, issues, PRs, documentation, code, comments) MUST be in English. The user-facing UI (views, copy, error messages, emails to users) is es-MX. Confirmed 2026-05-18."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 304a846f-9186-4678-bff5-d986163ce3f1
---

**Rule:**

| Where | Language |
|---|---|
| Chat conversation with Adrian | Español |
| Plans, drafts, brainstorming in chat | Español OK |
| Git commit messages | **English** |
| GitHub issue titles and bodies | **English** |
| GitHub PR titles, bodies, comments | **English** |
| GitHub Project items, labels, milestones | **English** |
| Documentation in `docs/` (anything committed) | **English** |
| Code comments | **English** |
| ADRs | **English** |
| Memory files in `.claude/memory/` | **English** (already are) |
| `IDENTITY.md`, `CLAUDE.md`, `README.md`, etc. | **English** |
| **`app/views/**`*` (user-facing UI)** | **es-MX** |
| **Error/flash messages shown to the user** | **es-MX** |
| **User-facing emails (Mailers)** | **es-MX** |
| **Page titles, meta descriptions, OG tags** | **es-MX** |
| Specs that assert UI content | es-MX strings to match the view, but English `describe`/`it` titles |

**Why:** Adrian stated 2026-05-14: *"me gusta que los commits, issues, task y documentacion del proyecto este en ingles, solo me comunico contigo en español"*. Confirmed 2026-05-18: *"el codigo, issues, tickets casi todo esta en ingles y me gusta, solo el sitio es en español mexicano"*. The repo is public + portfolio value — English maximizes audience and signals professional polish. The conversation can stay Spanish because that's our private collaboration channel. The product is for Mexican investors, so the UI must feel native to that audience.

**How to apply:**
- When writing a draft IN chat → Spanish OK
- Before committing or creating an issue → translate to English
- When writing a view, flash, email, or any user-facing copy → es-MX
- Even if Adrian writes in Spanish, the artifact (commit/issue/code) must be in English
- Code comments: minimal anyway per anti-pattern #4; when written, English
- Specs that match UI content use the actual es-MX strings inside `expect/include/fill_in`, but the spec descriptions (`describe`, `it`) stay English

**Edge cases:**
- Quotes from Adrian (verbatim in Spanish) inside an artifact: keep verbatim with `> *"..."*` block, OK as data
- Spanish proper nouns (CETES, Banxico, SAT, IPC, CDMX): keep as-is (technical terms)
- Adrian's name, locations: keep as-is
- Legal documents (`docs/legal/`, ADRs about compliance): English (docs) but the rendered view in `app/views/legal/` is es-MX

**No i18n infrastructure today.** As of 2026-05-19 (S09 close, issue #113 closed wont-fix) there is no `config/locales/es-MX.yml` — strings are hardcoded in views. Retrofitting to `t(".key")` is **deferred indefinitely** with explicit re-visit triggers:

- Bilingual support (es-MX + en) becomes a real product goal (e.g. opening beyond Mexican audience), OR
- LLM/contributor capacity is idle (no higher-value features in flight) AND someone wants to do the migration as cleanup.

Until then, hardcoded es-MX is the explicit convention, not an oversight. Gemini reviewer suggestions to adopt I18n are redirected to closed issue #113 + [ADR-0007](../../docs/architecture/adr/0007-defer-i18n-adoption.md) instead of debated per PR.

**Self-check before any `git commit`, `gh issue create`, `gh pr create`, or file in `docs/`:** is the artifact in English? If not, translate before committing. Inverse self-check before a view or flash: is the user-facing copy es-MX?
