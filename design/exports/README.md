# Exports — the review artifact

PNGs of the artboards, committed on purpose: a `.pen` is encrypted JSON, so without these a
design PR cannot be reviewed by anyone who does not open Pencil. They travel with the branch;
`references/` (gitignored device captures with real data) is the opposite policy — never mix them.

**Regenerating.** From an `execute` call with the flow **open**, `outputPath` is resolved from the
repo root, not from the `.pen`:

```js
Export(["<artboardId>", ...], "png", "design/exports", {scale: 2})
```

Files land as `<nodeId>.png` and are renamed to `<flow>-<screen>[-<state>].png` by hand — the ids
mean nothing to a reviewer. Re-export a flow whenever its artboards change materially; a stale PNG
is worse than a missing one.

**Index verified 2026-08-27.** All 62 rows below resolve to a file on disk, and every committed PNG
has a row — checked by listing the directory against the tables, not by reading them.

⚠ **One file on disk is not in this index: `ZHvbW.png`, untracked.** It is an un-renamed export
still carrying its node id — `[Activos] / Rastreados / Sin fuente`, whose renamed twin
`activos-tracked-sin-fuente.png` (renamed from `activos-rastreados-sin-fuente.png` by D48) is already committed and indexed below. It is left in place
deliberately: **deleting an export is the owner's call**, and an untracked file cannot be indexed
without first deciding whether it is a duplicate to remove or a re-shoot to keep. Whichever it is,
it should not survive as `ZHvbW.png` — the rename step above exists precisely because a node id
tells a reviewer nothing.

> **Artboard names here are the `.pen` masters', pre-D48.** D48 (2026-08-27) renames the tier
> ladder — **Poseo → Holdings · Sigo → Watchlist · Rastreado(s) → Tracked** — and makes *Señales*
> the observation sense of *movimiento*. The rows below still read `Sigo` and `Rastreados` because
> that is what the artboards are still called; they change when the `.pen` files are renamed and
> re-exported, and this index follows rather than leads. Filenames will change with them.

| File | Artboard |
|---|---|
| `cockpit-panorama-default.png` | `[Cockpit] / Panorama / Default` |
| `cockpit-panorama-tranquilo.png` | `[Cockpit] / Panorama / Tranquilo` |
| `cockpit-asset-analisis.png` | `[Cockpit] / Asset · Análisis / Default` |
| `cockpit-asset-mi-posicion.png` | `[Cockpit] / Asset · Mi posición / Default` |
| `cockpit-consolidado.png` | `[Cockpit] / Consolidado / Default` |
| `cockpit-movimientos.png` | `[Cockpit] / Movimientos / Default` — D42's gate was lifted 2026-08-27 |
| `activos-holdings.png` | `[Activos] / Holdings / Default` |
| `activos-watchlist.png` | `[Activos] / Watchlist / Default` |
| `activos-holdings-vacia.png` | `[Activos] / Holdings / Vacío` |
| `activos-registrar-movimiento.png` | `[Activos] / Registrar movimiento / Sheet` |
| `activos-registrar-con-teclado.png` | `[Activos] / Registrar movimiento / Con teclado` |
| `activos-tracked.png` | `[Activos] / Tracked / Default` |
| `activos-tracked-sin-fuente.png` | `[Activos] / Tracked / Sin fuente` |
| `activos-tracked-buscar.png` | `[Activos] / Tracked · Buscar / Default` |
| `activos-historial.png` | `[Activos] / Historial / Default` — ⚠ see D43, designed after /positions hit its D35 deadline |
| `reglas-lista.png` | `[Reglas] / Reglas / Default` |
| `reglas-vacio.png` | `[Reglas] / Reglas / Vacío` |
| `reglas-nueva-regla.png` | `[Reglas] / Nueva regla / Sheet` |
| `reglas-bandeja.png` | `[Reglas] / Bandeja / Default` |
| `reglas-confluencia.png` | `[Reglas] / Confluencia / Default` |
| `auth-totp-alta.png` | `[Auth] / TOTP · Alta / Default` — ADR-018 |
| `auth-codigos-recuperacion.png` | `[Auth] / Códigos de recuperación / Default` — ADR-018 |
| `auth-codigo-recuperacion.png` | `[Auth] / Código de recuperación / Default` — ADR-018 |
| `descubrir-olas.png` | `[Descubrir] / Olas / Default` |
| `descubrir-olas-sin-datos.png` | `[Descubrir] / Olas / Sin datos` |
| `ajustes-hub.png` | `[Ajustes] / Hub / Default` |
| `ajustes-integraciones.png` | `[Ajustes] / Integraciones / Default` |
| `ajustes-integraciones-estados.png` | `[Ajustes] / Integraciones · Estados / Default` |
| `ajustes-registros.png` | `[Ajustes] / Registros / Default` |
| `ajustes-estado.png` | `[Ajustes] / Estado y mantenimiento / Default` |

**Desktop (1280).** Drawn for the screens whose layout genuinely diverges, per D4 — the rest
reflow. The kit's shell variant is included because it is what every desktop artboard instances.

| File | Artboard |
|---|---|
| `ui-kit-shell-desktop.png` | `AppShellDesktop` (`ui-kit.lib.pen`) |
| `cockpit-panorama-desktop.png` | `[Cockpit] / Panorama · Desktop / Default` |
| `cockpit-asset-analisis-desktop.png` | `[Cockpit] / Asset · Análisis · Desktop / Default` |
| `cockpit-consolidado-desktop.png` | `[Cockpit] / Consolidado · Desktop / Default` |
| `activos-holdings-desktop.png` | `[Activos] / Holdings · Desktop / Default` |
| `activos-registrar-movimiento-desktop.png` | `[Activos] / Registrar movimiento · Desktop / Dialog` |
| `activos-tracked-desktop.png` | `[Activos] / Tracked · Desktop / Default` |
| `descubrir-olas-desktop.png` | `[Descubrir] / Olas · Desktop / Default` |
| `ajustes-hub-desktop.png` | `[Ajustes] / Hub · Desktop / Default` |
| `ajustes-integraciones-desktop.png` | `[Ajustes] / Integraciones · Desktop / Default` |
| `ajustes-estado-desktop.png` | `[Ajustes] / Estado y mantenimiento · Desktop / Default` |

Not drawn on desktop, on purpose: `Watchlist`, `Holdings vacía`, the two `Tracked · Buscar` and
`Reglas` states, `Descubrir · Sin datos` (it reflows into the same two-column shell with the
notice and the Calendario alone), and `Registros` — each reflows into a pattern one of the ones above already
settles. `Registros` would want a real log table, which is a new component and therefore a
decision, not a redraw.

**Nothing missing.** `flows/auth.pen` and `flows/onboarding.pen` shipped before this convention
existed; both were caught up on 2026-08-24. Every artboard in every flow now has a PNG here.

**Auth gained three artboards 2026-08-27** — TOTP enrollment, the one-time recovery-code display
and recovery-code entry at login (ADR-018). `auth-2fa.png` was re-shot: its `Enviar código por
correo` link is now `Usar un código de recuperación`, email OTP being explicitly out of scope. Per
D4 none of the three needs a desktop variant.

**`_playground.pen` has no exports on purpose.** It holds exploration, not screens; `Panel · V1…V4`
moved there from `auth.pen` in the same pass.

**Cockpit re-shot 2026-08-27** on kit 0.8.0 — all nine artboards, because the vendored `TopBar`
grew 57 → 76 and `TopBarDesktop` 76 → 80. `cockpit-panorama-black-swan.png` is gone with its
artboard (D51). A stray `ZHvbW.png` was deleted in the same pass: `Export` names files by node id,
so an export that is never renamed survives as an orphan nobody can identify.

| File | Artboard |
|---|---|
| `onboarding-setup.png` | `[Onboarding] / Setup / Default` |
| `onboarding-setup-desktop.png` | `[Onboarding] / Setup / Desktop` |
| `onboarding-integrations.png` | `[Onboarding] / Integrations / Default` |
| `onboarding-assets.png` | `[Onboarding] / Assets / Default` |
| `onboarding-complete.png` | `[Onboarding] / Complete / Default` |
| `onboarding-welcome.png` | `[Onboarding] / Welcome / Default` |
| `onboarding-integrations-desktop.png` | `[Onboarding] / Integrations / Desktop` |
| `onboarding-assets-desktop.png` | `[Onboarding] / Assets / Desktop` |
| `onboarding-welcome-desktop.png` | `[Onboarding] / Welcome / Desktop` |

| File | Artboard |
|---|---|
| `auth-login.png` | `[Auth] / Login / Default` |
| `auth-2fa.png` | `[Auth] / 2FA / Default` — ⚠ see D23, this screen has no code behind it |
| `auth-forgot.png` | `[Auth] / Forgot / Default` |
| `auth-email-sent.png` | `[Auth] / Email sent / Default` |
| `auth-reset.png` | `[Auth] / Reset / Default` |
| `auth-login-desktop.png` | `[Auth] / Login · Desktop / Default` |

## Brand (`brand.pen`)

Not a flow — an identity sheet (D44), so the rows are sheets rather than `[Flow] / Screen / State`
artboards.

| File | Artboard |
|---|---|
| `brand-brief.png` | `Brand / Brief` — the five findings and where each one stands |
| `brand-actual.png` | `Actual / Símbolo` — the mark being replaced, kept deliberately as the before |
| `brand-exploracion.png` | `C1 / Asimetría sin alargar` — F1 / F2 / F3, the three that survived the cull |
| `brand-simbolo-color.png` | `F2 / Símbolo y color` — construction, optical ladder, the six valid contrast pairs |
| `brand-wordmark-lockup.png` | `F2 / Wordmark y lockup` |
| `brand-usos.png` | `F2 / Usos` — correct, and the seven incorrect |
| `brand-pwa.png` | `F2 / PWA y aplicaciones` |
| `brand-escala-1x.png` | `F2 / Símbolo y color › Escala` — **exported at `scale: 1`, not 2** |

**Why one file breaks the scale-2 rule.** Every other PNG here is a review artifact and 2× makes it
readable. `brand-escala-1x.png` is a *measurement*: at 2× a "16 px" sample renders 32 px wide and
flatters itself. At true 1× it shows the honest floor — the wicks close at 24 px and below, and
only the candle bodies survive. Re-export it at 1× or do not re-export it at all.

> **Renamed and re-shot 2026-08-27 — the whole `activos` set.** D48 moved the tier ladder to
> Holdings · Watchlist · Tracked, so eight of the twelve filenames changed with their artboards.
> All twelve were re-exported regardless of rename, because kit 0.8.0 grew the TopBar from 57 to
> 76 and every screen in the flow moved its content down 19px. An `activos-cartera*` or
> `activos-rastreados*` file referenced anywhere else in the repo is a stale link.
>
> **Export writes relative to the repo root, not to the `.pen`.** `Export(..., "./exports")` from
> `design/flows/assets.pen` lands in `/exports`, not `design/exports/`. Move them after exporting.
