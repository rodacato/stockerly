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

**Re-counted 2026-08-28: 68 rows, 68 PNGs on disk.** The previous header claimed 62 and was already
stale before the three `Importar CSV` rows (#401) were appended — the actual count was 65. Counted by
listing the directory against the tables (`ls design/exports/*.png | wc -l` against a grep of the row
prefix), not by reading them.

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
| `cockpit-panorama-tranquilo.png` | `[Cockpit] / Panorama / Tranquilo` — nothing moved today |
| `cockpit-panorama-primera-vez.png` | `[Cockpit] / Panorama / Primera vez` — nothing held or watched yet |
| `cockpit-senales.png` | `[Cockpit] / Señales / Default` |
| `cockpit-senales-vacio.png` | `[Cockpit] / Señales / Vacío` |
| `cockpit-asset-analisis.png` | `[Cockpit] / Asset · Análisis / Default` |
| `cockpit-asset-analisis-aviso.png` | `[Cockpit] / Asset · Análisis / Aviso TradingView` |
| `cockpit-asset-mi-posicion.png` | `[Cockpit] / Asset · Mi posición / Default` |
| `cockpit-asset-cetes.png` | `[Cockpit] / Asset · CETES / Default` — fixed income, no chart (D98) |
| `cockpit-consolidado.png` | `[Cockpit] / Consolidado / Default` |
| `cockpit-consolidado-sin-historial.png` | `[Cockpit] / Consolidado / Sin historial` — no curve and no comparison yet |
| `activos-holdings.png` | `[Activos] / Holdings / Default` |
| `activos-watchlist.png` | `[Activos] / Watchlist / Default` |
| `activos-holdings-vacia.png` | `[Activos] / Holdings / Vacío` |
| `activos-watchlist-vacia.png` | `[Activos] / Watchlist / Vacía` |
| `activos-holdings-sin-consolidar.png` | `[Activos] / Holdings / Sin consolidar` — no FX rate: rows keep their own currency |
| `activos-registrar-movimiento.png` | `[Activos] / Registrar movimiento / Sheet` |
| `activos-registrar-con-teclado.png` | `[Activos] / Registrar movimiento / Con teclado` |
| `activos-registrar-movimiento-cetes.png` | `[Activos] / Registrar movimiento / CETES` — a fixed-income buy asks for Vencimiento |
| `activos-tracked.png` | `[Activos] / Tracked / Default` |
| `activos-tracked-agregar.png` | `[Activos] / Tracked · Agregar activo / Default` — D64 |
| `activos-tracked-sin-fuente.png` | `[Activos] / Tracked / Sin fuente` |
| `activos-tracked-sin-coincidencias.png` | `[Activos] / Tracked / Sin coincidencias` |
| `activos-historial.png` | `[Activos] / Historial / Default` — ⚠ see D43, designed after /positions hit its D35 deadline |
| `activos-historial-vacio.png` | `[Activos] / Historial / Vacío` |
| `activos-importar.png` | `[Activos] / Importar CSV / Default` |
| `activos-importar-revision.png` | `[Activos] / Importar CSV / Revisión` — the dry run: nothing written yet |
| `activos-importar-desconocidos.png` | `[Activos] / Importar CSV / Símbolos desconocidos` — the all-or-nothing refusal |
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
| `ajustes-nombre-correo.png` | `[Ajustes] / Nombre y correo / Default` |
| `ajustes-contrasena.png` | `[Ajustes] / Contraseña / Default` |
| `ajustes-integraciones.png` | `[Ajustes] / Integraciones / Default` |
| `ajustes-integraciones-administrar.png` | `[Ajustes] / Integraciones · Administrar / Default` — one source opened: verify, key, limits, delete |
| `ajustes-integraciones-estados.png` | `[Ajustes] / Integraciones · Estados / Default` |
| `ajustes-registros.png` | `[Ajustes] / Registros / Default` |
| `ajustes-registros-detalle.png` | `[Ajustes] / Registros · Detalle / Default` — one entry opened: payload and detail |
| `ajustes-estado.png` | `[Ajustes] / Estado y mantenimiento / Default` |
| `ajustes-errores.png` | `[Ajustes] / Errores / Default` — only with developer_mode (ADR-020) |
| `ajustes-errores-detalle.png` | `[Ajustes] / Errores · Detalle / Default` |
| `ajustes-en-mantenimiento.png` | `[Ajustes] / En mantenimiento / Default` — the 503 page a visitor gets while maintenance_mode is on |

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

**Ajustes re-shot 2026-09-16** — every artboard, mirrored to the code (D78), plus `Integraciones · Administrar`
and `Registros · Detalle`. The three desktop PNGs are gone with their artboards: every Ajustes screen is one
column (D4). The five rows this index lacked (nombre y correo, contraseña, errores, errores · detalle, en
mantenimiento) are in.

**Onboarding re-shot 2026-09-16** — every artboard, mirrored to the code (D78), plus `Setup / Error`.
`onboarding-integrations-desktop.png` and `onboarding-assets-desktop.png` are gone with their
artboards: the wizard steps have no `lg:` layout (D4).

**Descubrir re-shot 2026-08-27** — all three artboards, for the same reason Cockpit was: the
vendored `TopBar` grew 57 → 76 and `TopBarDesktop` 76 → 80.

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
| `onboarding-setup-error.png` | `[Onboarding] / Setup / Error` — the contract's failures, listed as the app renders them |
| `onboarding-setup-desktop.png` | `[Onboarding] / Setup / Desktop` |
| `onboarding-integrations.png` | `[Onboarding] / Integrations / Default` |
| `onboarding-assets.png` | `[Onboarding] / Assets / Default` |
| `onboarding-seguridad.png` | `[Onboarding] / Seguridad / Default` — the D52 step; it offers TOTP and lets you skip |
| `onboarding-seguridad-alta.png` | `[Onboarding] / Seguridad · Alta / Default` — enrolment opened from the wizard, in its frame (D122); the Ajustes entry is `auth-totp-alta.png` and `auth-codigos-recuperacion.png` |
| `onboarding-seguridad-codigos.png` | `[Onboarding] / Seguridad · Códigos / Default` — the recovery codes, same frame |
| `onboarding-complete.png` | `[Onboarding] / Complete / Default` |
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
