---
name: project-design-workflow
description: "Canonical visual-design workflow: expert-panel prompts → GitHub issue comments → Claude Design generation → .local/ mockups → Lumen audit → ERB translation. Validated at S07 close on five screens with zero regenerations."
metadata:
  node_type: memory
  type: project
  status: validated
  validated-at: S07-close (2026-05-16)
---

> **Status: Validated.** Initially captured as work-in-progress during S07 mid-sprint and reassessed at S07 close on 2026-05-16. Five screens (`/privacy`, `/admin/invites`, `/welcome`, `/help`, `/report-bug`) shipped through this workflow with zero regenerations needed and zero mockup-vs-implementation drift. The workflow is now the canonical approach for any new screen in Stockerly. Promoted to `docs/design/brand.md` §11 (link from `docs/design/brand.md` to this memory).

## The workflow (canonical, post-S07)

For each S07 issue that needs a screen (#73 `/privacy`, #74 `/admin/invites`, #77 `/welcome` + `/help` + `/report-bug`):

1. **Consult the expert panel** (`docs/research/experts.md`) — typically C5 Renata (UX/UI), C4 Marisol (Hotwire + Tailwind), and a situational expert (S5 Ileana for legal, etc.).
2. **Compose a self-contained design prompt** that embeds Lumen palette + typography + voice rules + screen-specific content + acceptance checklist, so the visual tool doesn't need access to `docs/design/`.
3. **Post the prompt as a comment on the GitHub issue** (not as a file in the repo) — keeps repo clean, makes the prompt persistent + trackable + grep-able from GH search.
4. **Adrian runs the prompt through Claude Design / Stitch / Figma AI** externally, exports the result.
5. **Mockups land in `.local/design-mockups/<Batch>/<screen>/`** — gitignored. Current batch: `Stockerly-1.0/` (5 screens generated 2026-05-16; one missing initially: `/welcome`, added later same day).
6. **Audit the mockup against Lumen** before implementing (palette match, typography, voice, brand avoid-list).
7. **Implement in ERB** translating mockup structure to Tailwind utility classes that resolve to canonical Lumen tokens.

See [[project-design-assets]] for the inventory/mapping side of this.

---

## Adrian's feedback (2026-05-16, captured verbatim)

> "El proceso me ha gustado, el involucrar a los expertos para tener algo más predecible, como manejamos los prompts como comentarios aunque preferiría que el prompt esté en un bloque de markdown, hasta la generación misma de las pantallas Claude Design lo está haciendo perfecto, también el manejo de .local me parece todo muy acertado para seguir haciéndolo, pero quiero que este feedback del proyecto esté como work in progress hasta terminar el sprint y ver qué tan bien funcionó, incluido tu feedback para mejorarlo."

Extracted points:

- ✅ **Expert panel involvement** — adds predictability to design output. Keep.
- ✅ **`.local/` for mockups** — clean separation, no repo pollution, persistent across sessions. Keep.
- ✅ **Claude Design generation quality** — output is "perfect" so far per Adrian's read. Confirmed by the `/welcome` audit (focal-frame motif applied creatively but on-brand; copy verbatim from prompt; palette 100% Lumen).
- ⚠️ **Prompt format in GitHub comments** — works, but Adrian prefers the prompt itself be wrapped in a **markdown code block** (fenced ` ``` `) instead of the current "blockquote with `>` prefix" style. Easier to copy-paste cleanly to the visual tool without `>` artifacts.

---

## My feedback (Claude, mid-sprint observation)

What is working well:

- The brand kit (`docs/design/brand.md` §10 standard preamble + `tokens.md`) being self-contained let me compose paste-ready prompts in one pass per screen. No back-and-forth assembling context.
- The expert consultation forces explicit constraints (Renata: "no hero, no mascot, max-w 768"; Ileana on `/privacy`: "no aspirational copy"). Those constraints surface as `Avoid` lists in the prompt and reach the visual tool unfiltered.
- Audit-before-implementing caught zero drift in `Stockerly-1.0/` so far. The `colors_and_type.css` files match Lumen hex-for-hex; the extras (chip-bg, primary-tint, motion tokens, z-index scale) are additive, not conflicting.
- Posting prompts as GH issue comments rather than repo files keeps `git log` and `docs/` clean. Single source of anchor per issue.
- `Welcome.jsx` showed Claude Design can apply brand metaphors creatively (using the focal frame as a quiet motif in the BetaCard) — better than over-prescribed mockups that look identical to the prompt.

What to improve (suggested):

- **Prompt format:** Switch from blockquote prose to fenced markdown code block per Adrian's preference. Concrete change: wrap the whole "Copy this block into the visual tool" section in ```` ``` ```` instead of `>`. Will require updating the 4 existing prompts in #73, #74, #77 comments — defer that touch-up to retro to avoid sprint scope creep, but use the new format for any prompt added post-2026-05-16.
- **Audit checklist as a script:** the Lumen-fidelity audit is currently manual (read `colors_and_type.css`, compare to `tokens.md`). Worth a small `script/audit-mockup.sh <mockup-folder>` that asserts the hex literals match the Lumen set. Defer to S08+.
- **Batch naming convention:** Currently `Stockerly-1.0/`. No rule for when `1.1` vs `2.0` happens or what gets versioned (palette change? full re-export? per-sprint?). Decide at close if a versioning rule is needed or if it stays implicit.
- **Mockup → ERB translation as a step worth tracking:** the JSX inline styles need to become Tailwind utilities. That's mechanical but not zero-effort. Consider a "translation pass" mini-protocol in the runbook if S07 reveals friction here.
- **Severe brand voice violation contingency:** no procedure yet for "what if the mockup contradicts ADR-001 voice rules" (e.g., generates exclamation marks despite the prompt forbidding them). Hasn't happened, but worth a contingency line in the audit step.

---

## Reassessment outcome (S07 close, 2026-05-16)

Each checkpoint from the original reassessment plan, with concrete answers from the sprint:

- ✅ **Zero regenerations needed.** Five screens shipped (`/privacy`, `/admin/invites`, `/welcome`, `/help`, `/report-bug`); none were re-generated due to drift. Target met.
- ✅ **JSX layout translated to ERB cleanly.** Structure preserved verbatim across all five; only the styling layer changed from inline-style to Tailwind utility classes. `Welcome.jsx`'s `helpVariant` prop pattern translated to a shared `_welcome_body.html.erb` partial used by both `/welcome` and `/help`.
- ✅ **Lumen audit was fast (<5 min per screen).** The `colors_and_type.css` check is a quick read against `tokens.md`. Automation isn't worth it at this volume.
- ✅ **Expert consultation changed the output meaningfully.** C5 Renata's "no full-page hero" and "max-w-2xl centered container" constraints, S5 Ileana's LFPDPPP-section list, and C4 Marisol's "Tailwind arbitrary values instead of raw hex" all shaped the prompts in ways that landed in the mockups.
- ✅ **Prompt-in-comment format worked.** No review friction; the comment URL is easy to share and the design tool ingests the markdown cleanly. Adrian's preference for fenced code blocks over blockquote prose became the new default mid-sprint and worked well on the `/welcome` prompt regeneration.

**Conclusion: promoted to canonical.** Status moves from work-in-progress to validated; reassess clause dropped; this memory is now the reference for the workflow. A short §11 entry in `docs/design/brand.md` points readers here for the operational detail.

---

## Related memories

- [[project-design-assets]] — inventory + Lumen-fidelity audit + workflow when implementing a mockup-backed screen
- [[stockerly-working-method]] — sprint protocol + GitHub Issues + .claude/memory/ + discovery card requirement
- [[project-expert-panel-v2]] — 8 Core + 8 Situational experts canonical at `docs/research/experts.md`
