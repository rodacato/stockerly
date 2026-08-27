# Component inventory — the translation work order

> [CODE_CHANGES.md](CODE_CHANGES.md) §0.5. Crosses `ui-kit.lib.pen` against
> `app/views/components/`. Every count is a grep, not an impression — and every count carries the
> date it was taken, because this document's whole failure mode is a measurement outliving the
> thing it measured.

**As of 2026-08-27 the crossing is 18 kit components (0.7.0) against 15 partials, all of them
referenced.** The header of this document read *"the kit's 13 components (0.4.0)"* and *"17
partials"* until that date; both were counts from an earlier pass that nothing re-ran.

**Measurement log** — kept so a reader can see the drift rather than only the latest number:

| Date | Kit | `app/views/components/` | Note |
|---|---|---|---|
| 2026-08-24 | 13 (0.4.0) | 19 partials, 11 alive | Seven had zero references in `app/`, `lib/` or `spec/`; an eighth rendered only into a Turbo Stream target no page mounts. So the crossing was 11 against 13. |
| 2026-08-25 | 16 (0.5.0) | 17, all referenced | The eight dead ones gone — seven in the shell slice, `_asset_fundamentals` with that sweep. |
| **2026-08-27** | **18 (0.7.0)** | **15, all referenced** | Re-run: `ls app/views/components/*.html.erb` and, per partial, `grep -rc "components/<name>" app lib spec`. Lowest is 1 file, highest is `_empty_state` at 9. |

## A. The kit's 18 — where each one lives in code today

Re-measured 2026-08-27. The five rows at the bottom were **missing from this table entirely**: the
kit gained `SidebarNav`, `TopBarDesktop` and `AppShellDesktop` in 0.5.0 and `Logo` / `LogoMark` in
0.7.0, and this section was never extended to meet them — so it crossed 13 against a kit that had
18, and read as complete.

| Kit component | Today in code | Verdict | Measured 2026-08-27 |
|---|---|---|---|
| `TopBar` | `components/_top_bar` | ✅ **Shipped** (slice 1) | The old `shared/_app_navbar` is deleted |
| `Card` | inline everywhere | **Net-new, still inline** | `bg-bg-surface` on 121 template lines (99 when first counted) |
| `ButtonPrimary` | inline everywhere | **Net-new, still inline** | `bg-primary` on 62 template lines |
| `ButtonSecondary` | inline everywhere | **Net-new, still inline** | same sites, secondary variants |
| `Field` | raw form helpers | **Net-new, still inline** | 38 `*_field` / `select` calls, each with its own class string |
| `Segmented` | `components/_segmented` | ✅ **Shipped** | Rendered twice — `assets/index`, `portfolios/show`. This row said "Net-new" until 2026-08-27 |
| `AssetRow` | `components/_asset_row` | ✅ **Shipped** (slices 2, 3) | Panorama's Radar reuses it; gained the optional maturity line |
| `MovementItem` | `trades/_trade_row` | ◐ **Partly** | A partial exists and is shared (`trades/index`, `positions/_positions_table`), but it is still a table `<tr>`, not the kit's row. Whether that closes the gap is a design call |
| `MarketCard` | — | **Net-new, not built** | `components/_kpi_card` was the right shape and was deleted with the dead set (§B) |
| `NavRow` | `settings/_nav_row` | ✅ **Shipped**, flow-local | 6 renders, all in `settings/show`. Not promoted to `components/` — one consumer |
| `SwitchRow` | `settings/_notification_switches` | ✅ **Shipped**, flow-local | 2 renders: `settings/show` and `alerts/index`. Two consumers is the promotion bar |
| `BottomNav` | `components/_bottom_nav` | ✅ **Shipped** (slice 1) | Carries five destinations now, not four |
| `Stepper` | `onboarding/_step_header` | ✅ **Shipped**, flow-local | Step counter + percent + progress bar. Landed with slice 7 |
| `SidebarNav` *(0.5.0)* | `components/_sidebar_nav` | ✅ **Shipped** (slice 1) | Desktop nav, same five destinations |
| `TopBarDesktop` *(0.5.0)* | `components/_top_bar_desktop` | ✅ **Shipped** (slice 1) | Screen title as the `h1` + bell |
| `AppShellDesktop` *(0.5.0)* | `layouts/app.html.erb` | ✅ **Shipped** (slice 1) | Not a partial — the layout composes the four shell partials and CSS picks the variant |
| `Logo` *(0.7.0)* | `shared/_logo` | ✅ **Shipped** (§11) | `brand_logo(:light \| :dark)` owns the filenames |
| `LogoMark` *(0.7.0)* | `shared/_logo_mark` | ✅ **Shipped** (§11) | The symbol alone |

Two things followed from the original crossing and one of them held. First, `TopBar` was the only
genuine revamp — that is still true, and it is why the shell was slice 1. Second, the four
primitives (`Card`, `Field`, and the two buttons) were where the translation would pay for itself
or not: **it did not, and that is the finding this table now carries.** Every slice shipped without
them, and the inline counts went *up* (99 → 121 `bg-bg-surface` lines). Extracting them is now a
change with no slice behind it, which makes it a decision rather than leftover work.

## B. The 19 partials — what happens to each

_As of 2026-08-27. The heading keeps "19" because that is the set this section triages; **15 of
them survive**, and the Alive table below is the part that was re-measured._

### Dead: zero references in `app/`, `lib/` and `spec/` (7)

Not "used rarely" — never rendered, by anything. Each was built for a screen that changed
shape before it shipped.

| Partial | Lines | Note |
|---|---|---|
| `_kpi_card` | 67 | The shape `MarketCard` needs. Read it before writing the new one; do not resurrect it. |
| `_integration_card` | 53 | Matches the `ProviderCard` gap in the kit's 0.5.0 list. Same advice. |
| `_status_badge` | 24 | Nine states. The design uses chips with far fewer. |
| `_log_severity_badge` | 16 | The `Registros` screen will want something like it. |
| `_news_card` | 12 | Panorama has no news card in the design. |
| `_market_status_indicator` | 12 | Ditto. |
| `_feature_card` | 8 | Public landing furniture; outside the six redesigned flows. |

**✅ Deleted in the shell slice**, once the net-new partials had been written against them.

### Broken: renders into a target nothing mounts (1) — ✅ resolved by deleting

| Partial | What was wrong |
|---|---|
| ~~`_asset_fundamentals`~~ | `MarketData::Handlers::BroadcastFundamentalsUpdate` replaced `#asset_fundamentals_<id>`. That id existed **only inside this partial**, and no view rendered the partial — so the broadcast was a silent no-op. Its spec asserted the broadcast call was made, so it passed. Compare `_asset_price`, whose target really is mounted by two tables: same mechanism, wired. |

**Deleted 2026-08-25** — handler, partial, spec and the EventBus subscription. The choice this
section left open was mount-or-delete; the asset-detail slice shipped `Análisis` / `Mi posición`
without asking for the frame, so mounting it would have been building a component the design does
not draw. `AssetFundamentalsUpdated` keeps its logging handler. The stale
`rescue ActionView::MissingTemplate` went with it.

### Alive — 15, re-measured 2026-08-27

The whole directory, not a subset: `ls app/views/components/*.html.erb` returns exactly these
fifteen, and each one is rendered from at least one file (`grep -rc "components/<name>" app lib
spec`). Three rows this table used to carry — `_data_status`, `_index_card` and `_asset_price` —
**named partials that no longer exist**, and one of those absences is a live defect (below).

| Partial | Rendered from | Note |
|---|---|---|
| `_empty_state` | 9 files | Survives, restyled — the design gives the empty states real content (`activos-cartera-vacia`). |
| `_asset_badge` | 4 | Survives. Folds into `AssetRow` / `MovementItem` as their leading element. |
| `_notification_badge` | 4 | **Net-new since this table was written** — the bell's unread count. |
| `_sheet_dialog` | 4 | **Net-new.** The `+ Nueva` sheet D14 asked for; Reglas and the trade flow share it. |
| `_sparkline` | 3 | ✅ **Rewritten in slice 3** — a line, not bars, and `_asset_row` now passes real `heights` instead of drawing an invented shape. |
| `_asset_row` | 2 | The kit's `AssetRow`. |
| `_segmented` | 2 | **Net-new.** The kit's `Segmented`. |
| `_watch_row` | 2 | **Net-new** — the `WatchRow` the 0.4.0 gap list kept flow-local in design. |
| `_donut_chart` | 1 (2 renders) | Survives → Consolidado (slice 4). Kit gap: it needs a categorical ramp, still open. |
| `_skeleton` | 1 | Survives as-is. No kit equivalent and none needed. |
| `_back_to_top` | 1 | Survives. Used by `layouts/legal`, untouched by the redesign. |
| `_top_bar` · `_top_bar_desktop` · `_sidebar_nav` · `_bottom_nav` | 1 each (`layouts/app`) | The shell. Four partials, one layout, CSS picks the variant. |

**Three rows deleted from this table on 2026-08-27, because the files are gone:**

- ~~`_data_status`~~ — no such partial. Freshness is still shown, but not by this.
- ~~`_index_card`~~ — no such partial. The row was already corrected once (*"not orphaned after
  all"*) and then the file went with `/market`'s listing under D31. Corrected twice, deleted once,
  never re-read.
- ~~`_asset_price`~~ — see below. This is the one that matters.

🐞 **`_asset_price` is gone and its broadcast is still wired.** This table said *"Survives — the
live-price mechanism the design keeps"*, and the `_asset_fundamentals` row above cited it as the
**counter-example**: *"Compare `_asset_price`, whose target really is mounted by two tables: same
mechanism, wired."* Neither half is true now. Measured:

- `app/views/components/_asset_price.html.erb` does not exist.
- `MarketData::Handlers::BroadcastPriceUpdate` still renders `partial: "components/asset_price"`
  into `target: "asset_price_#{asset.id}"`, and `config/initializers/event_subscriptions.rb` still
  subscribes it to `AssetPriceUpdated`.
- No view in `app/views` mounts an `asset_price_*` id — the two tables that did went with the
  listing.
- `spec/contexts/market_data/handlers/broadcast_price_update_spec.rb` stubs
  `Turbo::StreamsChannel`, so it asserts the call was made and never renders. **It is green.**

That is the exact failure mode this section documented for `_asset_fundamentals` — a broadcast into
a partial nothing serves, passing because its spec asserts the call rather than the render — with
the roles reversed: there the partial outlived the mount, here the handler outlived the partial.
**Mount-or-delete is the same choice, and it is not this document's to make**; it is recorded here
as a measurement for whoever owns the next slice.

~~`_global_search`~~ and ~~`_notification_panel`~~ were **deleted in the shell slice**: the
redesigned TopBar is logo + bell, and D13 made the inbox a screen so the bell navigates to
`/notifications` instead of opening a dropdown.

**Corrected 2026-08-27:** the `_global_search` row also said *"`/search` stays routable with no
entry point; a spec pins that"*. It is not routable and no spec pins it — `/search` was **deleted**
under D35 (#295), and `config/routes.rb` has no `search` route at all. The one search the design
draws is Rastreados·Buscar, served by `assets#search_ticker` at `tracked/search`. Routable-and-
unlisted was a holding pattern that ended on 2026-08-26; this row outlived it by a day.

## What this document does not decide

- **Deletion order.** Everything above is measurement plus a recommendation; the deletions
  land inside their slice, so a net-new partial can be written with the dead one still open
  in an editor. The shell slice took its own: eight files, plus the two Stimulus controllers
  that only the old navbar used (`notification`, `search`). `mobile-menu` survives — the
  public navbar still uses it.
- **Kit gaps.** `PatrimonioStrip`, `WatchRow`, `ProviderCard`, `LogRow`, `TierChip` are
  flow-local by design (`ui-kit.CHANGELOG.md` 0.4.0). Promotion is a design call. Noted
  2026-08-27: `WatchRow` now has a code partial (`components/_watch_row`) while staying
  flow-local in the kit — the code side crossed the bar first, which is a reason to look at it
  again, not a reason to promote it here.
- **The 3-segment `Segmented`.** `ajustes-hub` draws a three-way control (Claro · Oscuro ·
  Sistema) while the kit's `Segmented` is the two-tab pill. Kit gap, logged here, resolved
  in design.
- **Vocabulary.** D48 (2026-08-27) renames the tier ladder — **Poseo → Holdings · Sigo →
  Watchlist · Rastreado(s) → Tracked** — and makes *Señales* the observation sense of *movimiento*.
  Component names here are not tier names and are unaffected, with one exception worth watching:
  the kit's `TierChip (Poseo / Sigo)` labels the ladder directly, so its copy changes when the
  rename lands. Prose in this document that still says `Rastreados` is describing the screen's
  current name, not endorsing it.
