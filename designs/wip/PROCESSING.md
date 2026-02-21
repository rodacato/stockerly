# Procesamiento de Diseños WIP — Stockerly

> Este documento guía el proceso para tomar los exports de Google Stitch que llegan a `designs/wip/`
> y moverlos a su ubicación correcta en la estructura de `designs/`, actualizando toda la documentación.

---

## Inventario actual en WIP

| Carpeta Stitch (wip/) | Pantalla identificada | Destino final | SPEC.md existe |
|---|---|---|---|
| `generated_screen_1/` | Forgot Password | `designs/public/forgot-password/` | Si |
| `generated_screen_2/` | Reset Password | `designs/public/reset-password/` | Si |
| `generated_screen_3/` | Empty States Collection | `designs/shared/empty-states/` | Si |
| `onboarding_-_step_1:_markets/` | Onboarding Paso 1 | `designs/shared/onboarding/` | Si |
| `onboarding_-_step_2:_stocks/` | Onboarding Paso 2 | `designs/shared/onboarding/` | Si |
| `onboarding_-_step_3:_success/` | Onboarding Paso 3 | `designs/shared/onboarding/` | Si |
| `notification_panel_dropdown_-_stockerly/` | Notification Panel | `designs/shared/notification-panel/` | Si |
| `market_news_-_stockerly/` | News Feed Page | `designs/shared/news-feed/` | Si |
| `global_search_dropdown_-_stockerly/` | Global Search | `designs/shared/global-search/` | Si |
| `stockerly_-_error_404/` | Error 404 | `designs/shared/error-pages/` | Si |
| `stockerly_-_error_500/` | Error 500 | `designs/shared/error-pages/` | Si |

---

## Paso 1: Mover archivos a su ubicación final

Renombrar archivos según la convención de la carpeta destino:

```bash
# Forgot Password
mv wip/generated_screen_1/screen.png  public/forgot-password/screen.png
mv wip/generated_screen_1/code.html   public/forgot-password/code.html

# Reset Password
mv wip/generated_screen_2/screen.png  public/reset-password/screen.png
mv wip/generated_screen_2/code.html   public/reset-password/code.html

# Empty States
mv wip/generated_screen_3/screen.png  shared/empty-states/screen.png
mv wip/generated_screen_3/code.html   shared/empty-states/code.html

# Onboarding (3 pasos -> misma carpeta con sufijo)
mv wip/onboarding_-_step_1:_markets/screen.png  shared/onboarding/screen-step1.png
mv wip/onboarding_-_step_1:_markets/code.html   shared/onboarding/code-step1.html
mv wip/onboarding_-_step_2:_stocks/screen.png   shared/onboarding/screen-step2.png
mv wip/onboarding_-_step_2:_stocks/code.html    shared/onboarding/code-step2.html
mv wip/onboarding_-_step_3:_success/screen.png  shared/onboarding/screen-step3.png
mv wip/onboarding_-_step_3:_success/code.html   shared/onboarding/code-step3.html

# Notification Panel
mv wip/notification_panel_dropdown_-_stockerly/screen.png  shared/notification-panel/screen.png
mv wip/notification_panel_dropdown_-_stockerly/code.html   shared/notification-panel/code.html

# News Feed
mv wip/market_news_-_stockerly/screen.png  shared/news-feed/screen.png
mv wip/market_news_-_stockerly/code.html   shared/news-feed/code.html

# Global Search
mv wip/global_search_dropdown_-_stockerly/screen.png  shared/global-search/screen.png
mv wip/global_search_dropdown_-_stockerly/code.html   shared/global-search/code.html

# Error Pages (2 variantes en misma carpeta)
mv wip/stockerly_-_error_404/screen.png  shared/error-pages/screen-404.png
mv wip/stockerly_-_error_404/code.html   shared/error-pages/code-404.html
mv wip/stockerly_-_error_500/screen.png  shared/error-pages/screen-500.png
mv wip/stockerly_-_error_500/code.html   shared/error-pages/code-500.html
```

---

## Paso 2: Actualizar SPEC.md de cada página

Para cada pantalla movida, actualizar su SPEC.md:

1. Cambiar **"Captura: Pendiente"** → **"Captura: screen.png"**
2. Cambiar **"HTML Stitch: Pendiente"** → **"HTML Stitch: code.html"**
3. Actualizar el estado de **"Diseno (Stitch): Pendiente"** → **"Completo"**
4. Para onboarding, listar las 3 variantes: `screen-step1.png`, `screen-step2.png`, `screen-step3.png`
5. Para error-pages, listar las 2 variantes: `screen-404.png`, `screen-500.png`

---

## Paso 3: Revisión de expertos

Pedir al AI assistant que consulte con los expertos relevantes de `docs/spec/EXPERTS.md`:

### Qué revisar por pantalla

| Pantalla | Expertos a consultar | Qué evaluar |
|---|---|---|
| Forgot/Reset Password | Security Engineer, UX Designer | Flujo seguro, inline validation, mensajes de error, rate limiting visual |
| Onboarding (3 pasos) | Product Strategist, UX Designer, Financial Expert | Criterio de activación, selección de assets populares, copy, CTA |
| Empty States | Product Strategist, UX Designer | Copy persuasivo, CTAs correctos, consistencia visual |
| Notification Panel | UX Designer, Domain Architect | Agrupación por tipo, real-time UX, mark-as-read flow |
| News Feed | Product Strategist, UX Designer, Data Engineer | Filtros, fuentes, relevancia, paginación |
| Global Search | UX Designer, Product Strategist | Keyboard navigation, grouping, debounce, shortcuts |
| Error Pages | UX Designer | Branding, tono, links de escape, no alarmar |

### Prompt sugerido para revisión

```
Revisa el diseño de [PANTALLA] (designs/{zona}/{pagina}/screen.png) contra:
1. El SPEC.md de la página (designs/{zona}/{pagina}/SPEC.md)
2. Las recomendaciones de SUGGESTIONS.md relevantes
3. Los expertos de EXPERTS.md que apliquen

Evalúa:
- ¿El diseño cubre todos los elementos listados en el SPEC.md?
- ¿Hay elementos en el diseño que no están en el SPEC.md? (actualizar)
- ¿Hay inconsistencias con el sistema de diseño (colores, tipografía, iconos)?
- ¿El diseño respeta las decisiones de SUGGESTIONS.md (APPLIED)?
- ¿Qué feedback darían los expertos?
```

---

## Paso 4: Actualizar documentos de especificación

Después de mover y revisar, actualizar estos documentos en `docs/spec/`:

### 4.1 PRD.md
- Verificar que cada nueva pantalla tenga un Feature ID (F-xxx)
- Pantallas nuevas que necesitan Feature ID:
  - Onboarding Wizard → F-018 (ya propuesto en SUGGESTIONS.md)
  - Empty States → F-019 (ya propuesto)
  - Notification System → agregar si no existe
  - News Feed → agregar si no existe
  - Global Search → agregar si no existe

### 4.2 README.md (Mapa de implementación)
- Actualizar sec. 1 "Resumen de Páginas" con las nuevas pantallas
- Actualizar sec. 4 "Partials" si el diseño revela partials nuevos
- Actualizar sec. 5 "Controladores y Vistas" con nuevos controllers
- Actualizar sec. 6 "Rutas" con nuevas rutas
- Actualizar sec. 8 "Fases" con las nuevas pantallas en la fase correcta

### 4.3 TECHNICAL_SPEC.md
- Agregar nuevos Stimulus controllers si el diseño los requiere
- Agregar Turbo Frames/Streams nuevos
- Documentar ActionCable channels (notifications, search)

### 4.4 DATABASE_SCHEMA.md
- Verificar que los modelos que usa cada pantalla están definidos
- Si una pantalla necesita un modelo nuevo, agregarlo al schema

### 4.5 COMMANDS.md
- Agregar Use Cases nuevos que las pantallas requieran
- Agregar Domain Events nuevos
- Ejemplo: OnboardingController necesita `Watchlist::AddAsset` (ya existe)

### 4.6 CATALOG.md
- Actualizar estado de cada pantalla de `D` (design) al estado correcto
- Agregar pantallas nuevas si no están en el catálogo

---

## Paso 5: Limpiar WIP

Una vez todo movido y verificado:

```bash
rm -rf designs/wip/
```

---

## Proceso futuro (para nuevos exports de Stitch)

Cada vez que generes nuevos diseños en Stitch:

1. **Exportar** de Stitch → colocar en `designs/wip/{nombre-de-stitch}/`
2. **Leer este documento** para identificar el destino correcto
3. **Mover** archivos a `designs/{zona}/{pagina}/`
4. **Actualizar** el SPEC.md de la página
5. **Revisar** con expertos (usar prompt sugerido arriba)
6. **Actualizar** docs de spec si hay cambios
7. **Actualizar** CATALOG.md con nuevo estado
8. **Limpiar** `designs/wip/`
9. **Commit**: `design: add stitch export for [nombre-pagina]`
