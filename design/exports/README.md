# Exports — the review artifact

PNGs of the artboards, committed on purpose: a `.pen` is a JSON scene graph nobody can review as a diff, so without these a
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

**Index check.** Every PNG on disk has exactly one table row below and every row has a file, 96 of
each on 2026-10-14. Verify with `ls design/exports/*.png | wc -l` against a grep of the row prefix,
not by reading the tables.

> **Names follow D48.** The tier ladder reads **Holdings · Watchlist · Tracked** and *Señales* is
> the observation sense of *movimiento*; rows and filenames already use them.

| File | Artboard |
|---|---|
| `cockpit-panorama-default.png` | `[Cockpit] / Panorama / Default` |
| `cockpit-panorama-tranquilo.png` | `[Cockpit] / Panorama / Tranquilo` — nothing moved today |
| `cockpit-hoy-default.png` | `[Cockpit] / Hoy / Default` — a verdict line, the patrimonio strip and VS CETES, three items, the sin-plan row |
| `cockpit-hoy-tranquilo.png` | `[Cockpit] / Hoy / Tranquilo` — "todo en orden", nothing to look at |
| `cockpit-hoy-primera-vez.png` | `[Cockpit] / Hoy / Primera vez` — an empty portfolio |
| `cockpit-hoy-sin-cotizacion.png` | `[Cockpit] / Hoy / Sin cotización` — stale quotes, never "todo en orden" |
| `cockpit-hoy-cotizaciones-viejas.png` | `[Cockpit] / Hoy / Cotizaciones viejas` — prices exist but are old or a sync failed: the strip stays with its warning line, no VS CETES, no plan |
| `cockpit-hoy-con-plan-dentro.png` | `[Cockpit] / Hoy / Con plan · dentro` — on plan, the plan card |
| `cockpit-hoy-con-plan-brecha.png` | `[Cockpit] / Hoy / Con plan · brecha` — a share off its target and no contribution, as items |
| `cockpit-panorama-primera-vez.png` | `[Cockpit] / Panorama / Primera vez` — nothing held or watched yet |
| `cockpit-senales.png` | `[Cockpit] / Señales / Default` |
| `cockpit-senales-vacio.png` | `[Cockpit] / Señales / Vacío` |
| `cockpit-asset-analisis.png` | `[Cockpit] / Asset · Análisis / Default` |
| `cockpit-asset-analisis-watchlist.png` | `[Cockpit] / Asset · Análisis / Watchlist` — watched, not held: no toggle, LO TUYO reads threshold, rule and earnings |
| `cockpit-hoy-temporada-resultados.png` | `[Cockpit] / Hoy / Temporada de resultados` — earnings dates read one row per day, symbols joined (D160) |
| `cockpit-hoy-decision-tasa.png` | `[Cockpit] / Hoy / Decisión de tasa` — a Fed or Banxico date within 7 days, ranked after maturity and earnings |
| `cockpit-hoy-push-matutino.png` | `[Cockpit] / Hoy / Push matutino` — the 08:00 daily brief on a lock screen: the verdict as title, the item titles as body |
| `cockpit-hoy-ayuda-abierta.png` | `[Cockpit] / Hoy / Ayuda abierta` — the verdict's ? open: the ringed header and its popover |
| `cockpit-hoy-actualizacion-disponible.png` | `[Cockpit] / Hoy / Actualización disponible` — the shell-wide PWA update toast above the BottomNav |
| `cockpit-asset-analisis-aviso.png` | `[Cockpit] / Asset · Análisis / Aviso TradingView` |
| `cockpit-asset-mi-posicion.png` | `[Cockpit] / Asset · Mi posición / Default` |
| `cockpit-asset-cetes.png` | `[Cockpit] / Asset · CETES / Default` — fixed income, no chart (D98) |
| `cockpit-consolidado.png` | `[Cockpit] / Consolidado / Default` |
| `cockpit-consolidado-por-sector.png` | `[Cockpit] / Consolidado / Por sector` — the split by sector (`?por=sector`) |
| `cockpit-consolidado-sin-historial.png` | `[Cockpit] / Consolidado / Sin historial` — no curve and no comparison yet |
| `activos-holdings.png` | `[Activos] / Holdings / Default` |
| `activos-watchlist.png` | `[Activos] / Watchlist / Default` |
| `activos-holdings-vacia.png` | `[Activos] / Holdings / Vacío` |
| `activos-watchlist-vacia.png` | `[Activos] / Watchlist / Vacía` |
| `activos-holdings-sin-consolidar.png` | `[Activos] / Holdings / Sin consolidar` — no FX rate: rows keep their own currency |
| `activos-holdings-sin-cotizacion.png` | `[Activos] / Holdings / Sin cotización` — a held asset has no quote, so the notice replaces the summary |
| `activos-registrar-movimiento.png` | `[Activos] / Registrar movimiento / Sheet` |
| `activos-registrar-con-teclado.png` | `[Activos] / Registrar movimiento / Con teclado` |
| `activos-registrar-movimiento-cetes.png` | `[Activos] / Registrar movimiento / CETES` — a fixed-income buy asks for Vencimiento |
| `activos-tracked.png` | `[Activos] / Tracked / Default` |
| `activos-tracked-agregar.png` | `[Activos] / Tracked · Agregar activo / Default` — D64 |
| `activos-tracked-sin-fuente.png` | `[Activos] / Tracked / Sin fuente` |
| `activos-tracked-sin-coincidencias.png` | `[Activos] / Tracked / Sin coincidencias` |
| `activos-tracked-vacio.png` | `[Activos] / Tracked / Vacío` — an empty catalogue: no budget bar |
| `activos-historial.png` | `[Activos] / Historial / Default` — ⚠ see D43, designed after /positions hit its D35 deadline |
| `activos-historial-editando.png` | `[Activos] / Historial / Editando` — a movement edited in place |
| `activos-historial-confirmar-borrado.png` | `[Activos] / Historial / Confirmar borrado` — the in-place delete confirmation |
| `activos-historial-vacio.png` | `[Activos] / Historial / Vacío` |
| `activos-importar.png` | `[Activos] / Importar CSV / Default` |
| `activos-importar-revision.png` | `[Activos] / Importar CSV / Revisión` — the dry run: nothing written yet |
| `activos-importar-desconocidos.png` | `[Activos] / Importar CSV / Símbolos desconocidos` — the all-or-nothing refusal |
| `activos-buscar-catalogo.png` | `[Activos] / Buscar / En tu catálogo` — D125 |
| `activos-buscar-catalogo-y-yahoo.png` | `[Activos] / Buscar / Catálogo y Yahoo` — D125: a catalogue hit plus Yahoo's other listings |
| `activos-buscar-fuera-de-catalogo.png` | `[Activos] / Buscar / Fuera de tu catálogo` — D125: Yahoo's results with Rastrear |
| `activos-buscar-sin-resultados.png` | `[Activos] / Buscar / Sin resultados` — D125 |
| `activos-buscar-yahoo-no-responde.png` | `[Activos] / Buscar / Yahoo no responde` — D125 |
| `activos-activo-desconocido.png` | `[Activos] / Activo desconocido / Default` — D125: /market/:symbol for a symbol the catalogue lacks |
| `activos-activo-desconocido-yahoo-no-responde.png` | `[Activos] / Activo desconocido / Yahoo no responde` — D125 |
| `reglas-vacio.png` | `[Reglas] / Reglas / Vacío` |
| `reglas-nueva-regla.png` | `[Reglas] / Nueva regla / Sheet` |
| `reglas-nueva-regla-calendario.png` | `[Reglas] / Nueva regla / Calendario` |
| `reglas-lista.png` | `[Reglas] / Reglas / Default` |
| `reglas-bandeja.png` | `[Reglas] / Bandeja / Default` |
| `reglas-bandeja-vacia.png` | `[Reglas] / Bandeja / Vacía` |
| `auth-totp-alta.png` | `[Auth] / TOTP · Alta / Default` — ADR-018 |
| `auth-codigos-recuperacion.png` | `[Auth] / Códigos de recuperación / Default` — ADR-018 |
| `auth-codigo-recuperacion.png` | `[Auth] / Código de recuperación / Default` — ADR-018 |
| `descubrir-olas.png` | `[Descubrir] / Olas / Default` |
| `descubrir-olas-todas.png` | `[Descubrir] / Olas / Todas las canastas` — the basket opened in place (D94) |
| `descubrir-olas-sin-datos.png` | `[Descubrir] / Olas / Sin datos` |
| `descubrir-olas-calendario-agotado.png` | `[Descubrir] / Olas / Calendario agotado` — past the YAML's horizon (D33) |
| `ajustes-hub.png` | `[Ajustes] / Hub / Default` |
| `ajustes-hub-dos-pasos-activa.png` | `[Ajustes] / Hub / Dos pasos activa` — TOTP enrolled: a card with the codes left and Generar códigos nuevos |
| `ajustes-hub-avisos-bloqueados.png` | `[Ajustes] / Hub / Avisos bloqueados` — push permission denied: the phone switch stays off with the warning line under it |
| `ajustes-nombre-correo.png` | `[Ajustes] / Nombre y correo / Default` |
| `ajustes-contrasena.png` | `[Ajustes] / Contraseña / Default` |
| `ajustes-tu-plan-vacio.png` | `[Ajustes] / Tu plan / Vacío` — no plan yet, nothing prefilled |
| `ajustes-tu-plan-default.png` | `[Ajustes] / Tu plan / Default` — three shares summing to 100% and a contribution |
| `ajustes-tu-plan-error.png` | `[Ajustes] / Tu plan / Error` — the shares sum to 95% |
| `ajustes-integraciones.png` | `[Ajustes] / Integraciones / Default` |
| `ajustes-integraciones-administrar.png` | `[Ajustes] / Integraciones · Administrar / Default` — one source opened: verify, key, limits, delete |
| `ajustes-integraciones-estados.png` | `[Ajustes] / Integraciones · Estados / Default` |
| `ajustes-integraciones-vacio.png` | `[Ajustes] / Integraciones / Vacío` — every source deleted |
| `ajustes-registros.png` | `[Ajustes] / Registros / Default` |
| `ajustes-registros-detalle.png` | `[Ajustes] / Registros · Detalle / Default` — one entry opened: ID, severity and duration |
| `ajustes-registros-filtrado.png` | `[Ajustes] / Registros / Filtrado sin resultados` — a filter that matches nothing |
| `ajustes-estado.png` | `[Ajustes] / Estado y mantenimiento / Default` |
| `ajustes-estado-mantenimiento-activo.png` | `[Ajustes] / Estado y mantenimiento / Mantenimiento activo` — the switch on, with its warning box |
| `ajustes-errores.png` | `[Ajustes] / Errores / Default` — only with developer_mode (ADR-020) |
| `ajustes-errores-detalle.png` | `[Ajustes] / Errores · Detalle / Default` |
| `ajustes-en-mantenimiento.png` | `[Ajustes] / En mantenimiento / Default` — the 503 page a visitor gets while maintenance_mode is on |
| `ajustes-ayuda.png` | `[Ajustes] / Ayuda / Default` — /help as shipped (D161); nothing in the app links to it |

**Desktop (1280).** Drawn for the screens whose layout genuinely diverges, per D4 — the rest
reflow. The kit's shell variant is included because it is what every desktop artboard instances.

| File | Artboard |
|---|---|
| `ui-kit-shell-desktop.png` | `AppShellDesktop` (`ui-kit.lib.pen`) |
| `cockpit-panorama-desktop.png` | `[Cockpit] / Panorama · Desktop / Default` |
| `cockpit-consolidado-desktop.png` | `[Cockpit] / Consolidado · Desktop / Default` |
| `activos-holdings-desktop.png` | `[Activos] / Holdings · Desktop / Default` |
| `activos-registrar-movimiento-desktop.png` | `[Activos] / Registrar movimiento · Desktop / Dialog` |
| `activos-tracked-desktop.png` | `[Activos] / Tracked · Desktop / Default` |
| `activos-buscar-desktop.png` | `[Activos] / Buscar · Desktop / En tu catálogo` — D125: the results as a dropdown under the bar's field |

Not drawn on desktop, on purpose: `Watchlist`, `Holdings vacía`, the `Activos` empty and
notice states, the `Reglas` states, `Descubrir · Sin datos` (it reflows into the same two-column shell with the
notice and the Calendario alone), and every Ajustes screen — each reflows into a pattern one of the ones above already
settles.

**Nothing missing.** `flows/auth.pen` and `flows/onboarding.pen` shipped before this convention
existed; both were caught up on 2026-08-24. Every artboard in every flow now has a PNG here.

**Onboarding re-shot 2026-08-27** — five artboards plus one new: the Stepper went 3 → 4 steps
(D52), and `Assets` split its combined `ETFS · RENTA FIJA MX` card into two, catching up to a
locale that has had five separate categories all along. `Seguridad` gets no desktop artboard, the
same reason `Complete` gets none: both inherit the wizard frame exactly.

**Re-exported 2026-09-21 for kit 1.1.0 — 41 artboards, colour only.** The `primary-fg` token
landed in the code (accent text failed AA at 4.17:1 on 83 sites) and the ten `.pen` files vendored
it. Every artboard carrying accent text was re-exported: cockpit 7, activos 8, auth 9, reglas 6,
ajustes 4, descubrir 4, onboarding 3.

**34 of the 41 changed bytes; 7 did not, and that is correct.** `primary-hover` and `primary-fg`
resolve to the same value, so an artboard whose only accent text was already on `primary-hover`
renders identically — the token name is now right and the pixels never moved. The 34 are the ones
that were on `primary`, which moves `#5B6CFF` → `#4757E3`.

**These exports are colour-current and content-stale in the places the audit already lists.** The
re-export fixes the token, not the artboards: `ajustes-hub`'s integration badge still reads 10
against the code's 8, `reglas-lista`'s two stat tiles are still internally impossible, and the
three onboarding artboards ON-04 names are unchanged. Those need re-shooting against the code,
which is separate work.

**Ajustes re-shot 2026-09-16** — every artboard, mirrored to the code (D78), plus `Integraciones · Administrar`
and `Registros · Detalle`. The three desktop PNGs are gone with their artboards: every Ajustes screen is one
column (D4). The five rows this index lacked (nombre y correo, contraseña, errores, errores · detalle, en
mantenimiento) are in.

**Onboarding re-shot 2026-09-16** — every artboard, mirrored to the code (D78), plus `Setup / Error`.
`onboarding-integrations-desktop.png` and `onboarding-assets-desktop.png` are gone with their
artboards: the wizard steps have no `lg:` layout (D4).

**Re-shot 2026-09-17 for D123** — Alpha Vantage and FMP retired. Ajustes: `ajustes-integraciones`,
`ajustes-integraciones-administrar`, `ajustes-integraciones-estados` (its sin cuota card is ExchangeRate now) and
`ajustes-estado`. Onboarding: `onboarding-integrations`. Activos: the five Tracked PNGs, whose budget panel names
Yahoo Finance. Cockpit: `cockpit-asset-analisis`, for the statements' source label.

**Descubrir re-shot 2026-08-27** — all three artboards, for the same reason Cockpit was: the
vendored `TopBar` grew 57 → 76 and `TopBarDesktop` 76 → 80.

**Auth gained three artboards 2026-08-27** — TOTP enrollment, the one-time recovery-code display
and recovery-code entry at login (ADR-018). `auth-2fa.png` was re-shot: its `Enviar código por
correo` link is now `Usar un código de recuperación`, email OTP being explicitly out of scope. Per
D4 none of the three needs a desktop variant.

**`_playground.pen` has no exports on purpose.** It holds exploration, not screens. `Panel · V1…V4`
moved there from `auth.pen` in the same pass, and on to `brand.pen` on 2026-10-21.

**Cockpit re-shot 2026-08-27** on kit 0.8.0 — all nine artboards, because the vendored `TopBar`
grew 57 → 76 and `TopBarDesktop` 76 → 80. `cockpit-panorama-black-swan.png` is gone with its
artboard (D51). A stray `ZHvbW.png` was deleted in the same pass: `Export` names files by node id,
so an export that is never renamed survives as an orphan nobody can identify.

| File | Artboard |
|---|---|
| `onboarding-setup.png` | `[Onboarding] / Setup / Default` |
| `onboarding-setup-error.png` | `[Onboarding] / Setup / Error` — the contract's failures, listed as the app renders them |
| `onboarding-setup-desktop.png` | `[Onboarding] / Setup / Desktop` |
| `onboarding-integrations.png` | `[Onboarding] / Integrations / Default` |
| `onboarding-assets.png` | `[Onboarding] / Assets / Default` |
| `onboarding-seguridad.png` | `[Onboarding] / Seguridad / Default` — the D52 step; it offers TOTP and lets you skip |
| `onboarding-seguridad-alta.png` | `[Onboarding] / Seguridad · Alta / Default` — enrolment opened from the wizard, in its frame (D122); the Ajustes entry is `auth-totp-alta.png` and `auth-codigos-recuperacion.png` |
| `onboarding-seguridad-codigos.png` | `[Onboarding] / Seguridad · Códigos / Default` — the recovery codes, bare frame from both doors (D148) |
| `onboarding-complete.png` | `[Onboarding] / Complete / Default` |
| `onboarding-complete-sin-worker.png` | `[Onboarding] / Complete / Sin worker` — the warning when no worker attends the queue |
| `onboarding-welcome.png` | `[Onboarding] / Welcome / Default` |
| `onboarding-welcome-desktop.png` | `[Onboarding] / Welcome / Desktop` |

| File | Artboard |
|---|---|
| `auth-login.png` | `[Auth] / Login / Default` |
| `auth-login-error.png` | `[Auth] / Login / Error` — the inline alert every auth form shares |
| `auth-2fa.png` | `[Auth] / 2FA / Default` — ADR-018 |
| `auth-forgot.png` | `[Auth] / Forgot / Default` |
| `auth-email-sent.png` | `[Auth] / Email sent / Default` |
| `auth-reset.png` | `[Auth] / Reset / Default` |
| `auth-enlace-expirado.png` | `[Auth] / Enlace expirado / Default` |
| `auth-contrasena-actualizada.png` | `[Auth] / Contraseña actualizada / Default` |
| `auth-errores-404.png` | `[Auth] / Errores / 404` — public/404.html as shipped (retired disc mark) |
| `auth-errores-429.png` | `[Auth] / Errores / 429` — public/429.html, the one-button case |
| `auth-errores-500.png` | `[Auth] / Errores / 500` — public/500.html as shipped (English buttons) |
| `auth-login-desktop.png` | `[Auth] / Login · Desktop / Default` |

## Brand (`brand.pen`)

Not a flow — an identity sheet (D44), so the rows are sheets rather than `[Flow] / Screen / State`
artboards.

| File | Artboard |
|---|---|
| `brand-soft-candle.png` | `Actual / Soft Candle` — the shipped mark light, dark and monochrome at 64/32/16 px, the wordmarks, the icons and the social cards |
| `brand-brief.png` | `Brand / Brief` — the seven findings and where each one stands |
| `brand-usos.png` | `Actual / Usos` — correct, and the seven incorrect |
| `brand-panel-exploracion.png` | `Exploración / Panel de marca` — the four login brand panels; none ships (D152) |

> **Renamed and re-shot 2026-08-27 — the whole `activos` set.** D48 moved the tier ladder to
> Holdings · Watchlist · Tracked, so eight of the twelve filenames changed with their artboards.
> All twelve were re-exported regardless of rename, because kit 0.8.0 grew the TopBar from 57 to
> 76 and every screen in the flow moved its content down 19px. An `activos-cartera*` or
> `activos-rastreados*` file referenced anywhere else in the repo is a stale link.
>
> **Export writes relative to the repo root, not to the `.pen`.** `Export(..., "./exports")` from
> `design/flows/assets.pen` lands in `/exports`, not `design/exports/`. Move them after exporting.
