# CLAUDE.md - Stockerly

## Que es este proyecto

Stockerly es una plataforma fintech de analisis de tendencias bursatiles construida con Ruby on Rails 8. Permite a usuarios monitorear activos financieros (stocks, crypto, indices), gestionar portafolios, configurar alertas y consultar calendarios de earnings.

## Identity del asistente

El archivo `IDENTITY.md` en la raiz define el rol y personalidad del asistente AI: **Staff Software Engineer & Arquitecto de Producto** especializado en Rails, DDD y fintech. Lee ese archivo para entender los principios de trabajo, stack tecnico y estilo de comunicacion.

## Documentos de referencia

La especificacion del producto vive en `docs/spec/` y los disenos en `designs/`:

| Documento | Ubicacion | Contenido |
|-----------|-----------|-----------|
| Catalogo de paginas | `docs/CATALOG.md` | Indice maestro: todas las paginas, zona, ruta, estado |
| Workflow | `docs/WORKFLOW.md` | Proceso para agregar nuevas pantallas |
| Mapa de implementacion | `docs/spec/README.md` | Layouts, partials, rutas, controladores, fases |
| PRD | `docs/spec/PRD.md` | Funcionalidades, criterios de aceptacion |
| Spec Tecnica | `docs/spec/TECHNICAL_SPEC.md` | Stack, arquitectura, Hotwire, Stimulus |
| BD Schema | `docs/spec/DATABASE_SCHEMA.md` | Migraciones, modelos, seeds |
| Use Cases | `docs/spec/COMMANDS.md` | Catalogo DDD, events, gateways |
| Expertos | `docs/spec/EXPERTS.md` | 10 roles especializados para consultar |
| Sugerencias | `docs/spec/SUGGESTIONS.md` | Evaluacion cruzada (APPLIED) |
| Disenos visuales | `designs/{zona}/{pagina}/screen.png` | Capturas de cada pagina |
| HTML referencia | `designs/{zona}/{pagina}/code.html` | HTML de Stitch como referencia |
| Spec de pagina | `designs/{zona}/{pagina}/SPEC.md` | Metadatos estructurados por pagina |
| WIP processing | `designs/wip/PROCESSING.md` | Como procesar nuevos exports de Stitch |

## Arquitectura

- **Framework:** Ruby on Rails 8
- **CSS:** Tailwind CSS con theme custom (color primario `#004a99`)
- **Iconos:** Material Symbols Rounded (Google Fonts)
- **Tipografia:** Inter (Google Fonts)
- **Graficos:** CSS/SVG inline (conic-gradient donut, sparklines SVG)
- **Interactividad:** Hotwire (Turbo Drive/Frames/Streams) + Stimulus
- **Auth:** has_secure_password (sin Devise)
- **Arquitectura:** DDD pragmatico, Hexagonal, dry-monads

## Estructura de layouts

6 archivos de layout en `app/views/layouts/` (1 base + 5 específicos):
- `application.html.erb` — Layout base (meta tags, CDN, yield)
- `public.html.erb` — Landing, Trend Explorer, Open Source
- `auth.html.erb` — Login / Registro
- `app.html.erb` — Dashboard, Market, Portfolio, Alerts, Earnings, Profile (requiere login)
- `admin.html.erb` — Panel admin con sidebar (requiere rol admin)
- `legal.html.erb` — Privacy, Terms, Risk Disclosure (2 columnas con TOC)

## Zonas de acceso

- **Publica:** `/`, `/trends`, `/open-source`, `/privacy`, `/terms`, `/risk-disclosure`, `/login`, `/register`
- **Autenticada:** `/dashboard`, `/market`, `/portfolio`, `/alerts`, `/earnings`, `/profile`
- **Autenticada (password reset):** `/forgot-password`, `/reset-password/:token`
- **Admin:** `/admin/assets`, `/admin/logs`, `/admin/users`

## Enfoque de implementacion

1. Vistas primero con datos hardcodeados (frontend-first)
2. Luego modelos, migraciones y seeds
3. Finalmente conectar vistas al backend
4. Cada commit entrega valor incremental

## Convenciones

- Responder en **espanol** por defecto
- No sobre-ingenierar: solo lo que se pidio
- Simplicidad sobre abstraccion prematura
- Tests en Use Cases y Contracts, request specs para flujos criticos
- Seguridad: validacion en la frontera, autorizacion por request
