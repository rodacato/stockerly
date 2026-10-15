# Stockerly brand kit

Lumen / **Soft Candle (G)** is Stockerly's identity: a rounded market candle drawn
with one continuous line. Stockerly is a self-hosted, single-user investment tracker
for stocks, crypto and Mexican fixed income across MXN and USD.

This folder is a generated export. It was assembled by `bin/brand-kit` from the
canonical sources in the repository; edit those and rebuild rather than editing these files.
[manifest.json](manifest.json) records the brand asset version and SHA-256 of each bundled file.
Repeated builds of the same inputs produce the same ZIP. Licensed under the MIT [license](LICENSE).

## What to use

| Material | Files | Use |
|---|---|---|
| Editable mark | [glyph.svg](logos/glyph.svg) | Small icon or single-color application; inherits `currentColor` |
| Outlined lettering | [lettering.svg](logos/lettering.svg) | Editable name geometry, independent of installed fonts |
| Light wordmark | [SVG](logos/wordmark-light.svg) · [PNG](logos/wordmark-light.png) | Light backgrounds |
| Dark wordmark | [SVG](logos/wordmark-dark.svg) · [PNG](logos/wordmark-dark.png) | Dark backgrounds |
| Monochrome wordmark | [SVG](logos/wordmark-mono.svg) · [PNG](logos/wordmark-mono.png) | Single-color output; supplied dark ink for light backgrounds |
| OG / Twitter, es-MX | [SVG](social/og-image.svg) · [PNG](social/og-image.png) | 1200 × 630 social card |
| OG / Twitter, English | [SVG](social/og-image-en.svg) · [PNG](social/og-image-en.png) | 1200 × 630 social card |
| GitHub preview, es-MX | [SVG](social/github-social-preview.svg) · [PNG](social/github-social-preview.png) | 1280 × 640; upload the PNG manually in repository settings |
| GitHub preview, English | [SVG](social/github-social-preview-en.svg) · [PNG](social/github-social-preview-en.png) | 1280 × 640; same manual upload |
| Web / PWA | [favicon](pwa/favicon.svg), [192 px](pwa/icon-192.png), [512 px](pwa/icon-512.png) | Transparent icons |
| Maskable | [192 px](pwa/icon-maskable-192.png), [512 px](pwa/icon-maskable-512.png) | Supplied opaque canvas and safe area |
| Apple / monochrome | [Apple touch icon](pwa/apple-touch-icon.png), [monochrome](pwa/icon-monochrome-512.png) | 180 px Apple icon; 512 px notification artwork |
| iOS launch artwork | [splash/](pwa/splash/) | Existing device sizes in light and dark modes |
| Offline artwork | [offline.html](pwa/offline.html) | App retry page; its `/dashboard` link requires a running instance |
| Marketing | [es-MX](marketing/index.html), [English](marketing/en.html), [brand reference](marketing/brand.html) | Static HTML, CSS, assets and fictional design artboards |
| Tokens / editable templates | [tokens.md](tokens.md), [CSS](sources/application.css), [templates/](sources/templates/) | Exported references to the existing system |

Use SVG for scalable layouts and PNG when the destination requires raster artwork.
Preserve the viewBox, rounded stroke, proportions and supplied clear margin. Use the wordmark
when the name must be read; use the mark at small sizes. Keep the outlined name in a readable
foreground color. Do not stretch, add shadows, redraw the candle or remove the maskable safe area.
For light monochrome ink, change the outer `color` in the SVG to suit the destination.

## Voice, typography and color

Describe observations: holdings, cost, unrealized result and available history. Name the currency,
period, date and source when relevant. Distinguish unavailable information from a real zero.
Avoid recommendations, guarantees, invented customers or testimonials. The app is es-MX;
the landing is bilingual. Keep the approved copy in the supplied templates.

Use **Plus Jakarta Sans** for headings, **Inter** for reading and controls, and **JetBrains Mono**
for precise values. The wordmark uses outlined paths and needs no fonts. Marketing HTML requests
these typefaces from Google Fonts and falls back to system fonts without a connection; font
binaries are not bundled. Social SVG text uses system font fallbacks; the PNG is the fixed export.

[tokens.md](tokens.md) lists the current light/dark color roles. Its source is
`app/assets/tailwind/application.css`, also exported under `sources/`. Reuse those semantic roles
instead of creating another palette. The kit contains exports, not a second token system.

## Preview the marketing pages

From this folder:

```bash
python3 -m http.server 3106 --bind 127.0.0.1 --directory marketing
```

Open `http://localhost:3106/`, `/en.html` and `/brand.html`. The pages include the existing
light/dark toggle and local asset downloads. Financial figures are fictional; the screen images
are labeled design artboards, not evidence from a live account. HTML metadata retains the
project's intended Pages URLs.

## Edit and regenerate

The exported templates are editable references, not a standalone Rails project. Work in the
full repository, where the canonical guide is
[design/brand/README.md](https://github.com/rodacato/stockerly/blob/master/design/brand/README.md).
After changing artwork or tokens, run `bin/brand-assets` (needs Chrome/Chromium; set `CHROME_PATH`
if needed) and then `bin/brand-kit`. Follow the coordinated `BrandAssets::VERSION` procedure for
app changes; copying kit artwork alone does not configure a PWA, service worker or push
notifications. The package creates no deployment and changes no GitHub settings. Pencil files
(`design/*.pen`) are outside this package.
