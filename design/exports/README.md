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

| File | Artboard |
|---|---|
| `cockpit-panorama-default.png` | `[Cockpit] / Panorama / Default` |
| `cockpit-panorama-tranquilo.png` | `[Cockpit] / Panorama / Tranquilo` |
| `cockpit-panorama-black-swan.png` | `[Cockpit] / Panorama / Black swan` |
| `cockpit-asset-analisis.png` | `[Cockpit] / Asset · Análisis / Default` |
| `cockpit-asset-mi-posicion.png` | `[Cockpit] / Asset · Mi posición / Default` |
| `cockpit-consolidado.png` | `[Cockpit] / Consolidado / Default` |
| `activos-cartera.png` | `[Activos] / Cartera / Default` |
| `activos-sigo.png` | `[Activos] / Sigo / Default` |
| `activos-cartera-vacia.png` | `[Activos] / Cartera / Vacío` |
| `activos-registrar-movimiento.png` | `[Activos] / Registrar movimiento / Sheet` |
| `activos-registrar-con-teclado.png` | `[Activos] / Registrar movimiento / Con teclado` |
| `activos-rastreados.png` | `[Activos] / Rastreados / Default` |
| `activos-rastreados-buscar.png` | `[Activos] / Rastreados · Buscar / Default` |
| `reglas-lista.png` | `[Reglas] / Reglas / Default` |
| `reglas-vacio.png` | `[Reglas] / Reglas / Vacío` |
| `reglas-nueva-regla.png` | `[Reglas] / Nueva regla / Sheet` |
| `reglas-bandeja.png` | `[Reglas] / Bandeja / Default` |
| `reglas-confluencia.png` | `[Reglas] / Confluencia / Default` |
| `ajustes-hub.png` | `[Ajustes] / Hub / Default` |
| `ajustes-integraciones.png` | `[Ajustes] / Integraciones / Default` |
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
| `activos-cartera-desktop.png` | `[Activos] / Cartera · Desktop / Default` |
| `activos-registrar-movimiento-desktop.png` | `[Activos] / Registrar movimiento · Desktop / Dialog` |
| `activos-rastreados-desktop.png` | `[Activos] / Rastreados · Desktop / Default` |
| `ajustes-hub-desktop.png` | `[Ajustes] / Hub · Desktop / Default` |
| `ajustes-integraciones-desktop.png` | `[Ajustes] / Integraciones · Desktop / Default` |
| `ajustes-estado-desktop.png` | `[Ajustes] / Estado y mantenimiento · Desktop / Default` |

Not drawn on desktop, on purpose: `Sigo`, `Cartera vacía`, the two `Rastreados · Buscar` and
`Reglas` states, and `Registros` — each reflows into a pattern one of the ten above already
settles. `Registros` would want a real log table, which is a new component and therefore a
decision, not a redraw.

**Missing:** `flows/auth.pen` and `flows/onboarding.pen` shipped before this convention existed
and have no exports yet. Both files must be open in Pencil to export them — do it on their next
touch.
