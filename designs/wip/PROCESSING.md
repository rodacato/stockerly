# Processing Stitch Design Exports — Stockerly

> Workflow for processing new Google Stitch exports into the `designs/` directory structure.

---

## Directory Convention

New designs go into zone-based folders:

```
designs/
├── public/{page}/          # Public pages (landing, login, trends, etc.)
├── legal/{page}/           # Legal pages (privacy, terms, risk-disclosure)
├── app/{page}/             # Authenticated pages (dashboard, market, portfolio, etc.)
├── admin/{page}/           # Admin pages (assets, logs, users)
├── shared/{component}/     # Shared components (onboarding, notifications, etc.)
└── wip/                    # Temporary: raw Stitch exports before processing
```

Each page folder contains:

| File | Description |
|---|---|
| `screen.png` | Visual mockup screenshot from Stitch |
| `code.html` | Standalone Tailwind HTML reference from Stitch |
| `SPEC.md` | Page specification: route, models, Stimulus controllers, status |

For multi-variant pages, use suffixes: `screen-step1.png`, `code-step1.html`, etc.

---

## Processing Steps

When new designs are exported from Stitch:

### 1. Place raw exports in `designs/wip/`

```bash
# Stitch exports arrive with auto-generated folder names
designs/wip/generated_screen_1/
designs/wip/my_new_page_export/
```

### 2. Identify target destination

Map each export to its zone and page name based on content.

### 3. Move and rename files

```bash
# Example: new feature page
mv designs/wip/{stitch-folder}/screen.png designs/{zone}/{page}/screen.png
mv designs/wip/{stitch-folder}/code.html  designs/{zone}/{page}/code.html
```

### 4. Create SPEC.md

Write a SPEC.md for the page with:
- Route, layout, controller, view path
- Sections and UI elements
- Data requirements (models needed)
- Forms and actions (HTTP methods, Stimulus controllers, Turbo Frames/Streams)
- Implementation status

### 5. Expert review

Consult relevant experts from `docs/spec/EXPERTS.md`:

```
Review the design for [PAGE] (designs/{zone}/{page}/screen.png) against:
1. The page SPEC.md
2. The PRD requirements (docs/spec/PRD.md)
3. Relevant expert profiles

Evaluate:
- Does the design cover all elements in the SPEC.md?
- Are there elements in the design not in the SPEC.md? (update it)
- Is it consistent with the design system (colors, typography, icons)?
- What feedback would the experts give?
```

### 6. Update specification docs

If the new design introduces changes, update:
- `docs/spec/PRD.md` — Add Feature ID if needed
- `docs/spec/COMMANDS.md` — Add Use Cases / Events if needed
- `docs/spec/DATABASE_SCHEMA.md` — Add models if needed
- `docs/spec/TECHNICAL_SPEC.md` — Add Stimulus controllers / Turbo config if needed

### 7. Clean up WIP

```bash
rm -rf designs/wip/{stitch-folder}/
```

### 8. Commit

```bash
git add designs/{zone}/{page}/
git commit -m "design: add stitch export for {page-name}"
```
