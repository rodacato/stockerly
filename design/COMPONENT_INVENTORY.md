# Component inventory — the translation work order

> [CODE_CHANGES.md](CODE_CHANGES.md) §0.5. Crosses the kit's **13 components**
> (`ui-kit.lib.pen` 0.4.0) against `app/views/components/`. Measured 2026-08-24 on
> `chore/2.0-prework`; every count below is a grep, not an impression.

**The headline the section did not expect: `app/views/components/` holds 19 partials and
11 of them are alive.** Seven have zero references anywhere in `app/`, `lib/` or `spec/`,
and an eighth renders only into a Turbo Stream target no page mounts. So the crossing is
not 19 against 13 — it is 11 against 13, and the overlap is thinner still.

## A. The kit's 13 — where each one lives in code today

Reuse is the exception, not the rule. Nine of thirteen are net-new partials whose markup
exists today only as repetition inside page templates.

| Kit component | Today in code | Verdict | Measured |
|---|---|---|---|
| `TopBar` | ~~`shared/_app_navbar.html.erb`~~ → `components/_top_bar` | ✅ **Shipped** (slice 1) | The old navbar is deleted |
| `Card` | inline everywhere | **Net-new** | `bg-bg-surface` appears in 99 template lines |
| `ButtonPrimary` | inline everywhere | **Net-new** | 35 inline primary-button class strings |
| `ButtonSecondary` | inline everywhere | **Net-new** | same sites, secondary variants |
| `Field` | raw form helpers | **Net-new** | 36 `*_field` / `select` calls, each with its own class string |
| `Segmented` | `data-controller="tabs"` markup | **Net-new** | 4 templates hand-roll a tab pill |
| `AssetRow` | table `<tr>` markup | **Net-new** | `dashboard/_watchlist_table`, `market/_listings_table` |
| `MovementItem` | table `<tr>` markup | **Net-new** | `trades/_trade_row`, `portfolios/_positions_table` |
| `MarketCard` | — | **Net-new** | `components/_kpi_card` is the right shape but is dead (§B) |
| `NavRow` | — | **Net-new** | nothing in code has this shape |
| `SwitchRow` | — | **Net-new** | 20 templates mention a toggle; no shared partial |
| `BottomNav` | `components/_bottom_nav` | ✅ **Shipped** (slice 1) | Net-new, as measured |
| `Stepper` | — | **Net-new** | onboarding has no step indicator partial |

Two things follow. First, `TopBar` is the only genuine revamp, which is why the shell slice
is slice 1: it is the one place where the kit meets existing code instead of replacing it.
Second, the four primitives (`Card`, `Field`, and the two buttons) are where the translation
either pays for itself or does not — every later slice spends them.

## B. The 19 partials — what happens to each

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

### Broken: renders into a target nothing mounts (1)

| Partial | What is wrong |
|---|---|
| `_asset_fundamentals` | `MarketData::Handlers::BroadcastFundamentalsUpdate` replaces `#asset_fundamentals_<id>`. That id exists **only inside this partial**, and no view renders the partial — so the broadcast is a silent no-op. Its spec asserts the broadcast call was made, so it passes. Compare `_asset_price`, whose target really is mounted by two tables: same mechanism, wired. |

Decide in slice 3 (asset detail): either mount the frame or delete handler, partial and spec
together. The `rescue ActionView::MissingTemplate` inside the handler is stale — it guards
against a partial that has existed for a long time.

### Alive (11)

| Partial | Renders | Destination |
|---|---|---|
| `_asset_badge` | 10 | Survives. Folds into `AssetRow` / `MovementItem` as their leading element. |
| `_empty_state` | 7 | Survives, restyled — the design gives the empty states real content (`activos-cartera-vacia`). |
| `_sparkline` | 4 | Survives. Becomes part of `AssetRow`. |
| `_skeleton` | 4 | Survives as-is. No kit equivalent and none needed. |
| `_donut_chart` | 3 | Survives → Consolidado (slice 4). Kit gap: it needs a categorical ramp, still open. |
| `_data_status` | 2 | Survives; freshness is still shown in the design. |
| `_index_card` | 2 | Survives → Panorama market cards. Check against `MarketCard` before keeping both. |
| `_asset_price` | broadcast | Survives — the live-price mechanism the design keeps. |
| ~~`_global_search`~~ | — | **Deleted in the shell slice.** The redesigned TopBar is logo + bell, and search's new home is Activos › Rastreados, which slice 2 builds. `/search` stays routable with no entry point; a spec pins that. |
| ~~`_notification_panel`~~ | — | **Deleted in the shell slice.** D13 made the inbox a screen, so the bell navigates to `/notifications` instead of opening a dropdown. |
| `_back_to_top` | 1 | Survives. Used by `layouts/legal`, untouched by the redesign. |

## What this document does not decide

- **Deletion order.** Everything above is measurement plus a recommendation; the deletions
  land inside their slice, so a net-new partial can be written with the dead one still open
  in an editor. The shell slice took its own: eight files, plus the two Stimulus controllers
  that only the old navbar used (`notification`, `search`). `mobile-menu` survives — the
  public navbar still uses it.
- **Kit gaps.** `PatrimonioStrip`, `WatchRow`, `ProviderCard`, `LogRow`, `TierChip` are
  flow-local by design (`ui-kit.CHANGELOG.md` 0.4.0). Promotion is a design call.
- **The 3-segment `Segmented`.** `ajustes-hub` draws a three-way control (Claro · Oscuro ·
  Sistema) while the kit's `Segmented` is the two-tab pill. Kit gap, logged here, resolved
  in design.
