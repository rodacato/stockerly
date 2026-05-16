# Stockerly Brand

> **Palette:** Lumen &middot; **Logo:** Focal frame &middot; **Established:** 2026-05-14 (Sprint S2, #34)

This is the single source of truth for how Stockerly looks and reads. For concrete token values see [`tokens.md`](./tokens.md); for the catalog of UI building blocks see [`components.md`](./components.md).

---

## 1. What Stockerly is, in one paragraph

A personal portfolio tracker for Mexican investors with mixed MXN+USD holdings — CETES, BMV equities, US stocks, crypto. Self-hosted, open source, closed beta to ≤20 invited friends. **Not** a trading platform, **not** an enterprise SaaS, **not** a public-funnel product. The audience is sophisticated enough to read a chart and skeptical enough to dismiss marketing language.

The brand answers two questions at every visual decision:

1. **Does this look like a tool an MX investor reaches for weekend after weekend?** (yes = quiet, dense, dependable)
2. **Does this lie?** (fake stats, fake testimonials, prescriptive verbs) (no — strip it)

## 2. Voice

Descriptive, never prescriptive. Formalized in [`ADR-001`](../architecture/adr/0001-descriptive-not-prescriptive-language.md).

- ✅ *"AAPL appears oversold per RSI(14)"*
- ✅ *"CETE 28D matures in 5 days"*
- ✅ *"Your USD positions changed by &minus;1.2% today, ~MXN&nbsp;9,420 in equivalent"*
- ❌ *"Buy AAPL now"*
- ❌ *"Consider selling"*
- ❌ *"Smart investors choose..."*

The same rule applies to button labels, empty states, error messages, and chart annotations. State what is, never what to do.

## 3. Visual principles

- **Data before decoration.** Numbers and charts get the focal weight; chrome stays quiet.
- **Generous whitespace, dense data.** Lumen's cream surfaces buy room for tight tables — the contrast is intentional, not contradictory.
- **One accent, two semantics.** Indigo is the only chrome accent. Green / red are reserved for gain / loss. Don't add a third.
- **Sharp typography, soft shadows.** Plus Jakarta Sans + Inter + JetBrains Mono. `shadow.sm` on cards is enough; nothing should glow.
- **Light AND dark are first-class.** Both palettes ship together. Default is light (cream); the toggle is real and persists per-user.
- **Honest defaults.** If a field has no value, say "—" not "0.00" or "N/A". If a sync failed, say so on the dashboard, not in a hidden log.

## 4. Inspiration mix

What we lean into:

- **Stripe / Notion / Mercury** — luminous, friendly, generous whitespace, soft surfaces. Lumen palette's warm cream comes from here.
- **Linear / Vercel** — sharp typography, precise grids, dark mode that genuinely belongs (not just inverted light).
- **Robinhood / Webull** — controlled drama in dense data tables (color-coded change%, sparklines, tight rows). We borrow the *density*, not the dopamine.

What we explicitly avoid:

- ❌ **Bloomberg terminal overwhelm.** Six-column orange-on-black walls of data.
- ❌ **Corporate-bank-blue.** Saturated navy, gold accents, "Trusted by Fortune 500".
- ❌ **Fake social proof.** Invented institutions, fabricated stats, testimonials from imaginary day traders.
- ❌ **Neon / saturated accents.** No `#00FF00` greens, no `#FF00FF` magentas.
- ❌ **Mascot characters or illustrations.** Material Symbols + data viz only.

## 5. Palette — Lumen (summary)

Full token tables in [`tokens.md`](./tokens.md). Short version:

- **Primary:** warm indigo `#5B6CFF` (light) → lifted `#7B89FF` (dark) for AA contrast on cream/warm-dark surfaces.
- **Canvas:** cream off-white `#FAFAF7` (light) / warm dark `#1A1B23` (dark). Not pure white, not cold-slate dark.
- **Positive:** emerald `#10B981` / `#34D399`. **Negative:** coral `#F43F5E` / `#FB7185`. **Warning:** amber `#F59E0B` / `#FBBF24`.
- **Info ≡ Primary.** Stockerly has one accent; semantic alias keeps consumer code clear.

### Why Lumen, not Cipher or Bourse

The audience is sophisticated MX individual investors, not a trading floor. Lumen sits closer to Mercury / Notion than to Bloomberg — which matches Stockerly's calm, descriptive voice. **Cipher** was a close second and may return for a future "pro mode"; **Bourse** read too institutional for a self-hosted personal tool.

## 6. Typography

Three families, fixed. Full sizes in [`tokens.md`](./tokens.md).

| Family | Use |
|---|---|
| **Plus Jakarta Sans** (600, 700) | Display, H1–H3, dashboard titles. Warmer than Inter at large sizes. |
| **Inter** (400, 500) | Body, labels, forms, sidebar, all general UI text. |
| **JetBrains Mono** (500) | All financial numbers — prices, percentages, table cells, KPI values. Aligned digits matter. |

**Why monospace for numbers:** column alignment in dense tables. Inter's variable-width digits make `1,000.00` and `999.50` not line up; JetBrains Mono fixes that without making the rest of the UI feel like a terminal.

## 7. Logo — Focal frame

A square viewfinder formed by four L-bracket corners around a single weighted dot. Single SVG, `currentColor` fill, light/dark via CSS color inheritance.

**Why focal frame, not monogram or wordmark-only:**

The metaphor is **observation, not transaction**. Four brackets around a dot say "you are watching this position", which lines up with the descriptive copy convention. The geometric monogram lost crispness at 16 px (favicon stress); the wordmark+mark concept leaned too pre-IPO-startup. The focal frame is the only sub-32-px candidate that doesn't collapse into a generic letterform.

**Files** (all live alongside this doc in [`docs/design/`](.)):

- [`wordmark.svg`](./wordmark.svg) — horizontal lockup: glyph + "stockerly". Uses `currentColor`, works in both modes via CSS color inheritance.
- [`glyph.svg`](./glyph.svg) — glyph-only, square, favicon ≥ 24 px.
- [`glyph_thick.svg`](./glyph_thick.svg) — favicon ≤ 16 px stress variant (thicker strokes survive small rasterization).

For production paths (`public/`), the visual migration in Sprints S3–S6 will sync served files to these canonical SVGs. Until then, `public/` may still contain pre-S2 assets.

**Usage rules:**

- Glyph height = 24 px in the navbar lockup, 8 px gap to wordmark, wordmark cap-aligned to top of brackets.
- Minimum clearspace = height of the glyph on all sides.
- Don't stack vertically — brackets need horizontal context to read as a frame.
- For email signatures / OG images / external embeds where Plus Jakarta Sans isn't guaranteed, convert text to paths at build time (`oslllo-svg-fixer` or Fontello outline).

## 8. Theme toggle

- **Default:** light. The audience is reviewing on weekends, often in daylight; cream is more comfortable as the entry mode than dark-on-load.
- **Toggle behavior:** Three states — `system`, `light`, `dark`. Persists per-user in profile preferences (not just localStorage), so the same account in two devices stays consistent.
- **Toggle placement:** Navbar, next to user avatar. Material Symbol `light_mode` ↔ `dark_mode`.
- **Implementation hint:** Tailwind 4 `darkMode: 'class'` + a `<html class="dark">` toggle. The class is applied by a small Stimulus controller on `DOMContentLoaded` reading the user's preference.

## 9. Spanish-MX UI conventions

The audience reads Spanish natively (per [audience.md H2](../vision/audience.md)). UI copy is es-MX. Keep these phrasings consistent across new screens so the voice doesn't fragment:

| Concept | Use | Avoid |
|---|---|---|
| Dashboard greeting | "Buenas tardes, &lt;nombre&gt;." (or buenos días / buenas noches by hour) | "Hola!", "Welcome back" |
| Open positions section | "Posiciones abiertas" | "Mis acciones", "Stocks" |
| Closed positions | "Posiciones cerradas" | "Historial", "Pasado" |
| Gain/loss column | "Δ" or "Ganancia / Pérdida" | "Profit", "P&L" |
| Total portfolio value | "Valor total" | "Patrimonio total" (too formal) |
| Cash side | "Saldo disponible" | "Cash", "Liquidez" |
| Allocation breakdown | "Por sector" / "Por activo" / "Por geografía" | "Distribución" |
| News section | "Noticias" | "Feed", "Actualizaciones" |
| Alerts section | "Alertas" | "Notificaciones de mercado" |
| Trade entry button | "Registrar movimiento" | "Nuevo trade", "Add transaction" |
| Empty state for trades | "Sin movimientos aún." | "No data" |
| Date stamp on dashboard | "MIÉ · 14 MAY 2026 · 14:08 CDMX" | "Today, 2:08 PM" |
| Currency on KPI labels | "MXN" / "USD" tag right of the number | mixing $ symbols across currencies |

**Tone:** sober and direct. Avoid exclamation marks. Numbers carry the emotion.

### 9.1 Extended phrasebook (Renata's preliminary input — see [`components.md` §7](./components.md))

| Concept | Use | Avoid |
|---|---|---|
| Empty state — no positions yet | "Aún no hay posiciones registradas." | "No tienes acciones", "Vacío" |
| Empty state — no alerts firing | "Sin alertas activas." | "Todo en orden", "Sin novedad" |
| Empty state — sync never run | "Sin datos sincronizados todavía." | "Cargando...", "Sin conexión" |
| Loading (in-progress) | "Sincronizando..." (verb-ing; no ellipsis if rendered as a Badge) | "Cargando datos...", "Espera" |
| Server error, retryable | "No pudimos cargar esta sección. Reintentar." | "Algo salió mal", "Oops" |
| Server error, persistent | "Esta sección no está disponible ahora." (+ Reintentar) | "Error 500", "Falla del servidor" |
| Validation error (generic) | "Revisa los datos marcados." | "Hay errores en el formulario" |
| Validation error (specific email) | "Este correo ya está registrado." | "Email inválido" |
| Stale data badge | "Datos atrasados · sync 14:08 CDMX" | "Desactualizado", "Old data" |
| Delete confirm | "Eliminar esta posición de forma permanente." (statement, not question) | "¿Estás seguro?" |
| Save success (inline only, no toast) | "Guardado · 14:08 CDMX" | "¡Éxito!", "Guardado correctamente" |
| Time relative (within last hour) | "hace 12 min" | "Hace un rato", "Recientemente" |
| Time relative (today, earlier) | "hoy · 09:42 CDMX" | "Esta mañana", "Hoy temprano" |
| Time relative (yesterday) | "ayer · 17:30 CDMX" | "El día de ayer" |
| Time relative (older) | Absolute DateStamp only ("12 MAY 2026 · 14:08 CDMX") | "Hace 2 días" past 24 h |
| Currency formatting (MXN) | "MXN 47,210.45" (ISO code + space, no $ symbol on tables) | "$47,210.45 MXN", "$47,210.45" |
| Currency formatting (USD) | "USD 2,418.30" | "$2,418.30 USD", "USD$2,418.30" |
| Mixed-currency total | "MXN 856,420.00 equiv. (MXN+USD)" | "Total general" |
| Pluralization (positions) | "1 posición" / "5 posiciones" — never use "(s)" | "1 posición(es)" |
| Dividend | "Dividendo" | "Pago de dividendos", "Yield" |
| Sector vocabulary | "Tech · Energía · Financiero · Consumo · Salud · Industrial · Materiales · Utilidades · Inmobiliario · Comunicaciones" | mixing English sector names |
| Capital gain (realized) | "Ganancia realizada" | "Profit tomado" |
| Capital gain (unrealized) | "Ganancia no realizada" | "Plusvalía pendiente" |
| Asset class — fixed income | "Renta fija" | "Bonos", "Fixed income" |
| Asset class — equity | "Renta variable" | "Acciones" |
| CETES specifically | "CETE 28D" / "CETE 91D" / "CETE 182D" / "CETE 364D" | "CETES 28 días" |

## 10. How to apply this brand kit when generating new screens

This section is a workflow guide for future sessions with visual tools (Claude Design, Stitch, Figma AI). Paste relevant pieces of it into the prompt to keep new mockups consistent.

**Standard preamble for a new screen prompt:**

> Stockerly is a personal portfolio tracker for MX investors with mixed MXN+USD holdings. Closed beta, self-hosted, open source. Apply the Lumen brand kit: warm cream backgrounds, indigo accent, sober typography (Plus Jakarta Sans + Inter + JetBrains Mono). Voice is descriptive, never prescriptive. UI copy in es-MX. Logo is the focal frame glyph (four L-brackets + observation dot). See [`docs/design/`](docs/design/) for full tokens, palette, and components.

**Checklist before sending to a visual tool:**

- [ ] Specify both light and dark renders — never one only.
- [ ] Include 1–2 sample positions/values per row so the data carries the screen, not lorem.
- [ ] Use real MX brokerage symbology (`WALMEX.MX`, `CETE28D`, `IVVPESO.MX`) alongside US ones (`AAPL`, `NVDA`) — the dual-currency reality is part of the brand.
- [ ] Show the timezone-explicit date stamp at top: `"MIÉ · 14 MAY 2026 · 14:08 CDMX"`.
- [ ] Reference the focal-frame glyph in the navbar (don't redesign).
- [ ] Skip anything in the "What we explicitly avoid" list (§4).

**Checklist before accepting a mockup:**

- [ ] All copy is descriptive (ADR-001) — no "Buy", "Consider", "Don't miss".
- [ ] Gains green / losses coral, never reversed; no neon variants.
- [ ] Numeric cells use JetBrains Mono (look for digit-width consistency in tables).
- [ ] At least one empty state is rendered to verify the "—" convention.
- [ ] Dark mode is genuinely warm-dark (`#1A1B23` family), not slate-cold-dark.

### 10.1 End-to-end workflow (canonical post-S07)

The full operational workflow — expert-panel consultation → self-contained markdown prompt → GitHub issue comment → external generation → `.local/design-mockups/` storage → Lumen-fidelity audit → ERB translation with Tailwind tokens — is documented in the `project_design_workflow` memory entry (`.claude/memory/project_design_workflow.md`).

Validated at S07 close on five screens (`/privacy`, `/admin/invites`, `/welcome`, `/help`, `/report-bug`) with zero regenerations and zero mockup-vs-implementation drift. Adopt the same pattern for any new screen in S08+.

## 11. Decision Record

Captured for future reference when the brand is revisited or extended.

### 11.1 Palette (Sprint S2, 2026-05-14)

- **Chosen:** Lumen — warm indigo primary, cream off-white light bg, warm dark bg.
- **Considered + rejected:**
  - *Cipher* (Linear/Vercel-leaning, near-monochrome) — too cool for an MX audience that's looking at this on weekends rather than during a workday. May return as a future "pro mode" theme variant.
  - *Bourse* (refined fintech teal) — read too institutional / private-banking for a self-hosted personal tool. Lost the "weekend hobby" warmth.
- **One-line rationale:** Lumen + Focal frame reads "considered, calm, tracking tool" — never "trading platform" — which is what a closed-beta personal portfolio app for friends needs to communicate.

### 11.2 Logo concept (Sprint S2, 2026-05-14)

- **Chosen:** Concept 03 — Focal frame. Four L-bracket corners around a weighted observation point.
- **Considered + rejected:**
  - *Concept 01, Geometric monogram* (stylized "S") — lost crispness at 16 px favicon size, collapsed into a generic letterform.
  - *Concept 02, Wordmark + dot/mark* — leaned too pre-IPO-startup, didn't differentiate from a dozen YC-look-alikes.
- **One-line rationale:** "Observation, not transaction" — the bracket-frame metaphor reinforces ADR-001 visually. Survives the 16-px favicon stress test because brackets + dot read as a single object.

### 11.3 Typography (carried forward unchanged)

- **Chosen + retained:** Plus Jakarta Sans (display), Inter (body), JetBrains Mono (numeric). No change from pre-S2 stack.
- **One-line rationale:** Jakarta's warmth pairs with Lumen's cream; Inter's UI legibility is industry-standard; JetBrains Mono's tabular figures make dense tables line up without making the rest of the UI feel like a terminal.

### 11.4 Theme default (Sprint S2, 2026-05-14)

- **Chosen:** Light is the default-on-load. Dark is offered via a real toggle persisted to user preferences.
- **One-line rationale:** Audience reviews on weekends, often in daylight. Loading dark on a sunlit kitchen table is the wrong first impression.

## 12. When to update this doc

- A new component pattern gets used in 3+ screens and isn't in [`components.md`](./components.md).
- The audience expands beyond MX investors (a new currency, language, or context).
- Theme tokens drift in implementation — keep this doc and [`tokens.md`](./tokens.md) synced; periodic audit at sprint close.
- A new logo or palette variant ships — append to §11 rather than overwriting.

Never silently change tokens. Decisions ride in §11 forever, including the rejected options.
