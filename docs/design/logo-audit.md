# Logo audit — S10 #124

Audit captured before opening the beta. Goal: cohesive visual identity across every surface a first beta amigo can reach, with graceful fallbacks where dynamic asset logos may fail to resolve.

Status: **applied** in [PR feat(logo): canonical wordmark + asset fallback (#124)].

---

## 1. Stockerly wordmark — sources of truth

| Asset | Path | Variant |
|---|---|---|
| Light theme | `public/logo_light.svg` | Wordmark on light background |
| Dark theme  | `public/logo_dark.svg`  | Wordmark on dark background |
| Glyph       | `docs/design/glyph.svg` (reference only, not rendered) | Mark only |

Per [docs/design/brand.md](brand.md), the wordmark is the primary identity. The glyph is reserved for tiny chrome (favicon, PWA icon — `public/favicon.svg`, `public/icon-192.svg`, `public/icon-512.svg`).

## 2. Canonical render — `shared/_logo`

All wordmark renders go through [`app/views/shared/_logo.html.erb`](../../app/views/shared/_logo.html.erb).

```erb
<%= render "shared/logo" %>                       # default h-9
<%= render "shared/logo", height_class: "h-7" %>  # admin sidebar
<%= render "shared/logo", height_class: "h-6" %>  # footer
```

Light/dark variants toggle via Tailwind's `dark:hidden` / `hidden dark:block` pair — no JS, no CSS-in-JS.

## 3. Inventory — surfaces that render the wordmark

| Surface | Partial | Height |
|---|---|---|
| Public navbar (landing + auth) | `shared/_public_navbar` | `h-9` (36px) |
| App navbar (authenticated) | `shared/_app_navbar` | `h-9` |
| Admin sidebar | `shared/_admin_sidebar` | `h-7` (28px) |
| Public footer | `shared/_public_footer` | `h-6` (24px) |
| Mailer layout (email header band) | `layouts/mailer.html.erb` | `32px` (inline `<img height>`) |

Email uses inline `<img height>` rather than a Tailwind class because most mail clients strip CSS — the height is set on the tag and the source is an absolute URL (`#{root_url}logo_light.svg`).

## 4. Asset logos — fallback chain

Dynamic asset logos (Apple, NVIDIA, BMV emisoras, etc.) are sourced from `Asset.logo_url`, populated by the existing Clearbit fallback chain in the asset sync pipeline.

The component [`components/_asset_badge`](../../app/views/components/_asset_badge.html.erb) is the single render point. Fallback order:

1. **No `logo_url`** → symbol-in-colored-box (color keyed to `asset_type`).
2. **`logo_url` present but 404 / network error** → `onerror` swaps to the same symbol-in-colored-box (hidden sibling element).
3. **Successful load** → the image renders, fallback stays hidden.

Loading is lazy (`loading: "lazy"`) so the initial paint of `/market` and `/portfolio` doesn't wait on the badge images.

Sizes: `sm` (32px), `md` (40px, default), `lg` (48px), `xl` (56px).

`market/_asset_header` previously had its own `onerror` + material-icon fallback path; it now delegates to `_asset_badge` so the fallback strategy is centralized.

## 5. Mailers

Every transactional email (`welcome`, `verify_email`, `password_reset`, `account_suspended`, `account_reactivated`) renders the mailer layout, which includes the logo header band + Stockerly footnote. Subjects and bodies are es-MX. The wordmark `<img>` uses an absolute URL so it survives Gmail's relative-URL stripping.

## 6. Decisions that were *not* made here

- **Logo redesign** — out of scope. Brand assets (`logo_light.svg`, `logo_dark.svg`) untouched.
- **Glyph-only contexts** — the navbar uses the full wordmark even at narrow breakpoints. Reconsider at S11+ if breakpoint testing shows it's too cramped.
- **PWA icons** — already in `public/icon-*.svg`, manifest already references them. Out of scope here.
- **Email plain-text variants** — only the layout-level `mailer.text.erb` was touched (logo header substitute). Individual per-mailer `.text.erb` templates are not generated; clients that prefer text get the HTML body stripped, which is fine for a closed beta of ≤20.

## 7. Next steps (deferred, not in this PR)

- Add `app/views/user_mailer/*.text.erb` plain-text variants per mailer (~30min, polish for deliverability).
- Investigate whether the navbar wordmark should collapse to glyph-only below `sm` breakpoint (mobile menu toggle currently lives on the right — the wordmark stays).
- Mailer subjects + bodies were also migrated to es-MX in this PR as a beta-readiness side-effect; remaining English copy in the bug-report mailer is a follow-up.
