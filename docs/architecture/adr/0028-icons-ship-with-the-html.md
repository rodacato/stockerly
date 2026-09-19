# ADR-028 — Icons ship inside the HTML, not as a remote ligature font

- **Status:** Accepted
- **Date:** 2026-09-19
- **Author:** Adrian Castillo
- **Related:** [ADR-019](./0019-self-contained-by-default.md), [ADR-027](./0027-production-is-the-only-instance-that-spends-quota.md)

---

## Context

Every icon in the app was a Material Symbols ligature: `<span class="material-symbols-outlined">chevron_right</span>`.
Drawing it required three network hops to land, in order — `app.css`, then Google's stylesheet at
`fonts.googleapis.com`, then the woff2 at `fonts.gstatic.com`. When any of them failed, the fallback
of a ligature font is **the word itself**, so the screen read `chevron_right` where a chevron belonged.

The failure was reported three times. Board item #637, *Icons render as ligature text on a cold font
cache*, was closed against it. So was #638, which unblocked the service worker's font fetch in the
CSP. Neither held, and the third report is what produced this ADR.

Each fix had treated the symptom. `display=block` was read as "never show the fallback"; it gives a
short block period and then swaps to the fallback anyway, so it delayed the English word by three
seconds rather than preventing it. Importing the sheet into `layer(base)` fixed a real and separate
bug — Google's unlayered `font-size: 24px` was beating every Tailwind size class — but it did nothing
about the dependency.

**Why the PWA and not the desktop.** The service worker cached Google Fonts cache-first but never
precached them, so the cache existed only *after* a successful fetch. An installed app cold-starting
offline or on a bad connection has nothing to read. On desktop there had always been a good fetch first.

## Decision

**An icon is an inline SVG, vendored in the repo and rendered into the HTML.**

The invariant this buys, and the one the previous three fixes could not state:

> If the page rendered, the icon rendered.

Only something travelling inside a resource that already had to load — the HTML or `app.css` — satisfies
it. Anything in a file of its own is a resource that can fail on its own, which makes the bug rarer
rather than absent.

Implementation: the `rails_icons` gem with a custom library at
`app/assets/svg/icons/material_symbols/`, behind the project's own `icon_svg` helper. The gem's sync
generator cannot be used — Google nests each icon in its own directory and the generator expects a flat
one — so `script/vendor_icons.rb` fetches the names listed in `script/icon_names.txt`, strips `width`
and `height` so CSS decides the size, and sets `fill="currentColor"` so the icon takes the colour of
the text around it.

**The icon family does not change.** The names are the same Material Symbols names, so the Pencil
ui-kit, `design/DECISIONS.md` and every `text-*` size class at the call sites are untouched. This
changes delivery, not the design contract.

## Alternatives rejected

**Self-hosting the woff2, with codepoints instead of ligatures.** Cheap, and it turns the symptom
from an English word into a brief tofu box. It does not close the invariant: the font is still a file
that can fail alone. Kept on the shelf as the cheap mitigation, not as the fix.

**An external SVG sprite** (`<use href="/icons.svg#x">`). Trades a third party for same-origin, which
is better, and leaves the same class of bug: one request that can fail and take every icon with it.

**A subsetted woff2 base64-encoded into `app.css`.** This *does* close the invariant, and it is the
only option with a zero-line diff in the views. Rejected on cost: roughly +22 KB on a render-blocking
stylesheet that is 48 KB today, and it buys a font-subsetting step that does not exist in the repo and
that must preserve ligatures. A build step that runs rarely is a build step that rots.

**CSS `mask-image` with data-URI SVGs.** Closes the invariant too, but the call-site diff is identical
to inline SVG — every span still has to lose its text content — so it saves no work and costs
debuggability.

## Consequences

- **Text fonts are unchanged and still remote.** Plus Jakarta Sans, Inter and JetBrains Mono stay on
  Google with `display=swap`. Their fallback is readable text, which is a different severity. Closing
  that is a separate decision.
- **A name nobody vendored is now a 500, not a missing glyph** — `rails_icons` raises. Two things
  cover it: `bin/checks icons` catches the literals without booting Rails, and the suite catches the
  names assembled at runtime. Both were needed; the static check alone missed nine names that came
  from data, and the suite alone would not run in a lint job.
- **A new icon costs a line in `script/icon_names.txt` and a re-run of the vendoring script.** The
  check says so when it fires.
- **The ligature text is gone, and specs used to read it.** `data-icon` on the rendered `<svg>` carries
  the name, which is what the assertions now use.
- **Per-page weight grows by roughly 160 bytes per icon**, re-sent on each Turbo navigation and heavily
  compressed. Measured against a 48 KB stylesheet, it is noise.
