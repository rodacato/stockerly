# Stockerly / Lumen

Stockerly is a self-hosted, single-user investment tracker with MXN/USD support and
a Mexican-market focus. Its voice describes observations, dates and missing data;
it does not prescribe trades or promise returns.

## Sources

- [Glyph](glyph.svg): G / Soft Candle, one continuous rounded path on a 64-unit canvas.
- [Lettering](lettering.svg): outlined lettering; the wordmark needs no installed font.
- [Tokens](../../app/assets/tailwind/application.css): canonical colors, typography and shape.
- [Token reference](tokens.md): generated light/dark values, never edited manually.
- [Application logo](../../app/views/shared/_logo.html.erb) and
  [mark](../../app/views/shared/_logo_mark.html.erb): compose the canonical geometry inline.
- [Brand page source](templates/preview.html.erb): English brand reference, published as `brand.html`.
- [Landing source](templates/site.html.erb) and [copy](templates/site.yml): the es-MX and English marketing pages Pages serves at `/` and `/en.html`.

Use the supplied viewBox, stroke and proportions. The clear margin inside the
glyph canvas is part of the artwork. Use the wordmark where the name must be read,
the mark at small sizes, and a single foreground color for monochrome use. Choose
the light or dark wordmark for the destination surface; do not recolor the letters
with the accent. The mark refers to a market candle, without implying a direction.
Transparent normal icons use primary, readable against light and dark surfaces;
maskable and Apple icons carry their own light canvas. Monochrome exports keep one ink.

Plus Jakarta Sans carries headings, Inter carries reading and controls, and
JetBrains Mono carries values. These are the existing application font roles.

## Reproduction and downloads

```sh
bin/brand-assets                 # SVG, PNG, icons, splash screens, social cards, offline HTML
bin/rails tailwindcss:build       # Build the shared application tokens/utilities
bin/brand-preview                # Render tmp/brand-preview/index.html
bin/brand-preview --site         # Render the GitHub Pages output in site/ (landing ES/EN + brand.html)
python3 -m http.server 3106 --bind 127.0.0.1 --directory tmp/brand-preview
```

Open `http://localhost:3106`. The presentation has light/dark modes, fictional
portfolio figures and downloadable files. It is a local draft, not an application
route. Pages publishes the landing (`/`, es-MX; `en.html`, English) and the brand page
(`brand.html`) with production metadata. Landing copy lives in `site.yml`; it does not change the application locale.

Generated downloads live in [`public/brand/`](../../public/brand/). Normal,
maskable, monochrome and Apple icons live in [`public/`](../../public/). Social
sources are generated editable SVGs; their template lives in
[`templates/social.svg.erb`](templates/social.svg.erb). Asset URLs are coordinated
through [`BrandAssets::VERSION`](../../app/shared/domain/brand_assets.rb).
The application social cards are es-MX; `*-en` cards serve Pages. GitHub's 1280 × 640
preview is ready for manual upload; generating it does not change repository settings.
