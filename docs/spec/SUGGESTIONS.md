# Stockerly - Evaluacion de Expertos y Sugerencias

> Evaluacion del producto por cada experto del panel, con discusion cruzada y recomendaciones priorizadas para complementar e incrementar el exito de Stockerly.
>
> **Documentos evaluados:** PRD.md, TECHNICAL_SPEC.md, DATABASE_SCHEMA.md, COMMANDS.md, README.md
> **Disenos evaluados:** 18 paginas en designs/ (screen.png + code.html)
>
> ---
> **ESTADO: APLICADO** — Las sugerencias de este documento han sido aplicadas a todos los documentos del proyecto.
> Decisiones clave tomadas durante la aplicacion:
> - **No pricing/premium** — Producto 100% open source, sin tiers. `account_tier` eliminado.
> - **Gem `money-rails`** reemplaza el Value Object `Money` custom para formateo y conversion FX.
> - **Social auth eliminado** de v1 completamente (solo email/password).
> - **Layouts reducidos a 5** archivos (1 base + 4 especificos). `auth.html.erb` fusionado con `public`.
> - **5 Bounded Contexts** — Watchlist fusionado en Trading.
> - **Repositories eliminados** en v1. Use Cases interactuan con ActiveRecord directamente.
> - **`dry-initializer` eliminado**, `ransack` diferido, `money-rails` agregado.
> - **Event handlers aplanados** — archivos planos, sin carpetas anidadas.
> - **9 nuevos modelos** agregados a DATABASE_SCHEMA.md (Trade, PortfolioSnapshot, FxRate, AssetPriceHistory, Notification, AuditLog, Dividend, DividendPayment, RememberToken).
> - **Paginas reducidas a 16** — multidivisa fusionado, Open Source diferido.

---

## 1. Financial Domain Expert — Evaluacion del Dominio

### Lo que esta bien

El modelado base es solido. Las entidades principales (Asset, Position, Portfolio, AlertRule, EarningsEvent) reflejan correctamente los conceptos del trading retail. La separacion stocks/crypto/index es correcta. Los campos de Asset (market_cap, P/E, div_yield, volume, shares_outstanding) son exactamente los que un trader espera ver en un screener. Los Bounded Contexts tienen sentido desde la perspectiva del dominio financiero.

### Problemas y Gaps

#### 1.1 No existe el concepto de "Trade" (Transaccion)

Las posiciones aparecen ya creadas con `avg_cost`, pero en la realidad un trader hace multiples compras y ventas del mismo activo. El `avg_cost` se deriva de transacciones individuales via weighted average.

**Impacto:** Sin un modelo `Trade`, no se puede:
- Calcular correctamente el average cost cuando se hacen compras parciales
- Mostrar el tab "Closed Positions" con P&L realizado por trade
- Mostrar "Dividend History" (un dividendo se paga por shares held en una fecha)
- Generar un statement de actividad (requerido por reguladores)
- Distinguir entre realized y unrealized P&L

**Modelo propuesto:**
```
Trade
  id, portfolio_id, asset_id
  side: enum (buy, sell)
  shares: decimal
  price_per_share: decimal
  total_amount: decimal
  fee: decimal (comision del broker)
  currency: string
  executed_at: datetime
```

El `avg_cost` de Position se calcula automaticamente: `SUM(shares * price) / SUM(shares)` de todos los trades de compra abiertos.

#### 1.2 El portafolio no tiene historico de valor

El dashboard muestra "+1.2% today" y "$840.12 Day Gain" pero no hay de donde calcularlo. Se necesita saber el valor total del portafolio al cierre del dia anterior.

**Modelo propuesto:**
```
PortfolioSnapshot
  id, portfolio_id
  date: date (unique per portfolio)
  total_value: decimal
  cash_value: decimal (buying power)
  invested_value: decimal
```

Un job diario (`SnapshotPortfolioJob`) captura el valor al cierre. El "Day Gain" = valor actual - snapshot de ayer.

#### 1.3 Dividendos no estan modelados

El diseno de Portfolio muestra un tab "Dividend History" pero no hay modelo que lo soporte.

**Modelo propuesto:**
```
Dividend
  id, asset_id
  ex_date: date
  pay_date: date
  amount_per_share: decimal
  currency: string
```

```
DividendPayment (lo que recibio el usuario)
  id, portfolio_id, dividend_id
  shares_held: decimal
  total_amount: decimal
  received_at: datetime
```

#### 1.4 Multi-divisa incompleto

El modelo tiene `preferred_currency` en User y `currency` en Position, pero falta la pieza central: las tasas de cambio.

**Modelo propuesto:**
```
FxRate
  id
  base_currency: string (ej: "USD")
  quote_currency: string (ej: "MXN")
  rate: decimal (ej: 17.25)
  fetched_at: datetime
```

**Reglas de negocio:**
- Todas las posiciones se almacenan en su moneda original
- La conversion ocurre solo al presentar al usuario, usando su `preferred_currency`
- Se usa el mid-market rate (promedio entre bid y ask)
- El "Last FX Refresh" del diseno se alimenta del `MAX(fetched_at)` de FxRate

#### 1.5 Market Sentiment sin fuente definida

El dashboard muestra "Market Sentiment: 65% Bullish" pero no hay modelo ni calculo.

**Opciones:**
1. Derivarlo de Trend Scores: `promedio de scores de assets en watchlist del usuario`
2. Usar el Fear & Greed Index de CNN (via API)
3. Calcular desde % de assets con cambio positivo en el dia

Recomiendo opcion 1 para v1 (no requiere API externa).

#### 1.6 Sin historico de precios para graficos

El Trend Explorer muestra un grafico de "Performance Trend" con selector 1Y/5Y/MAX, pero solo hay `current_price` en Asset.

**Modelo propuesto:**
```
AssetPriceHistory
  id, asset_id
  date: date
  open: decimal
  high: decimal
  low: decimal
  close: decimal
  volume: bigint
```

Esto tambien se necesita para calcular sparklines reales (actualmente son CSS decorativos) y para evaluar condiciones de alerta basadas en RSI o moving averages.

#### 1.7 WatchlistItem deberia tener precio de entrada

Traders quieren saber "cuanto ha cambiado desde que lo empece a seguir". Un campo `entry_price` capturado automaticamente al momento de agregar a watchlist da ese contexto sin esfuerzo del usuario.

---

## 2. Product Strategist — Evaluacion del Producto

### Lo que esta bien

La propuesta de valor es clara y bien articulada: dashboard unificado para traders con trends, alertas y earnings. El modelo open-source es un diferenciador fuerte en un mercado dominado por plataformas cerradas (TradingView, Yahoo Finance). Las 18 paginas cubren un flujo end-to-end coherente. La landing page tiene los elementos correctos de conversion (social proof, features, stats, CTA).

### Gaps y Oportunidades

#### 2.1 No hay onboarding flow (CRITICO)

Despues del registro, el usuario llega a un dashboard con KPIs en $0.00, watchlist vacia, y news sin contexto. Esto mata la activacion.

**Propuesta de onboarding en 3 pasos:**
1. **Elegir intereses** — "What markets are you interested in?" (US Stocks, Crypto, International) — esto pre-carga activos sugeridos
2. **Agregar a watchlist** — "Pick 3-5 stocks to follow" — mostrar los mas populares (AAPL, TSLA, NVDA, BTC) con boton + rapido
3. **Tour del dashboard** — Tooltip tour de 4 pasos: "Here's your watchlist", "Track your portfolio here", "Set alerts for price changes", "Check upcoming earnings"

**Criterio de activacion:** Un usuario esta "activado" cuando tiene al menos 3 items en watchlist. Todo el onboarding deberia apuntar a eso.

#### 2.2 Empty states no disenados (CRITICO)

Ninguna de las 18 paginas muestra que pasa cuando no hay datos. Cada empty state necesita:
- Ilustracion o icono sutil
- Texto explicativo (que es esto, por que esta vacio)
- CTA primario (la accion que llena este espacio)

**Empty states necesarios:**

| Pagina | Elemento Vacio | CTA |
|--------|---------------|-----|
| Dashboard | Watchlist Performance (0 items) | "Add your first stock to watchlist" |
| Dashboard | Relevant News (sin tickers seguidos) | "Follow stocks to see relevant news" |
| Portfolio | 0 positions | "Record your first investment" |
| Portfolio | Closed Positions tab vacio | "No closed positions yet" |
| Portfolio | Dividend History tab vacio | "Dividends will appear here when received" |
| Alerts | 0 alert rules | "Create your first price alert" |
| Alerts | Live Feed vacio | "Alerts will appear here in real-time" |
| Earnings | Watchlist Priority (0 events) | "Follow stocks to track their earnings" |
| Earnings | Calendar month sin eventos | "No earnings reports this month" |
| Profile | Watchlist vacia | "Start following stocks from the Market Explorer" |
| Admin Assets | 0 assets | "Add your first asset or run initial sync" |

#### 2.3 Limites Basic vs Premium no definidos

El PRD menciona tiers pero no especifica limites concretos. Sin esto no hay monetizacion.

**Propuesta de Feature Gating:**

| Feature | Basic (Free) | Premium ($9.99/mo) |
|---------|-------------|---------------------|
| Watchlist items | 5 max | Ilimitados |
| Alert rules | 3 max | 50 max |
| Portfolio positions | 10 max | Ilimitadas |
| Multi-divisa | Solo USD | USD, EUR, MXN, GBP, TWD + custom |
| Export CSV | No | Si |
| Earnings calendar | Solo mi watchlist | All markets |
| Market Explorer resultados | Top 50 | Todos (4,800+) |
| Historical data | 1 ano | 5 anos + MAX |
| Trend Explorer filtros | Basicos (sector, exchange) | Avanzados (volatility, trend strength, market cap) |
| News feed | 3 articulos/dia | Ilimitados |
| Delivery preferences | Solo browser push | Push + Email + SMS |

**Implementacion:** Un concern `Limitable` que checkea el tier en Use Cases antes de crear/agregar.

#### 2.4 Falta pagina de Pricing

La landing page tiene "Pricing" en la nav pero no hay diseno ni pagina. Es critica para conversion.

**Propuesta:**
- Layout publico
- Card comparativa Basic vs Premium (similar a los disenos de Tailwind UI pricing)
- Highlights de Premium con checkmarks
- CTA: "Start Free" (Basic) y "Start 14-day Trial" (Premium)
- FAQ section al final
- Testimonial de un trader

#### 2.5 No hay sistema de notificaciones in-app

El icono de campana con badge rojo aparece en toda la zona autenticada pero no hay:
- Modelo para persistir notificaciones
- Panel/dropdown para verlas
- Contador de no leidas

**Modelo propuesto:**
```
Notification
  id, user_id
  title: string
  body: text
  notification_type: enum (alert_triggered, earnings_reminder, system, promotion)
  read: boolean (default: false)
  notifiable_type: string (polymorphic)
  notifiable_id: bigint
  created_at: datetime
```

**UX:** Dropdown desde el icono de campana con las ultimas 10. Link "View All" a pagina dedicada. El badge muestra count de `read: false`.

**Integracion con Events:** Cuando `AlertRuleTriggered` se publica, un handler crea una Notification y la broadcastea via Turbo Stream al navbar.

#### 2.6 News no tiene pagina independiente

El nav muestra "News" en varias paginas pero no hay vista dedicada. Los articulos solo aparecen en el dashboard (3 items). Traders quieren un feed completo filtrable.

**Propuesta de pagina `/news`:**
- Feed de articulos con paginacion infinita (Turbo Frame append)
- Filtros: por ticker, por fuente (Bloomberg, Reuters, WSJ), por fecha
- Cada articulo: titulo, resumen, imagen, fuente, ticker relacionado, tiempo
- Click abre articulo externo en nueva tab

#### 2.7 Busqueda global sin definicion

El search bar aparece en todas las paginas autenticadas pero no hay spec de que busca.

**Propuesta:**
- Busqueda por asset (nombre o ticker) — resultado principal
- Busqueda por news (titulo) — resultado secundario
- Dropdown con resultados agrupados por tipo (Stimulus controller con debounce 300ms)
- Enter redirige a Market Explorer con el query como filtro
- Accesible via keyboard shortcut (Cmd+K / Ctrl+K)

#### 2.8 Mobile strategy ausente

El 60%+ de traders retail usan el celular para checkear su portafolio. Los disenos son 100% desktop.

**Propuesta para v1 (sin rediseno completo):**
- Tailwind responsive por defecto (las clases ya soportan breakpoints)
- Priorizar que sea funcional en mobile: Dashboard KPIs, Watchlist, Alerts feed
- Admin puede quedar solo desktop (los admins usan computadora)
- La nav del layout `app` deberia colapsarse a hamburger en mobile
- Las tablas (Market Explorer, Portfolio positions) deberian scrollar horizontalmente

---

## 3. Domain Architect — Evaluacion Arquitectonica

### Lo que esta bien

La estructura hexagonal es correcta: Use Cases como input ports, Contracts para validacion, Repositories/Gateways como output ports. La separacion en 6 Bounded Contexts es razonable. Los Domain Events estan bien identificados. El patron Use Case con dry-monads Result es limpio y testeable.

### Sugerencias de Mejora

#### 3.1 Bounded Context "Market Intelligence" esta sobrecargado

Contiene 5 conceptos muy diferentes: Assets, TrendScores, EarningsEvents, MarketIndices y NewsArticles. Cada uno tiene diferentes fuentes, frecuencias de actualizacion y patrones de acceso.

**Propuesta de separacion:**

| Bounded Context Original | Nuevo BC | Entidades | Justificacion |
|--------------------------|----------|-----------|---------------|
| Market Intelligence | **Market Data** | Asset, MarketIndex, AssetPriceHistory, FxRate | Datos crudos de mercado, source: APIs |
| Market Intelligence | **Analytics** | TrendScore | Inteligencia derivada, calculada internamente |
| Market Intelligence | **Content** | NewsArticle | Contenido editorial, source: feeds/APIs |
| Market Intelligence | **Earnings** | EarningsEvent | Calendario propio, source: APIs especializadas |

Esto facilita que cada contexto tenga su propia frecuencia de sync y su propio Gateway.

#### 3.2 Eventos faltantes criticos

| Evento | Trigger | Handlers |
|--------|---------|----------|
| `AssetPriceUpdated` | Job de sync actualiza precio | Evaluar AlertRules, recalcular TrendScores, broadcast a dashboards abiertos |
| `PasswordChanged` | Use Case Profiles::ChangePassword | Audit log, invalidar otras sesiones, email de confirmacion |
| `ProfileUpdated` | Use Case Profiles::UpdateInfo | Audit log |
| `PortfolioSnapshotTaken` | Job diario SnapshotPortfolio | Nada (es un side effect que se convierte en dato) |
| `TradeExecuted` | Use Case Positions::OpenPosition | Recalcular avg_cost, actualizar portfolio value, log de actividad |
| `CsvExported` | Use Cases de export | Audit log (para admin) |
| `FxRatesRefreshed` | Job de refresh | Broadcast a dashboards con multi-divisa activo |
| `NotificationCreated` | Handlers de otros eventos | Broadcast via Turbo Stream al navbar |

**El evento `AssetPriceUpdated` es el mas importante de todo el sistema.** Es el trigger que conecta Market Data → Alerts → Notifications → Dashboard. Sin el, las alertas no pueden funcionar.

#### 3.3 El EventBus necesita soporte async

El EventBus actual es sincronico (todo se ejecuta en el mismo request). Para handlers pesados (enviar email, evaluar alertas), deberian encolarse como jobs.

**Propuesta:**
```ruby
class EventBus
  def self.publish(event)
    @handlers[event.class.name].each do |handler|
      if handler.respond_to?(:async?) && handler.async?
        ProcessEventJob.perform_later(handler.name, event.to_h)
      else
        handler.call(event)
      end
    end
  end
end
```

Handlers como `SendWelcomeEmail` y `NotifyUser` deberian ser async. Handlers como `CreatePortfolio` deberian ser sync (el portafolio debe existir antes de que el usuario llegue al dashboard).

#### 3.4 Falta un Domain Service para evaluacion de alertas

El flujo de alertas es el mas complejo del sistema:
1. `AssetPriceUpdated` event se publica
2. Se buscan todas las `AlertRule` activas para ese asset
3. Para cada regla, se evalua la condicion contra el nuevo precio
4. Si la condicion se cumple, se publica `AlertRuleTriggered`
5. Los handlers crean `AlertEvent` y `Notification`

Esto necesita un Domain Service dedicado:
```
app/domain/alert_evaluator.rb
  - evaluate(asset, new_price) → [triggered_rules]
  - Encapsula la logica de cada condicion (price above, below, % change, RSI)
  - Puro (sin side effects), recibe datos y retorna resultado
```

---

## 4. UX Designer — Evaluacion de Experiencia

### Lo que esta bien

Los disenos son profesionales, con buena jerarquia visual y uso consistente de color (primary #004a99 para acciones, emerald para positivo, red para negativo). Las KPI cards son claras. Las tablas tienen buena densidad de datos. La separacion de layouts (public, app, admin, legal) es correcta.

### Problemas de Consistencia y Gaps

#### 4.1 Navegacion autenticada inconsistente

Cada pagina tiene diferentes items en la nav:
- **Dashboard:** Dashboard, Watchlist, News, Portfolio
- **Market Explorer:** Markets, Indices, Portfolio, News
- **Portfolio:** Dashboard, Portfolio, Market, Watchlist
- **Alerts:** Dashboard, Watchlist, Alerts, Portfolio
- **Earnings:** Dashboard, Markets, Portfolio, Earnings, News
- **Profile:** Dashboard, Market, Profile, News

**Propuesta de nav unificada:**
```
[Logo] [Dashboard] [Markets] [Portfolio] [Alerts] [Earnings]  [🔍] [🔔] [Avatar▾]
```
- 5 items fijos en la nav principal
- News accesible desde Dashboard (feed) y desde dropdown del avatar
- Profile accesible desde dropdown del avatar
- Watchlist integrada en Dashboard y Profile (no es una pagina separada)

#### 4.2 No hay sistema de feedback visual

Los disenos no muestran:

| Estado | Donde Falta | Solucion |
|--------|-------------|----------|
| **Toast/Flash** | Despues de crear alerta, actualizar perfil, etc. | Toast en esquina superior derecha, auto-dismiss 5s |
| **Loading** | Dentro de Turbo Frames al filtrar/paginar | Skeleton loader o spinner dentro del frame |
| **Error inline** | Formularios (Create Alert, Profile, Login) | Mensajes bajo cada campo con borde rojo |
| **Confirmacion** | Eliminar alerta, cerrar posicion, suspend user | Modal de confirmacion con explicacion |
| **Success inline** | Toggle de preferencias, toggle de asset status | Check animado al lado del toggle |
| **Empty** | Todas las listas cuando estan vacias | Ilustracion + texto + CTA (ver seccion 2.2) |

#### 4.3 Trend Explorer publico vs Market Explorer: overlap

El Trend Explorer publico (`/trends`) y el Market Explorer autenticado (`/market`) muestran ambos datos de assets con metricas. La diferencia no es clara para el usuario.

**Propuesta de unificacion:**
- `/trends` (publico) → Vista simplificada: top 10 trends, detalle de un asset, sin filtros avanzados. CTA "Sign up for full access"
- `/market` (autenticado) → Vista completa: todos los assets, filtros avanzados, export, agregar a watchlist
- El Trend Explorer es la "preview" del Market Explorer

#### 4.4 Admin sidebar no tiene indicadores de estado

El sidebar admin muestra "Assets", "Logs", "Users", "Integrations" pero no indica:
- Cuantas alertas/issues hay (badge rojo en "Assets" si hay sync issues)
- Si hay errores recientes en logs (badge en "Logs")
- Usuarios pendientes de revision (badge en "Users")

Esto ayudaria al admin a priorizar que revisar primero.

---

## 5. Security Engineer — Evaluacion de Seguridad

### Lo que esta bien

La decision de usar `has_secure_password` nativo es correcta (bcrypt, probado, simple). La separacion AuthenticatedController → Admin::BaseController es limpia. dry-validation como primera linea de defensa es excelente. Rails credentials para API keys encriptadas es correcto.

### Vulnerabilidades y Mejoras

#### 5.1 "Remember me" necesita implementacion segura

El diseno muestra "Remember me for 30 days". Extender la cookie de sesion 30 dias no es suficiente.

**Implementacion segura:**
```
RememberToken
  id, user_id
  token_digest: string (bcrypt del token)
  expires_at: datetime
  last_used_at: datetime
  ip_address: string
  user_agent: string
```

- Al marcar "remember me", generar token random, guardar digest en BD, enviar token en cookie signed+encrypted
- En cada request sin sesion, verificar cookie → buscar token → autenticar → rotar token
- Revocar todos los tokens al cambiar password

#### 5.2 Admin actions sin audit trail con actor

`SystemLog` registra operaciones del sistema pero no quien las ejecuto. Las acciones de admin (suspend user, toggle asset, connect integration) son sensibles.

**Mejora:** Agregar `performed_by_user_id` a SystemLog. Cada Use Case de admin deberia crear un log con el admin que lo ejecuto.

Alternativamente, un modelo separado:
```
AuditLog
  id, user_id (quien ejecuto la accion)
  action: string ("admin.users.suspend", "admin.assets.toggle_status")
  auditable_type: string (polymorphic)
  auditable_id: bigint
  changes: jsonb (before/after)
  ip_address: string
  created_at: datetime
```

#### 5.3 API keys necesitan proteccion extra

El diseno muestra API keys enmascaradas con boton "reveal" (ojo). El reveal deberia:
1. Requerir confirmacion de password del admin
2. Registrarse en audit log
3. Las keys solo se muestran completas al momento de crearlas ("Copy now, you won't see this again")

#### 5.4 Rate limiting necesario

Endpoints vulnerables a brute force:
- `POST /login` — Rate limit: 5 intentos por IP por minuto
- `POST /register` — Rate limit: 3 registros por IP por hora
- `POST /password/reset` — Rate limit: 3 por email por hora

Rails 8 tiene `rate_limit` built-in en controllers:
```ruby
class SessionsController < ApplicationController
  rate_limit to: 5, within: 1.minute, only: :create
end
```

#### 5.5 IDOR en recursos de usuario

Cada Use Case que accede a recursos del usuario debe verificar ownership. Los Use Cases actuales lo hacen bien (`user.alert_rules.find_by(id:)`), pero deberia haber un test explicito para cada uno que verifique que un usuario no puede acceder a recursos de otro.

---

## 6. QA Engineer — Evaluacion de Testabilidad

### Lo que esta bien

La arquitectura es altamente testeable. Los Use Cases son clases puras que reciben parametros y retornan Result — perfectos para unit tests. Los Contracts se testean de forma aislada. La separacion de concerns facilita mocking.

### Sugerencias

#### 6.1 Test matrix para Use Cases

Cada Use Case deberia tener al menos estos tests:

```
describe Alerts::CreateRule do
  context "with valid params" do
    it "returns Success with alert rule"
    it "publishes AlertRuleCreated event"
    it "persists the alert rule in DB"
  end

  context "with invalid params" do
    it "returns Failure(:validation, errors) for missing ticker"
    it "returns Failure(:validation, errors) for invalid condition"
  end

  context "authorization" do
    it "only creates rules for the given user"
    it "respects Basic tier limits (3 rules max)"
  end
end
```

#### 6.2 Factories prioritarias

Las primeras factories a crear (bloquean todo lo demas):
1. `user` (con traits `:admin`, `:premium`, `:suspended`, `:with_portfolio`)
2. `asset` (con traits `:stock`, `:crypto`, `:index`, `:with_trend_score`)
3. `portfolio` (con trait `:with_positions`)
4. `position` (con traits `:open`, `:closed`, `:international`)
5. `alert_rule` (con traits `:active`, `:paused`)

#### 6.3 Request specs para Turbo Streams

Los Turbo Stream responses necesitan assertions especificas:
```ruby
it "prepends alert rule via turbo stream" do
  post alerts_path, params: { alert: valid_params }
  expect(response.body).to include('turbo-stream action="prepend" target="alert_rules"')
end
```

---

## 7. Data Engineer — Evaluacion de Integraciones

### Gaps en el pipeline de datos

#### 7.1 No hay estrategia de sync definida

Los Gateways estan diseñados pero no hay definicion de:
- Frecuencia de sync por tipo de asset (stocks: cada 15min durante market hours, crypto: cada 5min 24/7)
- Estrategia de backfill para historico de precios
- Manejo de market hours (no sincronizar stocks de NYSE fuera de 9:30-16:00 ET)
- Prioridad de sync (assets en watchlists de usuarios primero)

#### 7.2 Falta circuit breaker en Gateways

Si Polygon.io cae, no deberia cascadear a toda la app. Cada Gateway necesita:
- Timeout: 5 segundos
- Retry: 2 intentos con exponential backoff
- Circuit breaker: si 5 requests fallan en 1 minuto, abrir circuito por 5 minutos
- Fallback: usar ultimo precio conocido (`current_price` en Asset)

#### 7.3 Caching de API responses

Las APIs de mercado tienen rate limits estrictos (Polygon free: 5 calls/min). Se necesita:
- Cache en Solid Cache con TTL por tipo: precios (60s), fundamentals (24h), earnings (1h)
- Un Use Case de sync no deberia llamar a la API si el cache es valido

---

## 8. DevOps Engineer — Evaluacion de Infraestructura

### Sugerencia unica relevante

#### 8.1 Jobs de sync necesitan scheduling

Solid Queue soporta recurring jobs pero no estan configurados:

```yaml
# config/recurring.yml
sync_stock_prices:
  class: SyncAssetsJob
  args: [stocks]
  schedule: every 15 minutes
  description: "Sync stock prices during market hours"

sync_crypto_prices:
  class: SyncAssetsJob
  args: [crypto]
  schedule: every 5 minutes
  description: "Sync crypto prices 24/7"

refresh_fx_rates:
  class: RefreshFxRatesJob
  schedule: every hour
  description: "Refresh FX rates"

snapshot_portfolios:
  class: SnapshotPortfoliosJob
  schedule: every day at 23:59 UTC
  description: "Daily portfolio value snapshot"

check_alerts:
  class: CheckAlertsJob
  schedule: every 5 minutes
  description: "Evaluate active alert rules"

cleanup_old_logs:
  class: CleanupLogsJob
  schedule: every day at 03:00 UTC
  description: "Remove system logs older than 90 days"
```

---

## 9. Mesa Redonda — Discusion Cruzada

### Financial Expert → Architect:
> "El evento `AssetPriceUpdated` es el heartbeat del sistema. Sin el, ni las alertas ni los dashboards en vivo tienen sentido. Deberia ser la primera pieza de event-driven que se implemente."

### Architect → Financial Expert:
> "Coincido. Propongo que el flujo sea: `SyncAssetsJob → AssetPriceUpdated → AlertEvaluator (domain service) → AlertRuleTriggered → CreateAlertEvent + CreateNotification + TurboStreamBroadcast`. Cada paso es un handler separado."

### Product → UX:
> "El onboarding es mas critico que cualquier feature nueva. Sin el, nadie llega a usar las alertas ni el calendario. Necesitamos disenar el wizard y los empty states ANTES de implementar features nuevas."

### UX → Product:
> "Los empty states son baratos de implementar pero tienen impacto enorme. Cada pagina vacia con un buen CTA es un mini-onboarding. Deberian ser parte de la Fase 3 (vistas estaticas), no dejarlo para despues."

### Security → Architect:
> "Cada Use Case de admin necesita un audit log. Sugiero que el `ApplicationUseCase` tenga un hook `after_success` que los Use Cases de admin sobrescriban para loguear la accion."

### Financial Expert → Product:
> "Los limites de Basic vs Premium tienen sentido, pero cuidado con limitar demasiado el watchlist a 5 items. Un trader casual sigue al menos 10-15 stocks. Sugiero 10 para Basic y ilimitado para Premium."

### QA → Todos:
> "Prioricen factories de User y Asset antes de cualquier otra cosa. Esas dos entidades son dependencias de todo lo demas. Y por favor, agreguen el modelo Trade desde el principio — retrofitearlo despues es doloroso."

### Data Engineer → Product:
> "La busqueda global es un feature que requiere que tengamos Assets en BD primero. Sugiero que el seed de assets sea robusto (al menos 50 assets reales) para que la busqueda y los filtros tengan sentido desde el dia 1."

### QA → Architect (sobre naming):
> "README.md seccion 7.2 llama al modelo 'Watchlist (join table)' pero DATABASE_SCHEMA.md, TECHNICAL_SPEC.md y COMMANDS.md todos usan 'WatchlistItem'. La migracion crea `watchlist_items`, el modelo es `WatchlistItem`. Si no alineamos nombres antes de implementar, vamos a tener bugs de naming en vistas, rutas y tests desde el dia 1."

### Architect → Rails Engineer (sobre IntegrationsController):
> "Las rutas en README definen `resources :integrations` como recurso separado bajo `admin`, pero la seccion de controladores NO lista un `Admin::IntegrationsController` — las integraciones se renderizan dentro de `Admin::UsersController#index`. TECHNICAL_SPEC tampoco lista un controller separado. Necesitamos decidir: si son independientes, crear el controller. Si son combinados, eliminar la ruta independiente y usar un partial dentro de Users."

### Rails Engineer → QA (sobre AlertEvent):
> "La definicion de AlertEvent en README seccion 7.2 no tiene `user_id`, pero la migracion en DATABASE_SCHEMA si lo tiene (`t.references :user, null: false`). Sin user_id no puedes filtrar eventos por usuario — basicamente el Live Feed no funcionaria. Cualquier factory o test que se escriba contra el README va a fallar contra el schema real."

### Hotwire Engineer → Product (sobre layouts):
> "README dice 'Se necesitan 5 layouts' pero luego lista 6 secciones (3.1 a 3.6). Son 5 layouts especificos + 1 base (`application.html.erb`). Si alguien implementa literalmente '5 layouts' podria omitir uno. Hay que corregir el texto."

### Security → Product (sobre password reset):
> "El PRD menciona 'Forgot password?' y DATABASE_SCHEMA tiene campos `password_reset_token` y `password_reset_sent_at` en User. Pero README no define ni ruta, ni controlador, ni vista para password reset. Esto no es un gap de feature — es un gap de documentacion. El flujo existe en la especificacion pero no en el mapa de implementacion."

### UX → Architect (sobre admin sidebar):
> "README seccion 3.5 lista items del sidebar admin: Assets, Logs, Users, Integrations, **Settings, Support**. Pero no existe ningun controlador, vista, ruta ni diseno para Settings ni Support en ningun documento. Son menu items fantasma que van a confundir al implementar. O los definimos o los eliminamos del sidebar."

---

## 10. Recomendaciones Consolidadas y Priorizadas

### Tier 0: Correcciones de Documentacion (inconsistencias que bloquean implementacion correcta)

> Estas NO son sugerencias de mejora — son errores y contradicciones entre los documentos existentes que deben corregirse ANTES de implementar. Un desarrollador que siga README.md al pie de la letra producira codigo incorrecto en estos puntos.

| # | Inconsistencia | Documentos Afectados | Experto(s) | Correccion |
|---|----------------|---------------------|------------|------------|
| 0.1 | **Modelo "Watchlist" vs "WatchlistItem"** — README sec. 7.2 usa "Watchlist (join table)" pero la migracion, modelo y todos los demas docs usan "WatchlistItem" | README ↔ DATABASE_SCHEMA, TECHNICAL_SPEC, COMMANDS | QA + Architect | Renombrar a "WatchlistItem" en README sec. 7.2 |
| 0.2 | **`Admin::IntegrationsController` — rutas vs vistas contradictorias** — README sec. 6 define `resources :integrations` como recurso separado, pero sec. 5.3 NO lista controller separado (se renderiza dentro de `Admin::UsersController#index`). TECHNICAL_SPEC tampoco lo lista | README interno (sec. 6 vs sec. 5.3), TECHNICAL_SPEC | Architect + Rails Engineer | Decidir: si es separado, documentar el controller. Si es combinado, eliminar ruta independiente y usar nested route o partial |
| 0.3 | **`AlertEvent` sin `user_id` en README** — README sec. 7.2 define AlertEvent sin campo `user_id`, pero DATABASE_SCHEMA migracion 2.7 tiene `t.references :user, null: false` y el modelo tiene `belongs_to :user` | README ↔ DATABASE_SCHEMA | Rails Engineer + QA | Agregar `user_id` (FK, not null) a la definicion de AlertEvent en README sec. 7.2 |
| 0.4 | **Admin sidebar con paginas fantasma** — README sec. 3.5 lista menu items "Settings" y "Support" que no tienen controlador, vista, ruta ni diseno en NINGUN documento | README (sin correspondencia) | UX + Product | Eliminar "Settings" y "Support" del sidebar, o definir controladores/vistas para ellos |
| 0.5 | **"5 layouts" pero son 6** — README sec. 3 dice "Se necesitan 5 layouts" pero lista secciones 3.1 a 3.6 (6 layouts incluyendo `application.html.erb` base) | README interno | Hotwire Engineer | Corregir texto: "Se necesitan 6 archivos de layout: 1 base + 5 especificos" |
| 0.6 | **Password reset: flujo fantasma** — PRD F-002 menciona "Forgot password?", DATABASE_SCHEMA tiene `password_reset_token` y `password_reset_sent_at` en User, pero README no define ruta, controlador ni vista para el flujo | PRD + DATABASE_SCHEMA ↔ README | Security + Rails Engineer | Agregar a README: `PasswordResetsController` con rutas `GET/POST /forgot-password` y `GET/PATCH /reset-password/:token` |
| 0.7 | **Schema drift: campos faltantes en README** — README sec. 7.2 define modelos con menos campos que DATABASE_SCHEMA | README ↔ DATABASE_SCHEMA | Rails Engineer | Sincronizar campos (ver tabla abajo) |
| 0.8 | **Partials criticos no listados** — `_flash.html.erb` y `_confirm_dialog.html.erb` se usan en TECHNICAL_SPEC (Turbo Streams, Stimulus `confirm` controller) pero no aparecen en la tabla de partials de README sec. 4 | README ↔ TECHNICAL_SPEC | Hotwire Engineer | Agregar ambos partials a la tabla de shared partials en README sec. 4.1 |

**Detalle de 0.7 — Campos faltantes por modelo:**

| Modelo en README | Campo(s) faltantes | Presente en DATABASE_SCHEMA |
|-----------------|--------------------|-----------------------------|
| User | `password_reset_token`, `password_reset_sent_at` | Migracion 2.1 |
| NewsArticle | `url` | Migracion 2.10 |
| EarningsEvent | `actual_eps` | Migracion 2.9 |
| MarketIndex | `exchange`, `is_open` | Migracion 2.11 |
| SystemLog | `log_uid` | Migracion 2.13 |

> **Fuente de verdad:** DATABASE_SCHEMA.md tiene las definiciones mas completas. README sec. 7.2 deberia actualizarse para reflejar el schema real, o eliminarse a favor de una referencia directa a DATABASE_SCHEMA.md.

### Tier 1: Critico (bloquea el exito del producto)

| # | Recomendacion | Experto(s) | Razon |
|---|---------------|------------|-------|
| 1 | **Disenar e implementar empty states** para todas las paginas | Product + UX | Sin esto, usuarios nuevos ven pantallas vacias y abandonan |
| 2 | **Agregar modelo `Trade`** (buy/sell transactions) | Financial + QA | Sin esto, Portfolio no puede calcular P&L correctamente |
| 3 | **Agregar modelo `Notification`** con panel en navbar | Product | Sin esto, las alertas no llegan al usuario dentro de la app |
| 4 | **Implementar evento `AssetPriceUpdated`** como trigger central | Architect + Financial | Es el heartbeat del sistema, conecta Market Data → Alerts → Dashboard |
| 5 | **Agregar modelo `PortfolioSnapshot`** + job diario | Financial | El dashboard dice "+1.2% today" pero no puede calcularlo sin esto |
| 6 | **Onboarding wizard** post-registro (3 pasos) | Product | Sin esto, la tasa de activacion sera < 10% |

### Tier 2: Alto (mejora significativamente el producto)

| # | Recomendacion | Experto(s) | Razon |
|---|---------------|------------|-------|
| 7 | **Definir limites concretos Basic vs Premium** | Product + Financial | Necesario para monetizacion desde v1 |
| 8 | **Crear pagina de Pricing** | Product + UX | La landing page apunta a ella pero no existe |
| 9 | **Agregar tabla `FxRate`** con job de refresh | Financial + Data | Multi-divisa no funciona sin tasas reales |
| 10 | **Agregar `AssetPriceHistory`** + backfill | Financial + Data | Graficos, sparklines y RSI necesitan historico |
| 11 | **Unificar la navegacion** autenticada | UX | Cada pagina tiene nav diferente, confunde al usuario |
| 12 | **Agregar `AuditLog`** para acciones de admin | Security | Compliance y trazabilidad de acciones sensibles |
| 13 | **Rate limiting** en login, register, password reset | Security | Proteccion basica contra brute force |
| 14 | **Domain Service `AlertEvaluator`** | Architect | Encapsula logica compleja de evaluacion de condiciones |
| 15 | **EventBus con soporte async** (via Solid Queue) | Architect | Handlers pesados no deben bloquear el request |

### Tier 3: Medio (complementa y mejora la experiencia)

| # | Recomendacion | Experto(s) | Razon |
|---|---------------|------------|-------|
| 16 | **Modelo `Dividend` + `DividendPayment`** | Financial | Completa el tab "Dividend History" del diseno |
| 17 | **Pagina de News** independiente (`/news`) | Product | Valor agregado para traders, ya referenciada en nav |
| 18 | **Busqueda global** (assets + news, dropdown con Stimulus) | Product + UX | Feature esperada, search bar ya visible en todos los disenos |
| 19 | **Separar BC "Market Intelligence"** en 4 contextos | Architect | Mejor mantenibilidad cuando crezcan las integraciones |
| 20 | **`entry_price` en WatchlistItem** | Financial | Contexto valioso, capturado automaticamente sin esfuerzo |
| 21 | **Admin sidebar con badges** de issues/alertas | UX | Ayuda al admin a priorizar |
| 22 | **Mobile-responsive** desde Fase 1 | Product + UX | 60%+ de traders son mobile |
| 23 | **Remember me seguro** con token rotativo | Security | La implementacion naive tiene vulnerabilidades |
| 24 | **Circuit breaker** en Gateways | Data | Previene cascada de fallos si una API cae |
| 25 | **Solid Queue recurring jobs** configurados | DevOps | Todo el pipeline de sync depende de esto |
| 26 | **Seeds con 50+ assets reales** | Data + QA | Busqueda y filtros necesitan datos para tener sentido |
| 27 | **Market Sentiment** calculado desde trend scores del watchlist | Financial | Dato visible en dashboard, necesita fuente |
| 28 | **Unificar Trend Explorer / Market Explorer** | UX | Reducir overlap, uno es la preview del otro |

---

## 11. Modelos Nuevos Propuestos (Resumen)

Modelos que deberian agregarse al DATABASE_SCHEMA.md:

| Modelo | BC | Prioridad | Campos Clave |
|--------|----|-----------|-------------|
| `Trade` | Trading | Critico | portfolio_id, asset_id, side, shares, price_per_share, fee, currency, executed_at |
| `Notification` | Identity | Critico | user_id, title, body, notification_type, read, notifiable (poly), created_at |
| `PortfolioSnapshot` | Trading | Critico | portfolio_id, date, total_value, cash_value, invested_value |
| `FxRate` | Market Data | Alto | base_currency, quote_currency, rate, fetched_at |
| `AssetPriceHistory` | Market Data | Alto | asset_id, date, open, high, low, close, volume |
| `AuditLog` | Administration | Alto | user_id, action, auditable (poly), changes (jsonb), ip_address |
| `Dividend` | Market Data | Medio | asset_id, ex_date, pay_date, amount_per_share, currency |
| `DividendPayment` | Trading | Medio | portfolio_id, dividend_id, shares_held, total_amount |
| `RememberToken` | Identity | Medio | user_id, token_digest, expires_at, last_used_at, ip_address |

---

## 12. Eventos Nuevos Propuestos (Resumen)

| Evento | Trigger | Handlers Sugeridos |
|--------|---------|--------------------|
| `AssetPriceUpdated` | SyncAssetsJob | EvaluateAlertRules, BroadcastToOpenDashboards |
| `TradeExecuted` | Positions::OpenPosition | RecalculateAvgCost, UpdatePortfolioValue, LogActivity |
| `PasswordChanged` | Profiles::ChangePassword | InvalidateOtherSessions, SendConfirmationEmail, AuditLog |
| `ProfileUpdated` | Profiles::UpdateInfo | AuditLog |
| `PortfolioSnapshotTaken` | SnapshotPortfoliosJob | (ninguno, es dato) |
| `NotificationCreated` | Handlers de otros eventos | BroadcastToNavbar (Turbo Stream) |
| `FxRatesRefreshed` | RefreshFxRatesJob | BroadcastToMultiCurrencyDashboards |
| `CsvExported` | Use Cases de export | AuditLog |

---

## 13. Fases de Implementacion Revisadas

Basado en las sugerencias, las fases del README.md deberian ajustarse:

### Fase 0: Setup Base (sin cambios)
- Tailwind, Material Symbols, Inter, layouts, partials

### Fase 1: Paginas Publicas (sin cambios + Pricing)
- Landing, Legal, Open Source, Trend Explorer
- **NUEVO: Pagina de Pricing**

### Fase 2: Autenticacion (sin cambios + remember me)
- Login/Registro con has_secure_password
- **NUEVO: Remember me seguro**
- **NUEVO: Rate limiting en login/register**

### Fase 3: Vistas Estaticas + Empty States
- Dashboard, Market, Portfolio, Alerts, Earnings, Profile
- **NUEVO: Empty states para TODAS las paginas**
- **NUEVO: Onboarding wizard (3 pasos post-registro)**
- **NUEVO: Nav unificada**

### Fase 4: Admin (sin cambios + audit log)
- Assets, Logs, Users/Integrations
- **NUEVO: AuditLog para acciones de admin**
- **NUEVO: Sidebar con badges de issues**

### Fase 5: Modelos y Seeds (expandida)
- Todos los modelos originales
- **NUEVO: Trade, PortfolioSnapshot, FxRate, AssetPriceHistory**
- **NUEVO: Notification, AuditLog**
- **NUEVO: Dividend, DividendPayment (si hay tiempo)**
- Seeds con 50+ assets reales

### Fase 6: Backend (expandida)
- CRUD original (watchlist, alerts, profile)
- **NUEVO: AssetPriceUpdated event + AlertEvaluator**
- **NUEVO: Notification system con Turbo Stream broadcast**
- **NUEVO: Feature gating Basic vs Premium**
- **NUEVO: Portfolio snapshots diarios**
- **NUEVO: Busqueda global**
- **NUEVO: Pagina de News**

### Fase 7: Integraciones (nueva)
- Polygon.io Gateway funcional
- CoinGecko Gateway funcional
- FX Rates Gateway
- Solid Queue recurring jobs
- Circuit breakers y caching

---

## 14. Que Eliminarian o Cambiarian de lo Ya Definido

Los expertos tambien identificaron elementos en los documentos actuales que deberian eliminarse, simplificarse o replantearse:

### 14.1 Eliminar o Diferir

| Que | Donde esta | Recomendacion | Experto | Razon |
|-----|-----------|---------------|---------|-------|
| **`dry-initializer` gem** | TECHNICAL_SPEC.md (gems) | **Eliminar** | Architect | No se usa en ningun Use Case definido. Los Use Cases usan `self.call(...)` directamente, no necesitan inicializadores declarativos. Agrega una dependencia sin valor. |
| **`Ransack` gem** | TECHNICAL_SPEC.md (gems) | **Diferir a Fase 6** | Rails Engineer | Para las primeras fases con datos hardcodeados, los filtros se pueden implementar con scopes simples de ActiveRecord. Ransack agrega complejidad y surface de ataque (SQL injection si no se configura correctamente). Agregarlo solo cuando los filtros reales sean necesarios. |
| **`repositories/` carpeta completa** | TECHNICAL_SPEC.md (estructura) | **Eliminar en v1** | Architect + Rails Engineer | En Rails, ActiveRecord YA es el repository pattern. Crear `UserRepository`, `AssetRepository`, etc. que solo wrappean `User.find`, `Asset.where` es una abstraccion prematura que duplica codigo sin beneficio. Los Use Cases pueden usar los modelos directamente como driven adapters. Introducir repositories solo si se necesita cambiar de ORM o para queries muy complejas. |
| **Callbacks `after_create` en User** | DATABASE_SCHEMA.md (modelo User) | **Eliminar** | Architect | Crear Portfolio y AlertPreference via callbacks viola DDD — son side effects que deberian vivir en event handlers de `UserRegistered`. Ya estan modelados correctamente en COMMANDS.md como handlers. Los callbacks en el modelo crean acoplamiento invisible. |
| **`PortfolioAllocation` como concepto separado** | README.md (modelo propuesto) | **Eliminar** | Financial + Architect | No necesita tabla propia. La allocation se calcula on-the-fly desde las posiciones abiertas (`portfolio.allocation_by_sector`). Es un calculo, no una entidad. Mantenerlo como metodo en el Domain Service `PortfolioSummary`. |
| **Pagina Open Source como prioridad** | README.md (Fase 1) | **Diferir a Fase 4+** | Product | No contribuye a la activacion ni retencion de usuarios. Es una pagina de marketing para desarrolladores, no para traders. Implementarla despues de que el producto core funcione. |
| **Dark mode support** | TECHNICAL_SPEC.md (notas) | **Diferir a post-v1** | UX + Product | Los HTMLs de Stitch incluyen clases de dark mode pero implementarlo correctamente (toggle, persistencia, consistencia en 18 paginas) es esfuerzo significativo sin impacto en la funcionalidad core. Mejor hacerlo bien despues que hacerlo a medias ahora. |

### 14.2 Simplificar

| Que | Donde esta | Recomendacion | Experto | Razon |
|-----|-----------|---------------|---------|-------|
| **Dashboard Multidivisa como pagina separada** | README.md (pagina 9) | **Fusionar con Dashboard Principal** | UX + Product | Son la misma pagina. La unica diferencia es un selector de divisa en el header. No necesita una ruta ni vista separada — es el mismo `DashboardController#show` con un parametro `currency`. Eliminar como pagina separada del mapa. |
| **Portfolio Multidivisa como pagina separada** | README.md (pagina 12) | **Fusionar con Portfolio** | UX + Product | Misma razon. Es el mismo `PortfolioController#show` con posiciones que tienen diferentes currencies. No necesita vista separada. |
| **`TrendsController` + `MarketController` como controllers separados** | TECHNICAL_SPEC.md | **Evaluar fusionar** | Architect + UX | El Trend Explorer publico (`/trends`) y el Market Explorer autenticado (`/market`) muestran assets con metricas. El Trend Explorer podria ser simplemente el Market Explorer sin autenticacion, con filtros limitados y un CTA "Sign up for full access". Un solo `MarketController` con `before_action :require_authentication, except: [:public_index]`. |
| **6 Bounded Contexts → 5 suficientes para v1** | COMMANDS.md | **Fusionar Watchlist en Trading** | Architect + Financial | Watchlist (add/remove asset) es tan simple (2 Use Cases, 1 modelo) que no justifica su propio Bounded Context. En la practica, watchlist es parte de la experiencia de Trading del usuario. Fusionarlo simplifica la arquitectura sin perdida de claridad. |
| **Los 5 layouts separados** | README.md / TECHNICAL_SPEC.md | **Reducir a 4** | Hotwire Engineer | `auth.html.erb` es usado solo por la pagina de login/registro. Es una card centrada con header minimo. Se puede lograr con el layout `public` + una clase CSS en el body (o un `content_for :body_class`). No justifica un layout completo propio. |
| **Event Handlers como carpetas separadas por evento** | TECHNICAL_SPEC.md (event_handlers/) | **Simplificar a clases planas** | Architect | `on_user_registered/create_portfolio.rb`, `on_user_registered/create_alert_preferences.rb` es demasiada estructura para handlers de 5 lineas. Mejor: `event_handlers/create_portfolio_on_registration.rb`. Un archivo por handler, nombre descriptivo, sin carpetas anidadas. |

### 14.3 Replantear

| Que | Donde esta | Recomendacion | Experto | Razon |
|-----|-----------|---------------|---------|-------|
| **`Position` con `avg_cost` directo** | DATABASE_SCHEMA.md | **Replantear como campo calculado** | Financial | Si se agrega el modelo `Trade`, el `avg_cost` de Position deberia ser calculado (`SUM(shares*price)/SUM(shares)` de los trades de compra). No deberia ser un campo manual — se puede mantener como campo en BD pero actualizarlo via callback o Use Case cada vez que se agrega un Trade, para performance. |
| **`current_price` en Asset** | DATABASE_SCHEMA.md | **Replantear origen** | Data + Financial | Actualmente `current_price` es un campo en Asset que se actualiza via sync. Esto esta bien, pero debe quedar claro que es un cache del ultimo precio conocido, no el precio "real-time". Agregar campo `price_updated_at` para saber la frescura del dato. Mostrar en UI "as of 2 min ago" cuando no sea real-time. |
| **Social auth (Google, Apple) como placeholder** | PRD.md (F-002) | **Eliminar de v1 completamente** | Security + Product | Botones de social auth que no funcionan generan frustacion y desconfianza. Mejor no mostrarlos hasta que funcionen. En v1, solo email/password. Agregar social auth en v2 cuando se tenga OAuth configurado. |
| **`SystemLog` para todo** | DATABASE_SCHEMA.md | **Separar system logs de audit logs** | Security + Architect | Actualmente `SystemLog` mezcla operaciones del sistema (FX Rate Update, Shopify Sync) con lo que deberian ser audit logs de admin (suspend user, toggle asset). Son conceptos diferentes: uno es observabilidad, otro es compliance. Mantener `SystemLog` para operaciones tecnicas y crear `AuditLog` para acciones de usuario/admin. |
| **El nombre "Stockerly" vs "Stockerly"** | General | **Decidir uno** | Product | El repo se llama `stockerly`, los disenos dicen `Stockerly`. Esto crea confusion. Decidir el nombre definitivo y ser consistente en toda la documentacion y el codigo. |

### 14.4 Resumen de Impacto en Documentos

Si se aplican estas sugerencias (incluyendo las correcciones de consistencia del Tier 0), los documentos cambiarian asi:

**README.md (correcciones de consistencia — Tier 0):**
- Corregir "Watchlist" → "WatchlistItem" en sec. 7.2
- Agregar `user_id` a AlertEvent en sec. 7.2
- Decidir y alinear `Admin::IntegrationsController` (sec. 5.3 vs sec. 6)
- Eliminar "Settings" y "Support" del sidebar admin (sec. 3.5) o definirlos
- Corregir "5 layouts" → "6 archivos de layout (1 base + 5 especificos)" en sec. 3
- Agregar `PasswordResetsController` con rutas a sec. 5.1 y sec. 6
- Sincronizar campos faltantes en sec. 7.2 con DATABASE_SCHEMA.md (ver Tier 0.7)
- Agregar `_flash.html.erb` y `_confirm_dialog.html.erb` a tabla de partials en sec. 4.1

**README.md (mejoras — sugerencias originales):**
- Eliminar paginas 9 (Dashboard Multidivisa) y 12 (Portfolio Multidivisa) como paginas separadas — son variantes del mismo controller
- Diferir pagina 4 (Open Source) a fases posteriores
- Reducir de 18 a 16 paginas unicas (+1 nueva: Pricing = 17 total)

**TECHNICAL_SPEC.md:**
- Eliminar `dry-initializer` de gems
- Mover `ransack` a "agregar en Fase 6"
- Eliminar carpeta `repositories/`
- Simplificar `event_handlers/` a archivos planas
- Reducir layouts de 5 a 4 (eliminar `auth`)
- Agregar `price_updated_at` a Asset

**DATABASE_SCHEMA.md:**
- Agregar modelos: Trade, Notification, PortfolioSnapshot, FxRate, AssetPriceHistory, AuditLog, Dividend, DividendPayment, RememberToken
- Eliminar callbacks `after_create` de User
- Eliminar `PortfolioAllocation` como concepto
- Agregar `price_updated_at` a Asset
- Separar `SystemLog` (tecnico) de `AuditLog` (acciones humanas)
- Replantear `avg_cost` en Position como campo calculado/cacheado

**COMMANDS.md:**
- Fusionar BC "Watchlist" en "Trading" (5 Bounded Contexts)
- Agregar Use Cases: ExecuteTrade, SnapshotPortfolio, EvaluateAlerts, CreateNotification
- Agregar Use Case: PasswordResets::RequestReset, PasswordResets::ExecuteReset
- Agregar Domain Service: AlertEvaluator
- Agregar eventos faltantes (AssetPriceUpdated, TradeExecuted, PasswordChanged, etc.)

**PRD.md:**
- Eliminar social auth de v1
- Agregar F-002b: Forgot Password / Reset Password (flujo completo)
- Agregar F-017: Pricing Page
- Agregar F-018: Onboarding Wizard
- Agregar F-019: Empty States
- Agregar F-020: Notification System
- Agregar F-021: News Page
- Agregar F-022: Global Search
- Definir limites concretos Basic vs Premium

---

## 15. Auditoria de Consistencia entre Documentos

> Esta seccion documenta las inconsistencias encontradas al cruzar los 6 documentos de especificacion (README.md, PRD.md, TECHNICAL_SPEC.md, DATABASE_SCHEMA.md, COMMANDS.md, EXPERTS.md) entre si y contra los archivos reales en disco. Cada hallazgo incluye el experto responsable de la correccion y la accion recomendada.
>
> **Nota:** Las correcciones de Tier 0 (sec. 10) son el extracto priorizado de esta auditoria. Esta seccion provee el detalle completo.

### 15.1 Inconsistencias Criticas (bloquean implementacion correcta)

#### IC-01: Naming del modelo Watchlist / WatchlistItem

| Aspecto | Detalle |
|---------|---------|
| **Problema** | README sec. 7.2 define el join table como "Watchlist" con campos `id, user_id, asset_id, created_at`. Todos los demas documentos usan "WatchlistItem" consistentemente. |
| **Donde aparece mal** | README.md sec. 7.2 (titulo "Watchlist (join table)"), sec. 7.1 ERD ("Watchlist (join)") |
| **Donde aparece bien** | DATABASE_SCHEMA.md (migracion `create_watchlist_items`, modelo `WatchlistItem`), TECHNICAL_SPEC.md (lista de modelos), COMMANDS.md (Use Cases `Watchlist::AddAsset`, `Watchlist::RemoveAsset` que operan sobre `WatchlistItem`), PRD.md (referencia CRUD watchlist), seeds (`WatchlistItem.create!`) |
| **Impacto** | Un desarrollador que siga README generaria `rails g model Watchlist` en lugar de `WatchlistItem`. Las rutas, vistas y tests fallarian contra el schema real. |
| **Experto** | QA + Architect |
| **Correccion** | Renombrar "Watchlist" → "WatchlistItem" en README sec. 7.1 y 7.2 |

#### IC-02: Admin::IntegrationsController — existencia contradictoria

| Aspecto | Detalle |
|---------|---------|
| **Problema** | README sec. 6 (rutas) define `resources :integrations, only: [:index, :create, :update, :destroy]` bajo `namespace :admin`. Pero README sec. 5.3 solo lista `Admin::UsersController` para esa pagina, con el contenido de integraciones embebido ("Usuarios (tabla) + Integraciones (cards)"). TECHNICAL_SPEC sec. 2.2 tampoco lista un `Admin::IntegrationsController`. |
| **Documentos en conflicto** | README sec. 5.3 (no existe controller separado) vs README sec. 6 (si existe ruta separada) vs TECHNICAL_SPEC sec. 2.2 (no existe controller) |
| **Impacto** | Si se implementan las rutas, Rails buscara `Admin::IntegrationsController` que no existe. Si se implementa el controller combinado, las rutas de integraciones generaran errores 404. |
| **Experto** | Architect + Rails Engineer |
| **Opciones** | **(A)** Crear `Admin::IntegrationsController` independiente con su propia vista `index.html.erb` y mantener las rutas. **(B)** Eliminar `resources :integrations` de las rutas y mantener todo dentro de `Admin::UsersController#index` con un partial `_integrations.html.erb`. **Recomendacion:** Opcion B — el diseno muestra ambas secciones en la misma pagina. |

#### IC-03: AlertEvent sin user_id en README

| Aspecto | Detalle |
|---------|---------|
| **Problema** | README sec. 7.2 define AlertEvent con campos `id, alert_rule_id, asset_symbol, message, event_status, triggered_at`. No incluye `user_id`. |
| **Donde esta correcto** | DATABASE_SCHEMA.md migracion 2.7: `t.references :user, null: false, foreign_key: true`. Modelo `AlertEvent` tiene `belongs_to :user`. Seeds: `AlertEvent.create!(user: alex, ...)`. |
| **Impacto** | Sin `user_id`, no se puede: (1) filtrar el Live Alert Feed por usuario, (2) asegurar que un usuario solo vea sus propios eventos, (3) implementar `user.alert_events` que ya esta definido en el modelo User. |
| **Experto** | Rails Engineer + Security (IDOR risk) |
| **Correccion** | Agregar `| user_id | bigint | FK, not null |` a la tabla de AlertEvent en README sec. 7.2 |

#### IC-04: Admin sidebar — items sin backing

| Aspecto | Detalle |
|---------|---------|
| **Problema** | README sec. 3.5 describe el sidebar admin con menu: "Assets, Logs, Users, Integrations, **Settings, Support**". No existe ningun controlador, ruta, vista, diseno (screen.png) ni mencion en PRD para "Settings" ni "Support" en zona admin. |
| **Documentos revisados** | README (rutas sec. 6 — no hay `/admin/settings` ni `/admin/support`), PRD (no hay F-xxx para admin settings/support), TECHNICAL_SPEC (no hay controller listado), designs/ (no hay carpeta admin settings/support) |
| **Impacto** | El implementador del sidebar creara links rotos o tendra que inventar paginas no especificadas. |
| **Experto** | UX + Product |
| **Opciones** | **(A)** Eliminar "Settings" y "Support" del sidebar — el admin ya tiene settings distribuidos en cada seccion (assets config, integration config, user management). **(B)** Definir que iria en estas paginas y agregarlas al PRD. **Recomendacion:** Opcion A para v1 — evitar scope creep. |

#### IC-05: Password reset — flujo definido en partes pero nunca integrado

| Aspecto | Detalle |
|---------|---------|
| **Problema** | El flujo de password reset esta parcialmente definido en 3 documentos diferentes pero nunca aparece completo en el mapa de implementacion. |
| **Donde aparece parcialmente** | PRD F-002: *"Forgot password? link"*. DATABASE_SCHEMA User: campos `password_reset_token` y `password_reset_sent_at`. TECHNICAL_SPEC: menciona rate limiting para `/password/reset`. |
| **Donde falta** | README sec. 5 (no hay `PasswordResetsController`), README sec. 6 (no hay rutas `/forgot-password`, `/reset-password/:token`), README sec. 8 (no aparece en ninguna fase de implementacion), COMMANDS.md (no hay Use Cases `PasswordResets::RequestReset`, `PasswordResets::ExecuteReset`) |
| **Impacto** | El formulario de login tendra un link "Forgot password?" que no lleva a ninguna parte. |
| **Experto** | Security + Rails Engineer |
| **Correccion** | Agregar a README: controlador, rutas (`GET/POST /forgot-password`, `GET/PATCH /reset-password/:token`), vista (form email → form new password). Agregar a COMMANDS.md los Use Cases correspondientes. Agregar a fases de implementacion (Fase 2). |

### 15.2 Inconsistencias Moderadas (causan confusion o implementacion incompleta)

#### IM-01: "5 layouts" pero hay 6 archivos

README sec. 3 dice textualmente "Se necesitan **5 layouts**" pero luego lista secciones 3.1 (`application.html.erb` base), 3.2 a 3.6 (public, auth, app, admin, legal) = 6 archivos. El numero correcto depende de como se cuente: 5 layouts especificos o 6 archivos totales.

**Correccion:** Cambiar texto a "Se necesitan **6 archivos de layout** en `app/views/layouts/`: 1 base y 5 especificos".

#### IM-02: Schema drift — README sec. 7.2 vs DATABASE_SCHEMA.md

README sec. 7.2 ("Propuesta de Modelado") define modelos con menos campos que DATABASE_SCHEMA.md. Esto indica que README se escribio primero y DATABASE_SCHEMA lo expandio sin sincronizar de vuelta.

**Campos divergentes:** 5 modelos con campos faltantes en README (User: 2 campos, NewsArticle: 1, EarningsEvent: 1, MarketIndex: 2, SystemLog: 1). Ver tabla completa en Tier 0.7.

**Recomendacion:** Eliminar la seccion 7.2 de README y reemplazarla con una referencia: *"Ver [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) para la definicion completa de todos los modelos."* Esto evita mantener dos fuentes de verdad para el mismo dato.

#### IM-03: Partials criticos no inventariados

README sec. 4 (Elementos Compartidos) lista partials de layout y componentes, pero omite dos partials criticos referenciados en otros documentos:

| Partial faltante | Referenciado en | Uso |
|-----------------|-----------------|-----|
| `_flash.html.erb` | TECHNICAL_SPEC sec. 5.3 (Turbo Streams: `turbo_stream.prepend "flash_messages"`) | Toast/flash messages con auto-dismiss. Usado en toda la app despues de cada accion. |
| `_confirm_dialog.html.erb` | TECHNICAL_SPEC sec. 5.4 (Stimulus controller `confirm`) | Modal de confirmacion para acciones destructivas (eliminar alerta, suspend user, etc.) |

**Correccion:** Agregar ambos a la tabla de partials en README sec. 4.1 (Partials de Layout).

#### IM-04: ERD del README incompleto

README sec. 7.1 muestra un diagrama ASCII de entidades que omite:
- La relacion `User 1:1 AlertPreference` (solo aparece en texto debajo, no en el diagrama)
- `NewsArticle` (aparece solo en la lista de modelos)
- `MarketIndex` (idem)

DATABASE_SCHEMA sec. 1 tiene un ERD mucho mas completo que incluye todas las entidades.

**Recomendacion:** Mismo que IM-02 — referir a DATABASE_SCHEMA.md como fuente de verdad para el ERD.

### 15.3 Inconsistencias Menores (no bloquean pero generan confusion)

#### Im-01: Carpeta `trendstocker_dashboard` — nombre confuso

**RESUELTO:** La carpeta ahora se llama `designs/public/trends/` (renombrada durante la reestructuracion). El dashboard real esta en `designs/app/dashboard/`. La confusion de nombres ya no existe.

**Impacto:** Bajo — un desarrollador podria abrir la carpeta equivocada al buscar el diseno del dashboard.

#### Im-02: TrendsController — layout potencialmente incorrecto

README asigna layout `public` al Trend Explorer. Pero el diseno visual (`trendstocker_dashboard/screen.png`) usa un tema oscuro con header y estructura visual diferentes al public header estandar (que es claro con nav horizontal).

**Recomendacion del Hotwire Engineer:** Verificar si el Trend Explorer necesita un variant del layout public o clases CSS condicionales para el tema oscuro. No es un error de documentacion — es una decision de implementacion pendiente.

#### Im-03: README no menciona Stimulus controllers

TECHNICAL_SPEC sec. 5.4 define 15 Stimulus controllers detallados con responsabilidades claras. README sec. 4 (Elementos Compartidos) no menciona ninguno. Esto deja un gap entre "que partials existen" y "como interactuan".

**Recomendacion:** No duplicar la lista en README (evitar drift). Agregar una nota en README sec. 4: *"Para Stimulus controllers, ver [TECHNICAL_SPEC.md sec. 5.4](TECHNICAL_SPEC.md)."*

#### Im-04: Fases de implementacion no mencionan background jobs

README sec. 8 (Fases de Implementacion) no incluye ninguna fase para configurar background jobs (SyncAssetsJob, CheckAlertsJob, etc.), a pesar de que TECHNICAL_SPEC sec. 9 los define y son criticos para que alertas, sync de precios y snapshots funcionen.

**Recomendacion:** Ya cubierto en la Fase 7 propuesta (sec. 13). Cuando se actualice README sec. 8, incluir la fase de integraciones y jobs.

#### Im-05: Sin paginas de error custom

Ningun documento define paginas de error (404 Not Found, 500 Internal Server Error, 403 Forbidden). Para una plataforma fintech, una experiencia de error consistente con el branding es relevante.

**Recomendacion del UX Designer:** Diferir a post-Fase 4. Usar las paginas default de Rails mientras tanto. Cuando se implementen, crear `public/404.html`, `public/500.html` con el branding de Stockerly.

#### Im-06: SUGGESTIONS.md no referenciado

`SUGGESTIONS.md` (este documento) no esta referenciado desde README.md, CLAUDE.md ni IDENTITY.md. Los demas documentos (PRD, TECHNICAL_SPEC, etc.) se referencian mutuamente pero este queda huerfano.

**Correccion:** Agregar a la tabla de documentos de referencia en CLAUDE.md e IDENTITY.md:

```
| Sugerencias de expertos | `docs/spec/SUGGESTIONS.md` | Evaluacion cruzada, gaps, recomendaciones priorizadas |
```
