# ADR-012 — Separate the token contract from theme values, so themes are possible later

- **Status:** Accepted
- **Date:** 2026-08-24
- **Author:** Adrian Castillo
- **Supersedes:** —
- **Related:** [ADR-010](./0010-pivot-to-self-hosted-single-user-tracker.md), [ADR-011](./0011-adopt-i18n-for-the-2.0-rewrite.md), `design/DECISIONS.md` D1, `design/ui-kit.CHANGELOG.md`

---

## Context

The 2.0 redesign converged design and code on one palette — **Lumen** (indigo `#5B6CFF`, warm
canvas, semantic positive/negative/warning/info), 45 `--color-*` tokens in `@theme` plus dark
overrides. D1 settled the *values*; nothing has settled whether those values are **the** palette or
**a** palette.

Adrian wants themes eventually. The ask is not to build a theme picker now — it is to **consolidate
in that direction** so support can be added without re-touching every view, with what exists today
becoming the default theme.

Two things make this the right moment: the ERB translation has not started (so no view depends on
the current structure yet), and there is a collision waiting in the CSS.

**The collision.** `app/assets/tailwind/application.css` already uses `data-theme` — but for the
*mode*:

```css
:where(html.dark, [data-theme="dark"]) { --color-bg-canvas: #1A1B23; ... }
```

So `data-theme` currently means light/dark. Introducing named themes on the same attribute would
make `data-theme` mean two different things, and the first named theme would silently break dark
mode. This must be untangled **before** themes exist, not after.

## Decision

**Two independent axes: `theme` (which palette) and `mode` (light or dark). The token names are a
contract; only their values are theme-scoped.**

1. **The contract is the token names.** `--color-primary`, `--color-bg-surface`, `--color-fg-subtle`
   and the rest never change meaning. Views and components reference roles, never values, and never
   a raw hex. This already holds in the `.pen` kit (D1) and in most of `app/views`; it becomes the
   rule for everything the redesign touches.
2. **`data-theme` names the palette, not the mode.** Today's palette is **`lumen`**, and it is the
   default: `<html data-theme="lumen">`. The existing `[data-theme="dark"]` selector is retired as
   part of this change — it is the collision above.
3. **Mode stays where it is:** the `dark` class (`@custom-variant dark`), honouring the system
   preference and the user's explicit choice, exactly as the profile's theme picker already does.
4. **Values live in theme blocks; `@theme` maps the contract to them.** A palette is one block of
   light values and one of dark values, so adding a theme is adding a block — not editing views.
5. **Ship one theme.** No picker, no second palette, no abstraction beyond the two axes. The point
   is that the *second* theme costs a file; building it now would be inventing a need
   ([[feedback-cost-justified-tech]]).

## How to apply

- Land the restructure **before** the first redesign slice, while zero new views depend on it.
- New copy of the rule for any view work: a raw hex in a template is a bug; a token the palette
  lacks is a gap to log, not a value to inline (the same rule the `.pen` kit already enforces).
- The design side already models this: the kit carries `mode: light | dark` as a theme axis, so a
  `theme` axis is additive there too whenever a second palette exists.

## Consequences

### Positive

- Themes become a data change instead of a code change.
- The `data-theme` ambiguity dies before it can cause a bug, at the only moment when nothing depends
  on it.
- Forces the last raw hexes out of the templates the redesign rewrites.

### Negative

- One more indirection between a token and its value.
- The restructure touches a widely-imported CSS file, so it wants its own small PR with a visual
  check rather than riding a feature slice.

### Follow-ups

- The profile's theme picker keeps controlling **mode**; if a palette picker ever ships it is a
  second control, not a replacement.
