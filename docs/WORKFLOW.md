# Workflow: Agregar una Nueva Pantalla a Stockerly

> Proceso estandar para incorporar una nueva pantalla al proyecto,
> desde el diseno de referencia hasta los tests.
>
> Cada paso produce un artefacto concreto. No saltar pasos.

---

## Prerrequisito: Decidir la pantalla

Antes de abrir Stitch o crear carpetas:

1. Esta pantalla esta en el PRD (`docs/spec/PRD.md`)? Si no, necesita aprobacion.
2. A que zona pertenece? (`public` / `legal` / `app` / `admin` / `shared`)
3. Que ruta tendra? (verificar que no colisione en `config/routes.rb`)
4. Que controlador y action la sirve?
5. En que fase se implementa?

---

## Paso 1: Crear la carpeta en `designs/`

```bash
mkdir -p designs/{zona}/{nombre-kebab-case}/
```

**Reglas de nombre:**
- Siempre kebab-case (minusculas, guiones)
- Que coincida con el slug de la URL cuando sea posible
- Sin tildes, sin caracteres especiales, sin espacios
- Ejemplos: `forgot-password`, `risk-disclosure`, `global-search`

---

## Paso 2: Crear el SPEC.md inicial

Copiar la plantilla del Apendice A (abajo) y llenar como minimo:
- Seccion de Identificacion (ruta, layout, controlador, vista)
- Estado inicial: `design`

Dejar vacias las secciones que aun no aplican.

---

## Paso 3: Agregar la entrada al CATALOG.md

En `docs/CATALOG.md`, agregar la fila en la zona correcta con:
- Numero secuencial
- Nombre, ruta, layout, controlador
- Link al SPEC.md
- Estado: `D`

---

## Paso 4: Generar y exportar el diseno de Stitch

1. Escribir el prompt para Google Stitch (ver PROCESSING.md para ejemplos)
2. Exportar `screen.png` (captura full-page) y `code.html` (HTML de referencia)
3. Colocar en `designs/wip/{nombre-de-stitch}/` temporalmente
4. Seguir `designs/wip/PROCESSING.md` para mover a su destino final
5. Actualizar SPEC.md: "Captura: screen.png", "Diseno (Stitch): Completo"

**Commit:** `design: add stitch export for [nombre-pagina]`

---

## Paso 5: Revision con expertos

Pedir revision contra los expertos relevantes de `docs/spec/EXPERTS.md`:

```
Revisa el diseno de [PANTALLA] (designs/{zona}/{pagina}/screen.png) contra:
1. El SPEC.md de la pagina
2. Las recomendaciones de SUGGESTIONS.md relevantes
3. Los expertos aplicables de EXPERTS.md

Evalua:
- El diseno cubre todos los elementos del SPEC.md?
- Hay elementos nuevos que no estan en el SPEC.md? (actualizar)
- Es consistente con el sistema de diseno (colores, tipografia, iconos)?
- Que feedback darian los expertos?
```

---

## Paso 6: Actualizar docs de especificacion

Segun aplique:
- `docs/spec/PRD.md` — Agregar Feature ID (F-xxx) si es funcionalidad nueva
- `docs/spec/README.md` — Actualizar mapa de paginas, partials, rutas, fases
- `docs/spec/TECHNICAL_SPEC.md` — Nuevos Stimulus controllers, Turbo, ActionCable
- `docs/spec/DATABASE_SCHEMA.md` — Modelos nuevos que la pantalla necesite
- `docs/spec/COMMANDS.md` — Use Cases y Domain Events nuevos
- `ROADMAP.md` — Agregar la pantalla a la fase correspondiente

---

## Paso 7: Implementar el HTML estatico

1. Crear/actualizar ruta en `config/routes.rb`
2. Crear controlador y action
3. Crear vista `app/views/{nombre}/{accion}.html.erb`
4. Implementar con datos hardcodeados siguiendo `code.html`
5. Agregar partials en `app/views/shared/` o `app/views/components/`
6. Implementar empty state
7. Actualizar SPEC.md: completar secciones, estado → `static-html`
8. Actualizar CATALOG.md: estado → `H`

**Commit:** `feat: implement [nombre-pagina] static view`

---

## Paso 8: Conectar backend

1. Implementar Use Case y Contract
2. Conectar controlador al Use Case
3. Reemplazar datos hardcodeados por BD
4. Implementar Turbo Frames/Streams si aplica
5. Actualizar SPEC.md y CATALOG.md: estado → `backend-wired` / `B`

**Commit:** `feat: wire [nombre-pagina] to backend`

---

## Paso 9: Tests

1. Request spec en `spec/requests/`
2. Use Case specs en `spec/use_cases/`
3. Todos los tests pasando
4. Actualizar SPEC.md y CATALOG.md: estado → `tested` / `T` o `complete` / `OK`

**Commit:** `test: add specs for [nombre-pagina]`

---

## Checklist rapida (para PRs)

```
[ ] Carpeta en designs/{zona}/{pagina}/ creada
[ ] SPEC.md completo para el estado actual
[ ] Entrada en CATALOG.md actualizada
[ ] Diseno Stitch exportado (si disponible)
[ ] Ruta en config/routes.rb
[ ] Controlador creado
[ ] Vista implementada
[ ] Empty state implementado
[ ] Stimulus controllers documentados en SPEC.md
[ ] Turbo Frames/Streams documentados (si aplica)
[ ] Use Case y Contract creados (si backend)
[ ] Request spec escrita (si tests)
[ ] CATALOG.md y ROADMAP.md actualizados
```

---

## Apendice A: Plantilla SPEC.md

```markdown
# [Nombre de la pagina] — Spec

> **Zona:** public | legal | app | admin | shared
> **Estado:** design | static-html | backend-wired | tested | complete

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/ruta` |
| **Layout** | `layout-name` |
| **Controlador** | `NombreController#action` |
| **Vista principal** | `app/views/nombre/accion.html.erb` |
| **Fase** | Fase N |

---

## Diseno de referencia

- **Captura:** Pendiente — sin diseno Stitch aun
- **HTML Stitch:** Pendiente

---

## Secciones y elementos

> Secciones visibles en la pagina, de arriba hacia abajo.

---

## Datos necesarios

> Modelos y campos que necesita la pagina.

---

## Formularios y acciones

> Forms/HTTP actions, o "Ninguno" si es solo lectura.

---

## Stimulus controllers

> Lista de controllers, o "Ninguno identificado".

---

## Turbo

> Turbo Frames/Streams, o "No aplica".

---

## Empty state

> Que ve el usuario sin datos, o "No aplica".

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Pendiente |
| HTML estatico | Pendiente |
| Backend conectado | Pendiente |
| Tests | Pendiente |

---

## Notas

> Decisiones tecnicas, gotchas, edge cases.
```
