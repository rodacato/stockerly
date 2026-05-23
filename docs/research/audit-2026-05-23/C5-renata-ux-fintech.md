# C5 Renata Câmara — UX/UI Fintech Audit

> "The product feels intentional about being honest, but it doesn't yet look honest — token migration is halfway; some screens whisper while others shout; the first three taps teach the right lesson, but the dashboard stops teaching after tap one."

---

## State of the product through my lens

Adrian opens Stockerly on a Saturday afternoon. The first screen he sees is the dashboard — a quiet, well-designed greeting band with his portfolio delta and current time. That's good. It builds trust. He can scan the four KPI cards and immediately see: total portfolio value, today's gain, CETES maturing soon, and cash. Three seconds in, he knows the state.

Then he scrolls. The sentiment band shows his watchlist sentiment plus Fear & Greed for crypto and stocks. Helpful observation, well-designed gauge. He's still trusting the system.

Then he scrolls more. The watchlist table appears — clean, readable, Lumen tokens visible. The columns make sense: ticker, name, type, price, 24h change, 7d sparkline. A beta amigo would read this in two seconds: "I see what's moving."

But the sidebar panels below start falling apart. They whisper. The headings use old typography rules (not the eyebrow+title pattern). The backgrounds feel cold — not the warm cream that the KPI cards above use. A sidebar card for "Market Indices" uses raw hex colors that don't match the main dashboard. The "Weekly Insight" card lives in a primary-filled gradient (not a Lumen neutral surface). The empty state for "No watchlist yet" uses Lumen tokens cleanly, but the sidebar that should teach the user what to do next looks like it was designed in a different era.

When Adrian goes to his portfolio page, the header is perfect: eyebrow, title, subtitle. The KPI cards look good. The performance chart is there. But the card backgrounds revert to old slate. The allocation sidebar on the right uses a pre-Lumen color palette — the donut chart colors don't align with Lumen's hue set.

Login and password recovery pages still use `shadow-xl` (too heavy per the brand spec) and cold-slate dark (#0F1923) instead of warm-dark (#1A1B23).

The alerts page has the new Lumen structure (eyebrow, title, mini-KPIs), but the mini-cards use slate borders and backgrounds instead of the token-named utilities that the KPI strip one screen over uses.

**In summary:** The visual migration is 60% complete. The header bands are Lumen-clean. The main tables are Lumen-clean. But cards, buttons, form inputs, and backgrounds use a mix of old and new tokens — creating a visual stutter. A user won't consciously notice "oh, this uses the wrong palette," but they'll feel it: *this doesn't quite belong to the same product.*

---

## What delivers value (observations that are right)

1. **Descriptive copy, no prescriptive verbs.** Every observable string follows ADR-001 perfectly. No "Buy now", no "Consider selling", no "you should rebalance". Copy describes state: "AAPL appears oversold per RSI(14)", "3 of your tech positions entered oversold simultaneously this week". This is the hardest discipline to enforce in fintech, and it's working.

2. **Mono on all numbers, all the time.** Every price, percentage, and KPI value uses JetBrains Mono. The columns align. The cognitive load is low. Contrast this with the rest of the UI which uses Inter — the visual hierarchy is clear: "this is a number I should read carefully."

3. **The focal frame metaphor, expressed in the KPI strip.** Four cards, each has one primary number. "Valor total" is the anchor; the delta is a sub-reading. No secondary numbers shouting equally. That's the right hierarchy.

4. **Empty states are kind.** "Aún no sigues ningún activo" instead of "Your watchlist is empty". The copy invites action without being prescriptive: "Explorar el mercado" (explore) not "Start buying".

5. **Dark mode is real and intentional.** Both light and dark are readable. The warm-dark (#1A1B23) from Lumen is actually in the CSS tokens — not an afterthought. The dark mode isn't just an inverted light mode; it's designed as a first-class citizen.

6. **The sentiment band is observational.** The watchlist sentiment, crypto F&G, and stocks F&G are presented as *readings*, not *signals*. No "market is overbought, consider selling" language. This screen teaches without prescribing.

---

## What's missing (prioritized gaps)

### 1. **Visual consistency: Card backgrounds and borders are a two-tone story (CRITICAL)**

**File:** `app/views/dashboard/_kpi_card.html.erb:26`, portfolio page, alerts headers, earnings headers

**The gap:** Dashboard KPI cards use `bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800`. Lumen specifies `bg-bg-surface border border-border-default` (which map to the same hex values, but the inconsistency is the problem). When Adrian switches between the main dashboard (token names) and the portfolio page (slate literals), the backgrounds look slightly different.

**The fix:** Search-and-replace on card chrome across all user-facing views:
- `bg-white dark:bg-slate-900` → `bg-bg-surface`
- `border border-slate-200 dark:border-slate-800` → `border border-border-default`
- ~40 minutes of grep + replace.

**Why it matters:** Consistency builds subconscious trust. A user doesn't consciously notice the palette is wrong, but they *feel* the visual friction. This is the single largest contributor to "Stockerly feels assembled from different sources."

---

### 2. **Sidebar cards don't follow the eyebrow+title pattern (MEDIUM PRIORITY)**

**Files:** `app/views/dashboard/_weekly_insight.html.erb:5`, `_upcoming_events.html.erb:8`, `notable_observations.html.erb:7`, `_market_status.html.erb`

**The gap:** Main dashboard sections use Lumen pattern: eyebrow (`text-[11px] uppercase tracking-widest`) + H2 (`text-3xl font-extrabold`). Sidebar panels use H3 or `text-lg font-bold` (pre-Lumen pattern). When Adrian glances at the dashboard, the sidebar feels equally important as the main content because it uses the same heading weight.

**The fix:** Add eyebrow + reduce H3 weight:
- Add `<p class="text-[11px] font-semibold uppercase tracking-widest text-fg-subtle">Section name</p>` above each H3.
- Change H3 from `text-lg font-bold` to `text-base font-semibold`.
- Consider removing `shadow-sm` from sidebar cards or reducing to `border-only` chrome.
- ~20 minutes for dashboard; applies to other pages too.

**Why it matters:** Information architecture. Right now the sidebar shouts as loud as the main area. Making it quieter teaches Adrian: "scan the main numbers first, then the sidebar for context." This accelerates decision-making.

---

### 3. **Auth pages use heavy shadows and cold-dark palette (MEDIUM PRIORITY)**

**Files:** `app/views/sessions/new.html.erb:4`, `password_resets/new.html.erb`, `registrations/new.html.erb`

**The gap:** Auth cards use `shadow-xl` (too heavy per brand.md §3 "Sharp typography, soft shadows") and `bg-slate-900` (cold slate #0F1923, not Lumen warm-dark #1A1B23). Form inputs use `border-slate-200` instead of token-named borders.

**The fix:**
- Replace `shadow-xl` → `shadow-sm`.
- Replace `bg-white dark:bg-slate-900` → `bg-bg-surface`.
- Replace form input borders with token-named utilities.
- ~15 minutes.

**Why it matters:** Auth pages are the first impression for a beta amigo. Heavy shadow + cold palette reads as "old/corporate". Lumen reads as "modern/intentional". The difference is micro, but it shapes trust in seconds—especially on mobile where every pixel matters.

---

### 4. **Portfolio allocation sidebar uses pre-Lumen hex colors (HIGH PRIORITY)**

**File:** `app/views/portfolios/_allocation_sidebar.html.erb:2`

**The gap:** The donut chart color array contains hardcoded hex values like `#005A98` (pre-Lumen primary blue). When rendered, the colors don't match Lumen warm-indigo (#5B6CFF). The allocation donut is one of Adrian's most-viewed charts; if it's the wrong color, the whole portfolio page feels off-brand.

**The fix:** Replace hardcoded hex values with CSS custom properties referencing Lumen tokens. Define a heatmap-style 5-color palette in `application.css` (like Fear & Greed already does as a documented exception per tokens.md §4.2). ~20 minutes.

**Why it matters:** The allocation sidebar is the second thing Adrian looks at after the KPI strip. If it's visually inconsistent, the product feels improvised.

---

### 5. **Some copy still mixes es-MX vocabulary inconsistently (MEDIUM PRIORITY)**

**Example:** `components/index_card.html.erb` has `title="Open"/"Closed"` (English). This was noted in S10 audit but unfixed.

**The gap:** The 3-zone rule (controller strings → es-MX, view labels → es-MX, error messages → es-MX) is mostly followed, but there's leakage. S10 audit noted 30+ exact locations.

**The fix:** Grep for English strings in views and translate:
- `title="Open"/"Closed"` → `title="Abierto"/"Cerrado"`
- Any remaining English Material Symbol labels
- ~2 hours total, but tractable (mostly 1-line fixes).

**Why it matters:** A beta amigo reading entirely in Spanish should not hit English. Right now they will.

---

## What doesn't work (anti-patterns committed)

### 1. **Information hierarchy is unclear — sidebar has equal visual weight to main content**

The dashboard uses an 8/4 grid (8 cols main, 4 cols sidebar). But visually, the sidebar headings are the same weight as the main headings. They should be lighter. A user scanning in 2 seconds should see: main watchlist + sentiment. Sidebar (events, market status, insights) is secondary reading.

**Current state:** All sidebar cards use same `rounded-xl shadow-sm` chrome as main cards. Headings are too bold. Result: the user's eye doesn't know where to look.

**Fix:** See gap #2 above (eyebrow + reduce weight). This is solved by the visual hierarchy recommendation.

---

### 2. **Fear & Greed card is descriptively correct but visually dense**

The Fear & Greed card is correct on copy (readings, not signals). But it's packed: gauge + sparkline + 5 sub-indicator labels + timestamp. It's "dense without being clearly dense" — more "crammed" than "tight".

**Fix:** Either simplify sub-indicators (show 2–3 instead of 5) or add breathing room (increase padding, reduce font size). The mockup doesn't show sub-indicators at all; they may not add value.

---

### 3. **No visual affordance for interactivity on sparklines**

The 7-day sparkline in the watchlist table isn't marked as clickable or non-interactive. A user (especially on mobile) won't know whether to tap it.

**Fix:** Add `cursor-pointer hover:opacity-75` if clickable, or remove any hover state if not.

---

## Top 3 recommendations for Adrian's personal use case

### 1. **Migrate remaining card backgrounds to Lumen tokens — URGENCY: HIGH (visual coherence)**

**What to change:** Search-and-replace across all views:
- `bg-white dark:bg-slate-900` → `bg-bg-surface`
- `border border-slate-200 dark:border-slate-800` → `border border-border-default`
- `shadow-xl` → `shadow-sm`

**Why:** Right now, Adrian opens the dashboard (clean), scrolls to sidebar (looks off), then goes to portfolio (looks off). The micro-inconsistencies add up to "this feels assembled from different sources."

**Expected effect on decision speed:** Subconscious confidence boost. Visual consistency = brand trust. Adrian will feel the product is more cohesive, which builds confidence in the numbers.

**Estimated effort:** 40 minutes of grep + replace across ~30 files.

---

### 2. **Add eyebrow headings + reduce visual weight of sidebar sections — URGENCY: MEDIUM (information architecture)**

**What to change:**
- Add eyebrow labels above all sidebar H3s.
- Reduce H3 from `text-lg font-bold` to `text-base font-semibold`.
- Remove shadows from sidebar cards (use `border` only).

**Why:** Adrian's attention is limited. The sidebar should be *secondary* whitespace, not equally dense as the main area. This teaches him "scan main first, then sidebar if you want context."

**Expected effect on decision speed:** Adrian lands on important numbers faster. The first 3 taps show him portfolio total, today's change, watchlist sentiment — without the sidebar competing for attention.

**Estimated effort:** 20 minutes for dashboard.

---

### 3. **Unify empty states with Lumen eyebrow + body pattern — URGENCY: MEDIUM (consistency + trust)**

**What to change:** Every dashboard empty state (no watchlist, no events, no observations) should follow one pattern:
- Eyebrow + H2 + body + optional icon
- Descriptive copy per ADR-001 (observation + action, not prescription)

**Why:** Empty states are high-leverage moments. First-time users see them; returning users see them when filters clear. If they're inconsistent or prescriptive, the product feels broken. Right now they're scattered across different files and styles.

**Expected effect on decision speed:** First-time beta amigos land on an empty state and immediately understand what to do. No confusion. Trust is built.

**Estimated effort:** 2 hours (audit all empty states, standardize copy, deploy across 3–5 partials).

---

## Closing observation

Stockerly is doing something rare: choosing *honesty* over *motivation*. The copy describes what is happening, not what Adrian should do. The dashboard shows signal, not noise. Dark mode is real.

But the product is only *halfway* through its visual migration. The foundation (Lumen tokens in CSS) is there. The structure (eyebrow + title pattern) is there in main surfaces. But execution is scattered — some views Lumen-clean, others pre-Lumen.

A beta amigo opening it for the first time will see a product that *wants* to be coherent but isn't quite there yet.

**Current state: 6.5/10. With these three fixes: 8.5/10.**

The recommended changes are not about adding features. They're about finishing what's already started. Once the visual migration is done and information hierarchy is clear, Stockerly will look like what it is: a tool for investors who want signal, not noise. Quiet. Dense. Dependable.
