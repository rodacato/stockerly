# Audit 07 — Presentation layer (views, helpers, Stimulus, Tailwind, locales)

**Scope:** `app/views/` (149 ERB), `app/helpers/` (20 files / 1,452 lines), `app/javascript/controllers/` (27 controllers), `app/assets/tailwind/application.css`, `config/locales/`.
**Date:** 2026-08-30 · branch `fix/capture-daily-volume` · read-only.
**Reference docs read:** `CLAUDE.md`, ADR-0011 (I18n), ADR-0012 (token contract), `design/README.md`, `design/DECISIONS.md` (D1, D9, D10, D36, D48, D58, D69), `docs/research/experts.md` panel roles.

**No P0.** Nothing here loses data or leaks credentials. But the layer has a systemic problem that *is* correctness-adjacent for a financial product: **there is no single formatter for money, percent, or dates**, and the token contract ADR-012 declares is honoured by roughly 60% of the surface. Everything below is P1 or P2, ranked.

**One thing worth saying up front, in fairness:** `i18n-tasks health` is green — 959 keys, zero missing, zero unused, normalized. The catalogue itself is in better shape than most single-locale projects ever get. The problems are around it, not in it.

---

## P1

### [VIEW-01] Money is rendered five different ways; `format_currency_mx` is bypassed in ~20 places
- **Severity:** P1
- **Effort:** M
- **Where:**
  - Canonical: `app/helpers/dashboard_helper.rb:57` (`format_currency_mx`) — used at 21 call sites
  - Hand-rolled duplicate: `app/views/market/_analyst_target.html.erb:29,33,46,47,52,54`; `app/views/market/_price_chart.html.erb:19,21,46`; `app/views/market/_dividend_history.html.erb:19,43`; `app/views/market/_earnings_tab.html.erb:61,64`
  - Hardcoded currency literal: `app/views/market/_fixed_income_detail.html.erb:50,57,114`
  - Bare `$`, no ISO code: `app/helpers/fundamentals_helper.rb:62,64,66,68`
  - No currency at all: `app/views/dashboard/_patrimonio_strip.html.erb:13`
- **Evidence:**
  ```erb
  <%# _analyst_target.html.erb:29 — reimplements format_currency_mx by hand %>
  <p ...><%= ccy %> <%= number_with_precision(current, precision: 2, delimiter: ",") %></p>
  ```
  ```ruby
  # fundamentals_helper.rb:62-68 — bare "$" on market cap / revenue
  "$#{number_with_precision(v / 1e12, precision: 2)}T"
  ...
  number_to_currency(v)   # es-MX unit is "$" → "$1,234.00", currency unknown
  ```
  ```erb
  <%# _fixed_income_detail.html.erb:50 — the currency is a string literal %>
  <p class="<%= figure_class %>">MXN <%= number_with_precision(asset.face_value || 0, ...) %></p>
  ```
- **Why it matters:** D10 exists precisely to kill the bare-`$` ambiguity across a mixed MXN+USD portfolio, and `fundamentals_helper` reintroduces it on the one screen where a BMV issuer's market cap is denominated in pesos and a NASDAQ issuer's in dollars — both render `$`. The hand-rolled sites produce the *same* string as `format_currency_mx` today, which is worse than differing: they will silently drift the day the canonical formatter changes (a thousands separator, a non-breaking space, a `precision` default). And `_patrimonio_strip.html.erb:13` renders the app's headline number with no symbol while `portfolios/_patrimonio_total.html.erb:11` renders the identical figure as `MXN 1,247,580` — D10 permits the header-declares-currency form, but two screens showing one number two ways is a reading burden the product exists to remove.
- **Recommendation:** make `format_currency_mx` the only path. Replace the `<%= ccy %> <%= number_with_precision(...) %>` idiom everywhere with it; give it a `bare: true` mode for D10's declared-currency lists so `money_cell` and the strip route through the same function. Delete `format_large_currency`'s `$` prefixes — pass the asset's currency in, or emit the ISO code. Then move the whole family out of `DashboardHelper` (money formatting is not dashboard-specific) into a `Money` view-formatter or a Trading presenter.

> **S4 Camila Ferreyra (localización MX):** El `$` desnudo en fundamentales es el error que más caro sale con un lector mexicano: `$` es peso *y* dólar, y la pantalla de fundamentales es justo donde conviven emisoras BMV y NASDAQ. `number_to_currency` con `es-MX` te devuelve `$` — no te salva, te delata.
>
> **C5 Renata Câmara (UX fintech):** El patrimonio es *el* número del producto. Que el Panorama lo escriba `1,247,580` y el Consolidado `MXN 1,247,580` obliga a re-leer para confirmar que es el mismo dinero. Una sola forma, en las dos pantallas.

---

### [VIEW-02] The theme and currency pickers exist twice, and `/profile` still has the bug `/settings` documents as fixed
- **Severity:** P1
- **Effort:** M
- **Where:** `app/views/settings/_appearance.html.erb:11-40` vs `app/views/profiles/_preferences_tab.html.erb:21-57`
- **Evidence:**
  ```erb
  <%# settings/_appearance.html.erb:1-4 — the file's own header comment %>
  <%# Two segmented pills that now commit alike (D58): theme applies from
      localStorage, currency PATCHes on select. Neither waits for a button —
      the currency form used to, and a choice you can make and forget to submit
      leaves you reading MXN while believing you switched. %>
  ```
  ```erb
  <%# profiles/_preferences_tab.html.erb:40,56 — still waits for a button %>
  <%= form_with url: update_currency_path, method: :patch, scope: :profile, ... do |f| %>
    ...
    <%= f.submit "Guardar", class: "... text-white ..." %>
  ```
- **Why it matters:** this is the strongest finding in the audit because the codebase already knows the answer. D58's fix landed in `/settings` and was never applied to `/profile`, which is reachable from `/settings` itself (`settings/show.html.erb:17-20` links straight into it). A reader who changes their preferred currency on `/profile` and navigates away without pressing *Guardar* gets exactly the failure the comment describes: reading MXN while believing they switched — on the setting that decides how every consolidated total in the app is denominated. Both partials also carry duplicated copy (`"Claro" / "Oscuro" / "Sistema"` hardcoded in both) and duplicated Stimulus wiring; `profiles/_preferences_tab.html.erb:25` even carries a meaningless `data-controller-target="option"` attribute.
- **Recommendation:** decide which screen owns preferences (D58's reasoning says `/settings`), then either delete the `/profile` Preferencias tab or make it render `settings/_appearance`. One partial, one persistence contract. If both must exist, they must be the same partial — a duplicated control is a duplicated bug by construction.

---

### [VIEW-03] Two percent conventions coexist for the same quantity
- **Severity:** P1
- **Effort:** S
- **Where:** `app/helpers/assets_helper.rb:26-29` (`signed_percent`, 12 call sites) vs `number_to_percentage(..., format: "%n%")` at `app/views/discover/show.html.erb:60`, `app/views/market/_market_context.html.erb:15,35,36`, `app/views/market/_range_52w.html.erb:9`, `app/views/components/_watch_row.html.erb:34`, `app/views/market/_vs_plan.html.erb:19`
- **Evidence:**
  ```ruby
  # assets_helper.rb:28 — always signed, typographic minus (U+2212)
  "#{value.negative? ? "−" : "+"}#{number_with_precision(value.abs, precision: 1)}%"
  ```
  ```erb
  <%# discover/show.html.erb:60 — never signed positive, ASCII hyphen for negative %>
  <%= number_to_percentage(wave.change_percent, precision: 1, format: "%n%") %>
  ```
- **Why it matters:** both render a **day change**. `components/_asset_price.html.erb:21` shows `+1.4% hoy` / `−3.2% hoy`; `discover/show.html.erb:60` and `market/_market_context.html.erb:15` show `1.4%` / `-3.2%` for the same kind of number. On a screen whose entire job is "did this go up", the presence or absence of a `+` is the reading, and the two minus glyphs (`−` U+2212 vs `-` U+002D) render at different widths in JetBrains Mono, so columns of figures do not align.
- **Recommendation:** `signed_percent` is the correct convention (explicit sign, typographic minus, mono-aligned) — route every day-change / return site through it. Keep `number_to_percentage` only where the value is a magnitude, not a change (`_range_52w`'s distance-to-band, `_watch_row`'s `falta` gap) and make that distinction explicit with a second named helper (`magnitude_percent`) so the choice is visible at the call site instead of accidental.

---

### [VIEW-04] Domain logic living in view helpers: currency inference, fiscal calendar, valuation thresholds, FX resolution
- **Severity:** P1
- **Effort:** L
- **Where:**
  - `app/helpers/earnings_helper.rb:39-41` — **infers currency from the exchange**
  - `app/helpers/earnings_helper.rb:13-17` — derives the fiscal quarter
  - `app/helpers/market_helper.rb:57-65` — resolves an FX rate and converts a price
  - `app/helpers/assets_helper.rb:16-24` — FX conversion with a `MissingFxRate` rescue
  - `app/helpers/assets_helper.rb:59-65` — computes return-since-watch
  - `app/helpers/fundamentals_helper.rb:8-16` — metric interpretation thresholds
  - `app/helpers/market_helper.rb:107-152` — the observation phrase / tag / accent catalogue
- **Evidence:**
  ```ruby
  # earnings_helper.rb:39-41 — a money rule in the presentation layer
  def earnings_currency(event)
    event.asset.currency.presence || (event.asset.exchange == "BMV" ? "MXN" : "USD")
  end
  ```
  ```ruby
  # assets_helper.rb:59-65 — a return calculation in a helper
  def followed_since_percent(item)
    entry = item.entry_price
    current = item.asset.current_price
    return nil if entry.blank? || entry.zero? || current.blank?
    (current - entry) / entry * 100
  end
  ```
- **Why it matters:** `earnings_currency` is the sharpest one. In a product whose stated first hard rule is *"multi-currency MXN/USD is first-class, not an international feature"*, the fallback that decides whether an EPS figure is pesos or dollars lives in a view helper, is untestable from the domain, and hardcodes a two-venue world (a NYSE-listed Mexican issuer, or any third venue, silently becomes USD). `followed_since_percent` is a return calculation — the same kind of number `GainLoss` and `PeriodReturnsCalculator` own — computed in the presentation layer where no spec that guards returns will ever see it. `market_helper.rb:107-152` is 45 lines of es-MX domain vocabulary in a helper while ADR-014 put the equivalent state phrases in a domain catalogue and `config/i18n-tasks.yml` explicitly reserves `market.estado.*` for it — the observation phrases should have followed the same path and did not.
- **Recommendation:** split each helper by the test in the ADR-002 spirit — *does this decide what a number means, or only how it is drawn?* Meaning goes to `app/contexts/*/domain/` (an `EarningsPresenter` owning currency and fiscal period; `followed_since_percent` onto `WatchlistItem` or a Trading domain object; the metric thresholds beside `MetricDefinitions`, which already lives in `MarketData::Domain`). Drawing stays. Concretely per helper:

  | Helper | Lines | Verdict |
  |---|---|---|
  | `market_helper.rb` | 252 | **Mixed, worst offender.** `vix_tier`, `observation_dot_class`, `signal_value`, `asset_detail_tabs` are view-formatting. `approximate_in_preferred`, `asset_data_source_caption`, `tracked_price_source`, the three `OBSERVATION_*` catalogues, and the three date formatters are domain/data. Split ~60/40. |
  | `alerts_helper.rb` | 164 | **Mostly domain.** `CONDITION_LABELS`, `alert_condition_summary`, `CONDITION_FAMILIES`, `alert_rule_kind_label`, `alert_cooldown_label` are the alert vocabulary and belong in `Alerts::Domain` next to `TriggerNotice` (which already exists and already writes this voice). Only `CONDITION_ACCENTS` and `alert_event_accent` are view. |
  | `fundamentals_helper.rb` | 118 | **Mixed.** `METRIC_CHIPS` (thresholds = meaning) and `SUMMARY_METRICS` / `remaining_metrics_by_category` (which metrics matter) are domain; `CHIP_TONES` and `format_metric_value` are view. |
  | `notifications_helper.rb` | 115 | **Mostly view**, and correctly so — except `navbar_notifications` / `navbar_unread_count` (see VIEW-05) and the date formatters (VIEW-09). |
  | `admin/integrations_helper.rb` | 117 | **Genuinely view-formatting.** `PROVIDER_WEBSITES`, `CAPABILITY_LABELS`, `STATE_STYLES` are presentation of state the domain already computed. Leave it. Only `integration_last_check_label:103-113` should go (VIEW-09). |
  | `admin/logs_helper.rb` | 100 | **Genuinely view-formatting.** Filter option lists and severity→class maps. Leave it, minus `admin_log_timestamp:49-54` (VIEW-09). |
  | `earnings_helper.rb` | 68 | **Mostly domain** despite its size — currency inference, fiscal quarter, status derivation. Only the class maps are view, and those are drifted (VIEW-06). |
  | `statements_helper.rb` | 82 | **Copy catalogue, not logic.** ~60 es-MX line-item labels that ADR-011 says belong in `es-MX.yml`. |

---

### [VIEW-05] ActiveRecord queries issued from views and view helpers
- **Severity:** P1
- **Effort:** M
- **Where:**
  - `app/views/market/_statements_tab.html.erb:3` and `:29-30` — 1 `exists?` + 3 `where/order/limit`, inside a loop
  - `app/views/market/_asset_header.html.erb:28` — `asset.watchlist_items.find_by(user: current_user)`
  - `app/helpers/alerts_helper.rb:142-149` — `Asset.find_by(symbol:)`, once per distinct rule symbol
  - `app/helpers/market_helper.rb:60-61` — `FxRateHistory.rate_on` + `FxRate.find_by`, unmemoized
  - `app/helpers/market_helper.rb:208` — `MarketData::Queries::PriceSeries.for(asset).latest(1).first`
  - `app/helpers/notifications_helper.rb:8,13` — two queries on every authenticated page render
- **Evidence:**
  ```erb
  <%# _statements_tab.html.erb:29-30 — a query per panel, in the template %>
  <% stmts = @asset.financial_statements.where(statement_type: type, period_type: :annual)
                   .order(fiscal_date_ending: :desc).limit(5) %>
  ```
  ```ruby
  # alerts_helper.rb:148 — the presentation layer reaching into another context's AR model
  @alert_rule_assets[symbol] = Asset.find_by(symbol: symbol)
  ```
- **Why it matters:** four queries fire from `_statements_tab` on every asset-detail statements tab, and they are invisible to the controller and to any `includes` a future fix might add. `_asset_header.html.erb:28` re-queries for a record the controller already proved exists (it passed `is_watchlisted`) purely to recover its id. `alerts_helper.rb:148` is also a boundary violation in spirit: a view helper reaching directly into `Asset` is the pattern ADR-002 forbids for Trading→MarketData, done from a layer that has no ADR covering it at all. `market_helper.rb:60-61` is unmemoized and sits in `components/_asset_price`, which the comment at that file's head says is re-rendered by `MarketData::Handlers::BroadcastPriceUpdate` on every price move — so every broadcast re-resolves FX from the database.
- **Recommendation:** move all six into the use case that assembles the page. `_statements_tab` should receive a `{income_statement: [...], balance_sheet: [...], cash_flow: [...]}` hash from `MarketData`; `_asset_header` should receive the `watchlist_item_id` alongside `is_watchlisted`; `alert_rule_kind_label` should receive a pre-resolved kind from the Alerts use case; `_asset_price` should receive `approximate` and `source_caption` as locals, which also makes the broadcast path allocation-free. `navbar_notifications` is defensible as-is (the comment explains the lazy-load reasoning honestly) but should at minimum become one query — `recent.limit(6)` plus a separate `unread.count` on the same association is two round-trips for one bell.

---

### [VIEW-06] 144 raw palette classes and hex literals bypass the ADR-012 token contract — and the price chart's red is not the app's red
- **Severity:** P1
- **Effort:** M
- **Where:** 144 occurrences across 15 files. Worst: `app/helpers/market_helper.rb` (23), `app/javascript/controllers/ticker_search_controller.js` (16), `app/helpers/earnings_helper.rb` (14), `app/views/shared/_flash_message.html.erb` (12), `app/views/market/_analyst_target.html.erb` (10), `app/views/market/_pe_chart.html.erb` (6), `app/helpers/alerts_helper.rb` (6). Raw hex: `app/helpers/price_chart_helper.rb:36-37`; `app/views/market/_pe_chart.html.erb:39,41,43,62,66,68,76,84`; `app/views/market/_price_chart.html.erb:27,28,29,44`.
- **Evidence:**
  ```ruby
  # price_chart_helper.rb:36-37 — the down-state red
  line_color = trend_up ? "#10b981" : "#ef4444"
  fill_color = trend_up ? "#10b981" : "#ef4444"
  ```
  `--color-positive` is `#10B981` ✓. `--color-negative` is **`#F43F5E`** — `#ef4444` is not it, and neither is `_pe_chart`'s `#22c55e` (`--color-positive` is `#10B981`).
  ```erb
  <%# shared/_flash_message.html.erb:1 — raw palette, while its sibling uses tokens %>
  <% css_class = type.to_s == "notice" ? "bg-green-50 border-green-200 text-green-800 dark:bg-green-900/20 ..." : "..." %>
  ```
  ```erb
  <%# shared/_flash_alert.html.erb:6 — the same concept, done right %>
  <p class="... border-negative bg-negative-bg ... text-negative-fg" role="alert">
  ```
- **Why it matters:** ADR-012 is unambiguous — *"a raw hex in a template is a bug; a token the palette lacks is a gap to log, not a value to inline"* — and the whole point of the decision was that a second theme becomes a data change. Every one of these 144 sites is a place a second palette would silently not reach. Beyond the ADR, there is a visible defect today: a falling price draws in `#ef4444` while every other negative in the app draws in `#F43F5E`, and neither `_price_chart`'s `#e2e8f0` grid lines nor its `stroke="white"` data points respond to dark mode at all — on a dark canvas the grid is near-white. `_flash_message` vs `_flash_alert` is the same inconsistency in miniature: two flash treatments in one product, one tokenized and one not.
- **Recommendation:** fix the two hex-in-chart files first — they are visible defects, not just debt (`price_chart_helper.rb`, `_pe_chart.html.erb`, `_price_chart.html.erb`), reading the tokens via `var(--color-positive)` / `var(--color-negative)` / `var(--color-border-default)` the way `PortfoliosHelper::CHART_COLORS:104` and `MarketHelper#price_series_json:72` already do. Then `_flash_message.html.erb:1` → the tokens its sibling already uses. Then sweep the helper class-maps (`market_helper.rb:6-24,168-174`, `earnings_helper.rb:31-50`, `alerts_helper.rb:20-30`, `notifications_helper.rb:40-46`) — note `notifications_helper` uses tokens correctly at `:29-34` and raw palette at `:40-46`, in the same file. A CI grep for `-(emerald|rose|amber|slate|green|red)-[0-9]` under `app/views` and `app/helpers` would hold the line afterwards.

> **C4 Marisol Aguirre (Hotwire + Tailwind 4):** El contrato de ADR-012 no falla por descuido de un dev, falla porque nada lo checa. Los 144 hits son el costo de no tener el grep en CI el día que se escribió el ADR. Y ojo con el orden: `bg-emerald-500` y `bg-positive` conviven hoy sin conflicto visual solo porque los valores casi coinciden — el día que muevas `--color-positive` te enteras de los 144 de golpe.

---

### [VIEW-07] Stale "beta" copy in user-facing surfaces, after ADR-0010 killed the beta
- **Severity:** P1
- **Effort:** S
- **Where:** `app/views/bug_reports/new.html.erb:24`; `app/views/profiles/_preferences_tab.html.erb:60,64`; `app/views/bug_report_mailer/notify.html.erb:1`; `app/views/bug_report_mailer/notify.text.erb:1`
- **Evidence:**
  ```erb
  <%# bug_reports/new.html.erb:24 %>
  <p ...>Cuéntanos qué pasó. Esto llega directo al correo de soporte de la beta.</p>
  ```
  ```erb
  <%# bug_report_mailer/notify.html.erb:1 %>
  <p>Nuevo reporte de bug en Stockerly beta cerrada.</p>
  ```
  ```erb
  <%# profiles/_preferences_tab.html.erb:64 %>
  <p class="text-xs text-fg-subtle">No editable durante la beta.</p>
  ```
- **Why it matters:** ADR-0010 dropped the closed-beta audience on 2026-08-20; there is no beta and no support address for one. On a self-hosted instance run by a third party — the explicit packaging target — the bug-report screen promises to reach "el correo de soporte de la beta", and the mailer announces a report in "Stockerly beta cerrada", both pointing at Adrian's inbox from someone else's box. `"No editable durante la beta"` explains a disabled timezone field with a reason that no longer exists, so the field now reads as broken rather than deferred.
- **Recommendation:** rewrite the three surfaces for the self-hosted single-user framing. The bug report screen should say where the report actually goes on *this* instance (or link to the GitHub issue tracker per ADR-022, which is the honest destination); the timezone note should state the real reason it is fixed. These strings are also un-migrated, so the rewrite is the natural moment to move them into `es-MX.yml` (VIEW-10).

> **C5 Renata Câmara:** No es solo copy viejo — es una promesa que el producto ya no puede cumplir. Un tercero que instala Stockerly y reporta un bug cree que le va a contestar un equipo de soporte. Decir *"esto abre un issue en GitHub"* es más corto, más honesto y no envejece.

---

### [VIEW-08] Financial math and 40 lines of SVG geometry inline in ERB
- **Severity:** P1
- **Effort:** M
- **Where:** `app/views/market/_pe_chart.html.erb:12-56` (45 lines of computation); `app/views/market/_statement_table.html.erb:47`; `app/views/market/_earnings_tab.html.erb:5,11,16,19`; `app/views/market/_fixed_income_detail.html.erb:3-15`; `app/views/components/_sparkline.html.erb:22`
- **Evidence:**
  ```erb
  <%# _statement_table.html.erb:47 — a profit margin computed in the template %>
  <% margin = (raw_value.to_f / stmt.data["totalRevenue"].to_f * 100).round(1) %>
  <div class="text-xs text-fg-subtle"><%= margin %>%</div>
  ```
  ```erb
  <%# _pe_chart.html.erb:37-44 — a valuation judgement, in the view %>
  last_pe = pe_values.last
  line_color = if last_pe < 15 then "#22c55e" elsif last_pe <= 25 then "#f59e0b" else "#ef4444" end
  ```
- **Why it matters:** `_pe_chart` is the clearest case. It is 106 lines of which ~45 are chart geometry and threshold classification, and the classification contradicts a decision the codebase already took: `fundamentals_helper.rb:1-7` (D36) says *"P/E 'caro vs su historia' is deliberately absent — it needs the asset's own P/E history, which this partial is not given"* — and `_pe_chart`, which **is** given that history, instead paints absolute P/E bands green/amber/red, a market-wide rule that is meaningless across sectors and reads prescriptively against ADR-0001. Meanwhile `_statement_table.html.erb:47` computes gross/operating/net margin — three of the metrics `FundamentalCalculator` owns — in a template, and renders the result as a bare `<%= margin %>%`, bypassing `format_metric_value`'s `:percentage` path and therefore the only place margin formatting is tested. `price_chart_helper.rb` proves the pattern is already understood here: the price chart's identical geometry lives in a helper and returns a hash.
- **Recommendation:** do for `_pe_chart` what `price_chart_helper` already does for `_price_chart` — a `pe_chart_data(history)` that returns points, bands, ticks and a token name; the template renders only. Move the margin computation into the statements presenter beside `line_items_for`, and route the output through `format_metric_value`. Then take D36's own reasoning seriously and decide whether the P/E bands should exist at all — if they should, the thresholds belong next to `METRIC_CHIPS` where the "only where the threshold is part of the metric's own definition" rule can be applied to them.

---

## P2

### [VIEW-09] Six competing date and relative-time formatters, none using the es-MX catalogue that already exists
- **Severity:** P2
- **Effort:** M
- **Where:**
  - `app/helpers/market_helper.rb:90-101` (`observation_when`), `:176-202` (`short_date_es`, `short_month_year_es`, `short_date_upper_es`, `ASSET_MONTHS_ES_LOWER`)
  - `app/helpers/notifications_helper.rb:82-102` (`format_date_header`, `format_notification_time`)
  - `app/helpers/alerts_helper.rb:83-95` (`alert_event_when`)
  - `app/helpers/earnings_helper.rb:2-11` (`WEEKDAY_LABELS`, `earnings_date_header`)
  - `app/helpers/admin/logs_helper.rb:49-54` (`admin_log_timestamp`)
  - `app/helpers/admin/integrations_helper.rb:103-113` (`integration_last_check_label`)
  - `app/helpers/application_helper.rb:28-39` (`duration_in_words_es`)
  - `app/helpers/datetime_es_helper.rb:6-7` (`MONTHS_ES`, `WEEKDAYS_ES`)
- **Evidence:** `config/locales/es-MX.yml:385-433` already ships the complete es-MX `date:` block (`abbr_month_names`, `day_names`, `formats.short/long/default/calendar`) and `:435-473` the full `datetime.distance_in_words` tree. `config/i18n-tasks.yml` even reserves them under `ignore_unused` so the scanner will not flag them. Yet:
  ```ruby
  # market_helper.rb:176 — a duplicate of date.abbr_month_names
  ASSET_MONTHS_ES_LOWER = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze
  # datetime_es_helper.rb:6 — the same list again, uppercased
  MONTHS_ES = %w[ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC].freeze
  # application_helper.rb:30-38 — a duplicate of datetime.distance_in_words.x_hours / x_minutes
  hours == 1 ? "1 hora" : "#{hours} horas"
  ```
  And three of them produce **different strings for the same instant**: an event from two days ago reads `hace 2 días` (`market_helper:99`), `14 MAY · 09:22 CDMX` (`alerts_helper:93`), and `14 MAY 2026 · 09:22 CDMX` (`notifications_helper:100`).
- **Why it matters:** the locale file is already correct and already gated by `i18n-tasks health` in CI; the helpers are eight hand-maintained copies of it that no check covers. `l(date, format: :short)` is already used correctly in four places (`trades/_trade_row.html.erb:10`, `discover/show.html.erb:39`) — so the codebase both knows the right answer and does not use it in most places.
- **Recommendation:** delete `ASSET_MONTHS_ES_LOWER`, `MONTHS_ES`, `WEEKDAYS_ES`, `WEEKDAY_LABELS` and `duration_in_words_es`; add the two or three `date.formats.*` the app actually needs (an uppercase eyebrow format, a compact month-year) to `es-MX.yml` and use `l()`. Collapse the five relative-time functions into one `relative_time_es(time, with_clock: false)` built on `time_ago_in_words` (which already resolves through the es-MX `datetime` tree). Net: roughly −70 lines of helper and one testable formatter.

> **S4 Camila Ferreyra:** Tienes el catálogo `date`/`datetime` completo en `es-MX.yml`, con `i18n-tasks` cuidándolo — y ocho helpers reimplementándolo a mano. `strftime("%b")` sale en inglés, por eso nacieron; la respuesta era `l()`, no una constante nueva. Que el mismo instante se lea de tres formas distintas en tres pantallas es el síntoma, no el problema.

---

### [VIEW-10] I18n inventory — adoption is real but the pattern is inconsistent, and six surfaces are untouched
- **Severity:** P2
- **Effort:** M (mechanical, per surface)
- **Where:** whole-tree, table below.
- **Evidence:** `bundle exec i18n-tasks health` → **green**: 959 keys, *"No translations are missing" / "Every translation is in use" / "All data is normalized"*. So there are **no dead keys and no missing keys** — the catalogue is healthy. The problems are the *shape* of the adoption:

  **1. Absolute keys where ADR-011 §4 mandates lazy lookups.** Five directories use only absolute keys, so a key's home is not its template:
  ```erb
  <%# assets/index.html.erb:16 — absolute, from within assets/index %>
  <%= t("assets.index.invertido", amount: ...) %>
  ```
  **2. Key names are Spanish**, while `CLAUDE.md` and `feedback-repo-language` put every code artifact in English: `t("trades.new.comision")`, `t("auth.contrasena")`, `t("assets.index.titulos")`, `t("positions.index.movimiento_linea")`.
  **3. Six surfaces are fully hardcoded**, including `profiles/` — a redesigned-looking screen with a tab shell, four panels and ~20 strings, and zero keys.

  | Surface | Files | Lazy `t(".x")` | Absolute `t("a.b")` | Hardcoded es-MX | Status |
  |---|---:|---:|---:|---:|---|
  | `onboarding/` | 5 | 36 | 0 | 0 | ✅ migrated, lazy |
  | `trade_imports/` | 2 | 36 | 0 | 0 | ✅ migrated, lazy |
  | `discover/` | 1 | 18 | 0 | 1 | ✅ migrated, lazy |
  | `totp_enrollments/` | 2 | 12 | 0 | 0 | ✅ migrated, lazy |
  | `welcome/`, `help/` | 2 | 7 | 0 | 0 | ✅ migrated, lazy |
  | `market/` | 28 | 91 | 36 | 14 | 🟡 mostly migrated |
  | `admin/` | 13 | 59 | 21 | 1 | 🟡 mostly migrated |
  | `settings/` | 5 | 31 | 12 | 0 | 🟡 mostly migrated (`_appearance:13` hardcoded) |
  | `alerts/` | 5 | 25 | 13 | 0 | 🟡 mostly migrated |
  | `portfolios/`, `positions/` | 4 | 34 | 10 | 0 | 🟡 mostly migrated |
  | `dashboard/` | 4 | 9 | 8 | 1 | 🟡 mostly migrated |
  | `notifications/`, `two_factor/`, `shared/`, `pwa/` | 20 | 35 | 9 | 0 | 🟡 partial |
  | `assets/` | 4 | 0 | 55 | 0 | 🟠 migrated, **absolute only** |
  | `trades/` | 4 | 0 | 34 | 0 | 🟠 migrated, **absolute only** |
  | `password_resets/` | 5 | 0 | 23 | 8 | 🟠 migrated, absolute only + residue |
  | `setup/`, `sessions/` | 2 | 0 | 25 | 1 | 🟠 migrated, **absolute only** |
  | `components/` | 16 | 0 | 14 | 1 | 🟠 absolute only (defensible — shared partials) |
  | `layouts/` | 7 | 0 | 3 | 1 | 🟠 absolute only (defensible) |
  | `profiles/` | 6 | 0 | 0 | 20 | 🔴 **not migrated** |
  | `bug_reports/` | 1 | 0 | 0 | 7 | 🔴 not migrated |
  | `legal/` | 3 | 0 | 0 | 142 | 🔴 not migrated (long-form legal prose) |
  | `alert_mailer/`, `bug_report_mailer/`, `user_mailer/` | 4 | 0 | 0 | 7 | 🔴 not migrated (ADR-011 §1 names mailers) |
  | `watchlist_items/` | 1 | 0 | 0 | 0 | — no copy |
  | **Plus:** `app/helpers/statements_helper.rb` | — | — | — | ~60 labels | 🔴 copy catalogue in a helper |

  **No English is leaking into user-facing copy** — I checked and found none. That part is clean.
- **Why it matters:** the hardcoded surfaces are ADR-011-sanctioned (*"until a surface is rewritten, its hardcoded es-MX strings stay put and are not a defect"*), so this is inventory, not blame. But the *absolute-key* directories are a different case: those surfaces **were** migrated, and migrated against the ADR's own rule 4, so the indirection cost was paid without the "the template path is the key path" mitigation the ADR relies on. `statements_helper.rb` is the one I would flag hardest — 60 strings of user-facing es-MX in a Ruby constant, which `i18n-tasks` cannot see and the voice review ADR-011 promised cannot reach.
- **Recommendation:** treat the 🟠 rows as a small follow-up (rename to lazy keys with `i18n-tasks normalize` guarding the move; ~150 keys, mechanical). Decide once on key language — I would rename to English keys, since `feedback-repo-language` is explicit that code artifacts are English and keys are code, and doing it while the catalogue is green and 959 keys is cheaper than later. Leave `legal/` alone (long-form prose, low churn, real cost to key). Move `statements_helper`'s labels into `es-MX.yml` when the statements screen next gets touched. `profiles/` is the largest un-migrated *app* surface and should get its keys with whatever change fixes VIEW-02.

---

### [VIEW-11] Eight dead Stimulus controllers, eagerly loaded on every page
- **Severity:** P2
- **Effort:** S
- **Where:** `app/javascript/controllers/` — `calendar_nav_controller.js` (36), `clipboard_controller.js` (14), `onboarding_form_controller.js` (57), `onboarding_select_controller.js` (42), `password_visibility_controller.js` (12), `price_flash_controller.js` (49), `row_link_controller.js` (17), `trend_breakdown_controller.js` (18) — **245 lines**
- **Evidence:** zero `data-controller="…"` references across all 149 templates for any of the eight, and zero references in `spec/`. `app/javascript/controllers/index.js:3` uses `eagerLoadControllersFrom("controllers", application)`, so every one is fetched, parsed and registered on every page load.
- **Why it matters:** 8 of 27 controllers (30%) are dead. `price_flash_controller.js` is the notable one — 49 lines of price-change flash animation for a product whose Turbo Stream price broadcasts are live (`MarketData::Handlers::BroadcastPriceUpdate` replaces `components/_asset_price`), so this is very likely a feature that was built, wired, and lost its `data-controller` in the 2.0 rewrite rather than one that was never used. Worth confirming before deleting.
- **Recommendation:** confirm `price_flash` and `trend_breakdown` against the redesign punch list (`design/V2_REMAINING.md`) — if the 2.0 screens are meant to have them, this is a wiring bug, not dead code. Delete the other six. `onboarding_form` / `onboarding_select` are the safest deletions: `onboarding/` is fully migrated and fully redesigned, so if it does not reference them now, it will not.

---

### [VIEW-12] Duplicated markup that wants shared partials
- **Severity:** P2
- **Effort:** S
- **Where:**
  - **FX-unavailable warning, byte-identical ×3:** `app/views/portfolios/_patrimonio_total.html.erb:21-27`, `app/views/dashboard/_patrimonio_strip.html.erb:25-31`, `app/views/assets/index.html.erb:23-29`
  - **3-band gauge track + dot, ×2:** `app/views/portfolios/_comparison_card.html.erb:17-25` vs `app/views/dashboard/_sentiment_card.html.erb:18-26`
  - **`movimiento_linea` interpolation, ×2:** `app/views/trades/_trade_row.html.erb:9-13` vs `app/views/trades/_confirm_delete_row.html.erb:10-14`
  - **Share-precision rule, ×5:** `trades/_trade_row.html.erb:12`, `trades/_confirm_delete_row.html.erb:13`, `components/_asset_row.html.erb:24`, `market/_position_trades.html.erb:27`, `market/_position_summary.html.erb:54`
  - **Primary/secondary slot swap, ×2:** `components/_asset_row.html.erb:13-16` vs `components/_watch_row.html.erb:11-14`
- **Evidence:**
  ```erb
  <%# _comparison_card.html.erb:18-22 and _sentiment_card.html.erb:19-23 — identical %>
  <div class="flex gap-1">
    <span class="h-1.5 flex-1 rounded-full bg-negative"></span>
    <span class="h-1.5 flex-1 rounded-full bg-warning"></span>
    <span class="h-1.5 flex-1 rounded-full bg-positive"></span>
  </div>
  ```
  ```erb
  <%# The share-precision rule, written out five times %>
  precision: position.shares.to_d.frac.zero? ? 0 : 4
  ```
- **Why it matters:** the share-precision one is the real defect, not the repetition: **three of the five sites omit `delimiter: ","`**. So a fractional-share position renders `1,234.5678` in `components/_asset_row.html.erb:24` and `1234.5678` in `market/_position_trades.html.erb:27` — the same quantity, two formats, on two screens describing the same holding. The rule itself ("show 4 decimals only when the position is fractional") is a display convention about a financial quantity and belongs in one function.
- **Recommendation:** `shares_cell(shares)` in `AssetsHelper` next to `money_cell`, applied at all five sites — that fixes the delimiter inconsistency as a side effect. `shared/_fx_unavailable.html.erb` for the warning. `components/_track_gauge.html.erb` taking `offset:` for the gauge. The slot-swap logic in `_asset_row`/`_watch_row` is presenter work, not a partial — both rows are assembling a `{text:, color:}` view model in ERB, which is what a row presenter is for.

---

### [VIEW-13] Ten design tokens are defined, forced into the bundle, and referenced by nothing
- **Severity:** P2
- **Effort:** S
- **Where:** `app/assets/tailwind/application.css:75-79` (light) and `:135-139` (dark) — `--color-sentiment-1` … `--color-sentiment-5`; plus `--color-chart-neutral` at `:73` and `:133`
- **Evidence:** zero references to `sentiment-[1-5]` or `chart-neutral` across `app/views`, `app/helpers`, `app/javascript`. Only `--color-chart-1..8` are consumed, via `PortfoliosHelper::CHART_COLORS:104` and `MarketHelper#price_series_json:72`. The block's own comment says it was made `@theme static` *specifically* to defeat tree-shaking:
  ```css
  /* A plain `@theme` tree-shakes what no utility references, which left
     chart-2..8 undefined in light mode and the allocation donut drawing an
     empty ring. */
  ```
- **Why it matters:** minor in bytes, but the comment documents that `@theme static` was adopted to keep genuinely-used tokens alive — and it is now also keeping ten unused ones alive, invisibly. More usefully: the *Fear & Greed sentiment scale* has a purpose-built 5-band token set, and `dashboard/_sentiment_card.html.erb:19-23` paints the fear/greed gauge with a **3-band** `negative/warning/positive` track instead. Either the design intended five bands and the implementation shipped three, or the tokens were speculative. Worth resolving with the design side rather than deleting blind.
- **Recommendation:** check `design/ui-kit.lib.pen` / `DECISIONS.md` for the sentiment scale; if the 5-band reading is the intent, `_sentiment_card` is under-built and the tokens are correct. If not, delete all ten and `--color-chart-neutral`.

---

### [VIEW-14] Typography drift: 106 arbitrary `text-[Npx]` values, 9 of them restating the scale
- **Severity:** P2
- **Effort:** S
- **Where:** whole-tree. Distribution: `text-[11px]` ×60, `text-[10px]` ×21, `text-[10.5px]` ×12, `text-[16px]` ×3, `text-[15px]` ×3, `text-[18px]` ×2, `text-[12px]` ×2, `text-[22px]` ×1, `text-[14px]` ×1, `text-[13px]` ×1.
- **Evidence:** `app/views/market/_disclaimer.html.erb:11,12` use `text-[12px]` — which is exactly `text-xs`. `app/views/profiles/_preferences_tab.html.erb:67` uses `text-[14px]` = `text-sm`; `:102` and `app/views/profiles/_data_session_tab.html.erb:36` use `text-[16px]` = `text-base`.
- **Why it matters:** the nine that restate an existing step (`12/14/16/18px`) are pure waste — same output, no token. The forty-two sub-`text-xs` values are the more interesting half: `10px`, `10.5px` and `11px` are three near-identical caption sizes used interchangeably (`market_helper`'s eyebrows are `10.5`, `_fixed_income_detail`'s labels are `10.5`, `_asset_row`'s subtitles are `11`, the tier chips are `10`), which is a caption scale the token contract does not define. ADR-012 makes the token *names* the contract; there is no name for "the size below `xs`", so every author invents one.
- **Recommendation:** replace the nine scale-restating values with their utilities. Then define the caption steps as real tokens (`--text-caption: 11px`, `--text-micro: 10px` or whatever the design system calls them — `design/ui-kit.lib.pen` should be the source) and collapse the three sizes to two. This is exactly the "a token the palette lacks is a gap to log" case ADR-012 anticipates.

---

### [VIEW-15] Class-list contradictions and stale-class toggling in Stimulus
- **Severity:** P2
- **Effort:** S
- **Where:** `app/views/alerts/new.html.erb:74`; `app/javascript/controllers/selectable_card_controller.js:19,22`
- **Evidence:**
  ```erb
  <%# alerts/new.html.erb:74 — both set `display` %>
  <div role="tablist" class="hidden flex gap-1 rounded-xl bg-bg-muted p-1"
       data-alert-form-target="panel direction" ...>
  ```
  ```js
  // selectable_card_controller.js:19-22 — swaps in raw palette classes the server never rendered
  card.classList.add("border-slate-200", "dark:border-slate-800")
  ```
- **Why it matters:** `hidden flex` works today only because Tailwind emits `.hidden` after `.flex` in the display group — `alert_form_controller.js:73` (`panel.classList.toggle("hidden", !matches)`) relies on that ordering surviving a Tailwind upgrade. `selectable_card` is the same bug `toggle_controller.js:22-24` already carries a comment about having fixed: *"bg-bg-muted is what the server renders for the off state. Toggling a different off-class (bg-slate-200) left both on the element, so a switch turned off by hand did not match one rendered off."* The fix was applied to `toggle` and not to `selectable-card`, which still adds `border-slate-200` on top of whatever `onboarding/assets.html.erb` rendered.
- **Recommendation:** drop `flex` from `alerts/new.html.erb:74` and let the controller add it, or use a `data-*` attribute plus a `data-[…]:flex` variant (the pattern `_appearance.html.erb:16` already uses for the theme pills — that one is done right). Make `selectable_card` toggle the same token classes the server renders, matching `toggle_controller`.

---

### [VIEW-16] Accessibility: two unlabeled filter inputs, one wrong ARIA role
- **Severity:** P2
- **Effort:** S
- **Where:** `app/views/admin/logs/_filters.html.erb:10`; `app/views/admin/errors/_filters.html.erb:8`; `app/views/alerts/new.html.erb:74`
- **Evidence:** both admin search fields carry only a `placeholder:` and no `<label>` or `aria-label`. `alerts/new.html.erb:74` sets `role="tablist"` on a container whose children are `<input type="radio">` in `<label>` wrappers — a radio group, not a tab list.
- **Why it matters:** small and cheap. Worth noting that the rest of the layer is genuinely good here: `assets/tracked.html.erb:20` uses an `sr-only` label, `assets/_track_form.html.erb:15` a visible one, every icon carries `aria-hidden="true"`, every icon-only button an `aria-label` (`market/_asset_header.html.erb:29,36`, `trades/_trade_row.html.erb:25,30`), and there are no clickable `<div>`s. The one inline handler is `layouts/legal.html.erb:20` (`onclick="window.print()"`) on a real `<button>`, which is fine.
- **Recommendation:** add `sr-only` labels to the two admin inputs; drop `role="tablist"` (the `<label>`-wrapped radios are already correct without it, and the bogus role actively misleads a screen reader).

---

### [VIEW-17] The `en` fallback is a Rails scaffold stub that can only mask missing keys in production
- **Severity:** P2
- **Effort:** S
- **Where:** `config/application.rb:56-58`; `config/environments/production.rb:89`; `config/locales/en.yml:31-32`; `config/i18n-tasks.yml:2-3`
- **Evidence:**
  ```ruby
  # application.rb:56-58
  config.i18n.default_locale     = :"es-MX"
  config.i18n.available_locales  = [ :"es-MX", :en ]
  config.i18n.fallbacks          = [ :en ]
  ```
  ```yaml
  # en.yml — untouched Rails scaffold, one key
  en:
    hello: "Hello world"
  ```
  `i18n-tasks.yml` declares `locales: [es-MX]`, so `health` will never inspect `en`. `raise_on_missing_translations` is true in dev and test, **absent in production**.
- **Why it matters:** ADR-011 is explicit that a second locale is not a goal (*"`en` gets added the day there is a reader for it"*), so the fallback chain buys nothing — `en.yml` has one key and it is `hello`. What it does buy is a behavioural difference between environments: a missing key raises in dev/test and, in production, falls through `en` to a rendered `translation missing` span. Given `health` is green today the exposure is theoretical, but it is the one gap `i18n-tasks` structurally cannot see.
- **Recommendation:** either drop `:en` from `available_locales`/`fallbacks` (matching ADR-011's stance and making prod fail the same way dev does), or keep it and delete the scaffold content from `en.yml` so nobody mistakes it for a real locale. The first is more honest.

---

## Overall assessment

Not a bad presentation layer. The 2.0 redesign landed real structure — `components/`, `shared/`, a token contract, a green `i18n-tasks health`, honest `<%# %>` comments that explain *why* a partial is shaped the way it is (those comments are genuinely above average and were load-bearing for this audit; several findings above are things the codebase told me about itself). Accessibility is better than typical. Controllers delegate to use cases and the views mostly consume what they are handed.

The failure mode is **convergence without enforcement**. Every problem here has a correct implementation *already in the repo*, next to an incorrect one:

- `format_currency_mx` exists — and 20 sites reimplement it (VIEW-01).
- D58's no-submit currency picker exists — and `/profile` still has the button (VIEW-02).
- `signed_percent` exists — and 7 sites use `number_to_percentage` (VIEW-03).
- `price_chart_helper` extracts chart geometry — and `_pe_chart` inlines it (VIEW-08).
- `_flash_alert` uses tokens — and `_flash_message` uses raw palette (VIEW-06).
- `toggle_controller` fixed the stale-class bug — and `selectable_card` still has it (VIEW-15).
- `es-MX.yml` carries the full `date`/`datetime` catalogue — and eight helpers reimplement it (VIEW-09).
- `notifications_helper` uses tokens at line 29 and raw palette at line 40 — in one file.

That pattern says the ADRs and decisions are right and nothing checks them. Three cheap CI greps would hold most of this line permanently: raw palette classes under `app/views|app/helpers`, raw hex in ERB, and `number_to_percentage` / `number_with_precision` outside the sanctioned formatters.

**Suggested order:** VIEW-02 (a live bug on the currency setting) → VIEW-06's two chart files (visible dark-mode defects) → VIEW-07 (stale beta copy, 5 strings) → VIEW-12's `shares_cell` (fixes a real delimiter inconsistency) → VIEW-01 + VIEW-03 (the formatter consolidation, with the greps that keep it) → the rest as the redesign touches each surface.

> **C4 Marisol Aguirre:** Lo que tienes no es deuda de diseño, es deuda de *enforcement*. La capa está bien pensada; lo que falta son tres greps en CI. Sin eso, cada slice del rediseño reintroduce la mitad de esto.
>
> **C5 Renata Câmara:** Lo más caro de esta lista no es ningún hallazgo suelto — es que el mismo número se lea distinto en dos pantallas. Un tracker patrimonial se gana la confianza siendo aburridamente consistente. VIEW-01, VIEW-03 y VIEW-12 son la misma historia contada tres veces.
>
> **S4 Camila Ferreyra:** El catálogo es-MX está sano y con `i18n-tasks` verde, cosa rara. Lo que sobra son ocho helpers reimplementando el bloque `date` que ya tienes, y el `$` desnudo en fundamentales. Ninguno es difícil; los dos son visibles para el lector mexicano.
