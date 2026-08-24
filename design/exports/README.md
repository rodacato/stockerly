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

**Missing:** `flows/auth.pen` and `flows/onboarding.pen` shipped before this convention existed
and have no exports yet. Both files must be open in Pencil to export them — do it on their next
touch.
