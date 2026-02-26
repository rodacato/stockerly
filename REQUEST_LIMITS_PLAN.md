# Phase 15.6 — API Key Management & Provider Rate Limits

> **Fecha:** 2026-02-26
> **Estado:** Plan — pending approval
> **Prerequisito:** Phase 15.5 complete (1627 specs)

---

## Contexto

Phase 15.5 introdujo `ApiKeyPool` y `KeyRotation` a nivel modelo/dominio, pero no hay UI para gestionarlos. Además, el sistema actual de rate limits es reactivo (detecta HTTP 429 después del hecho) sin prevención proactiva por proveedor. Cada API tiene límites distintos que el sistema debería conocer y respetar.

---

## Consulta con el Panel de Expertos

### Domain Architect — Límites de Bounded Context

> El CRUD de ApiKeyPool pertenece al bounded context **Administration**. No cruza contextos: los gateways ya consumen keys via `KeyRotation` (output port), y el admin las gestiona (input port). El rate limiting proactivo debe vivir como **Domain Service** (`RateLimiter`) separado del `CircuitBreaker` existente — son concerns distintos:
> - **CircuitBreaker** protege contra fallos consecutivos (5xx, timeouts)
> - **RateLimiter** previene exceder cuotas conocidas (requests/interval)
>
> No deben fusionarse. El `RateLimiter` es stateless per-request (consulta contadores), el `CircuitBreaker` es stateful (mantiene estado open/closed).

### Data Engineer — Realidad de los Rate Limits por Proveedor

> Cada proveedor tiene límites radicalmente distintos:
>
> | Provider | Free Tier Limit | Interval | Notes |
> |----------|----------------|----------|-------|
> | **Polygon.io** | 5 req/min | Per minute | Basic plan. Starter: 100/min |
> | **CoinGecko** | 30 req/min | Per minute | Demo key. Pro: 500/min |
> | **Alpha Vantage** | 25 req/day | Per day | Also 5 req/min soft limit |
> | **ExchangeRate API** | 1,500 req/month | Per month | ~50/day |
> | **Yahoo Finance** | No official limit | — | Informal, ~2000/day safe |
> | **Banxico** | No published limit | — | Conservative: 100/day |
> | **Alternative.me** | No published limit | — | Conservative: 100/day |
>
> Lo crítico: no todos los proveedores usan la misma ventana de tiempo.
> Polygon y CoinGecko son per-minute, Alpha Vantage es per-day Y per-minute,
> ExchangeRate es per-month. El modelo necesita soportar **intervalos configurables**.

### Security Engineer — Gestión Segura de Keys

> Las API keys en el admin deben:
> 1. **Nunca mostrarse en claro** — solo masked (últimos 4 chars)
> 2. **No transmitirse en logs** ni en parámetros de URL
> 3. **El campo `name`** es buena práctica — identifica keys sin revelar el valor
> 4. **Soft delete** preferido sobre hard delete — audit trail para fintech
> 5. **Rate limit counters** no deben ser manipulables desde el frontend

### Rails Engineer — Implementación Pragmática

> El rate limiting no necesita Redis ni infraestructura adicional.
> Podemos usar los campos existentes de Integration (`daily_api_calls`, `daily_call_limit`)
> y extender con nuevos campos para granularidad por-minuto. Los contadores se
> resetean con la misma lógica del `reset_daily_counter!` existente.
>
> Para el pool CRUD, seguir el patrón existente: Use Case + Contract + Controller.
> La UI se integra en la página de admin existente como sección expandible per-integration.

---

## Diseño Técnico

### 1. Modelo de Rate Limits por Proveedor

Agregar campos a `integrations`:

```ruby
# Migration: add_rate_limit_fields_to_integrations
add_column :integrations, :max_requests_per_minute, :integer, default: nil
add_column :integrations, :max_requests_per_day, :integer, default: nil
add_column :integrations, :minute_calls, :integer, default: 0, null: false
add_column :integrations, :minute_reset_at, :datetime
```

**Razonamiento:** Los dos intervalos más comunes son per-minute y per-day. `daily_api_calls` y `daily_call_limit` ya existen para el daily. Agregamos `max_requests_per_minute` + `minute_calls` + `minute_reset_at` para el per-minute. Si un proveedor no tiene límite por minuto, `max_requests_per_minute` queda `nil` (sin restricción).

### 2. Modelo ApiKeyPool — Campo `name`

```ruby
# Migration: add_name_to_api_key_pools
add_column :api_key_pools, :name, :string, null: false, default: "Default"
```

### 3. Domain Service: `RateLimiter`

```ruby
# app/domain/rate_limiter.rb
class RateLimiter
  include Dry::Monads[:result]

  # Returns Success(:allowed) or Failure([:rate_limited, message])
  def self.check!(provider_name)
    integration = Integration.find_by(provider_name: provider_name)
    return Success(:allowed) unless integration

    # Check per-minute limit
    if integration.max_requests_per_minute.present?
      integration.reset_minute_counter! if minute_window_expired?(integration)
      if integration.minute_calls >= integration.max_requests_per_minute
        return Failure([:rate_limited, "#{provider_name}: minute limit reached (#{integration.max_requests_per_minute}/min)"])
      end
    end

    # Check per-day limit
    if integration.budget_exhausted?
      return Failure([:rate_limited, "#{provider_name}: daily limit reached (#{integration.daily_call_limit}/day)"])
    end

    # Increment counters
    integration.increment_minute_calls! if integration.max_requests_per_minute.present?
    integration.increment_api_calls!

    Success(:allowed)
  end
end
```

**Flujo en los gateways:**

```ruby
# Antes (actual):
def fetch_price(symbol)
  response = connection.get(...)
  return Failure([:rate_limited, ...]) if response.status == 429  # Reactivo
  ...
end

# Después (con RateLimiter):
def fetch_price(symbol)
  check = RateLimiter.check!("Polygon.io")
  return check if check.failure?  # Proactivo — ni siquiera hace la llamada

  response = connection.get(...)
  return Failure([:rate_limited, ...]) if response.status == 429  # Sigue como fallback
  ...
end
```

**Ventaja:** Evita gastar llamadas que sabemos van a fallar. El check 429 se mantiene como fallback porque los contadores locales pueden desincronizarse.

### 4. KeyRotation + RateLimiter Integrados

`KeyRotation.next_key_for` ya selecciona la key menos usada. Pero no verifica si el proveedor ya agotó su cuota. El flujo integrado:

```
Gateway request
  → RateLimiter.check!(provider)     # ¿Hay cuota disponible?
  → KeyRotation.next_key_for(provider) # ¿Cuál key usar?
  → HTTP request                       # Ejecutar
  → Handle 429 as fallback            # Por si los contadores están desfasados
```

### 5. Seeds con Rate Limits Reales

```ruby
Integration.find_or_create_by!(provider_name: "Polygon.io") do |i|
  i.max_requests_per_minute = 5
  i.daily_call_limit = 500
  # ...
end

Integration.find_or_create_by!(provider_name: "CoinGecko") do |i|
  i.max_requests_per_minute = 30
  i.daily_call_limit = 10_000
  # ...
end

Integration.find_or_create_by!(provider_name: "Alpha Vantage") do |i|
  i.max_requests_per_minute = 5
  i.daily_call_limit = 25
  # ...
end
```

### 6. Admin UI — Integrations Page Redesign

La página `/admin/users` actualmente muestra integrations como cards estáticas. Se rediseña como una sección dedicada con:

#### 6a. Integration Cards (mejorados)

Cada card ahora muestra:
- Provider name + type + status badge
- **Rate limit usage bar**: `minute_calls/max_requests_per_minute` y `daily_api_calls/daily_call_limit`
- Last sync timestamp
- **Expandible**: click para ver/gestionar API Key Pool
- Botones: Edit | Delete | Refresh Sync

#### 6b. API Key Pool (sección expandible dentro de cada integration)

```
┌─────────────────────────────────────────────────────────┐
│ Polygon.io                              [Connected]     │
│ Stocks & Forex                                          │
│ Rate limits: 3/5 per min · 127/500 per day             │
│ Last sync: 2 mins ago                                   │
│                                                         │
│ ▼ API Keys (2)                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ☑ Production Key     ••••••••7x9z    12 calls today │ │
│ │ ☑ Backup Key         ••••••••3a4b     3 calls today │ │
│ │ ☐ Retired Key        ••••••••9c1d     0 calls today │ │
│ └─────────────────────────────────────────────────────┘ │
│ [+ Add Key]                                             │
│                                                         │
│ [Edit Limits]  [Delete Provider]  [Refresh Sync]        │
└─────────────────────────────────────────────────────────┘
```

### 7. Use Cases Nuevos

| Use Case | Context | Input | Output |
|----------|---------|-------|--------|
| `Admin::Integrations::UpdateProvider` | Administration | `id`, `daily_call_limit`, `max_requests_per_minute`, `api_key_encrypted` | `Success(integration)` |
| `Admin::Integrations::DeleteProvider` | Administration | `id` | `Success(:deleted)` |
| `Admin::Integrations::AddPoolKey` | Administration | `integration_id`, `name`, `api_key_encrypted` | `Success(api_key_pool)` |
| `Admin::Integrations::TogglePoolKey` | Administration | `id` | `Success(api_key_pool)` |
| `Admin::Integrations::RemovePoolKey` | Administration | `id` | `Success(:removed)` |

### 8. Events Nuevos

| Event | Fields | Handler |
|-------|--------|---------|
| `IntegrationUpdated` | `integration_id`, `provider_name`, `changes` | `LogIntegrationUpdated` |
| `IntegrationDeleted` | `integration_id`, `provider_name` | `LogIntegrationDeleted` |
| `PoolKeyAdded` | `integration_id`, `pool_key_id`, `key_name` | `LogPoolKeyAdded` |
| `PoolKeyToggled` | `pool_key_id`, `key_name`, `enabled` | `LogPoolKeyToggled` |
| `PoolKeyRemoved` | `pool_key_id`, `key_name` | `LogPoolKeyRemoved` |

### 9. Reset de Contadores

```ruby
# Integration model — nuevos métodos
def reset_minute_counter!
  update!(minute_calls: 0, minute_reset_at: Time.current)
end

def increment_minute_calls!
  self.class.update_counters(id, minute_calls: 1)
end

def minute_budget_exhausted?
  return false if max_requests_per_minute.nil?
  return false if minute_reset_at.nil? || minute_reset_at < 1.minute.ago

  minute_calls >= max_requests_per_minute
end
```

---

## Commits Planificados

| #   | Phase  | Commit Message | Scope |
|-----|--------|---------------|-------|
| 110 | 15.6a  | Add name to ApiKeyPool and rate limit fields to Integration | Migration, model, seeds |
| 111 | 15.6b  | Add RateLimiter domain service with per-minute and per-day checks | Domain, specs |
| 112 | 15.6c  | Integrate RateLimiter into gateways | Gateways, specs |
| 113 | 15.6d  | Add UpdateProvider and DeleteProvider use cases | Use cases, contracts, events, specs |
| 114 | 15.6e  | Add AddPoolKey, TogglePoolKey, and RemovePoolKey use cases | Use cases, contracts, events, specs |
| 115 | 15.6f  | Add admin API key pool controller and routes | Controller, routes, specs |
| 116 | 15.6g  | Redesign admin integrations UI with pool management | Views, Stimulus, specs |

**Estimated specs:** ~50-60 new specs

---

## Lo que NO incluye esta fase

- **Redis-backed counters** — Los contadores de PostgreSQL son suficientes para nuestro volumen
- **Per-endpoint rate limits** — Solo per-provider (simplicidad > granularidad)
- **Automatic key procurement** — El admin agrega keys manualmente
- **Rate limit headers parsing** — Sería nice-to-have pero agrega complejidad por poco beneficio
- **Monthly rate limits** — Solo minute + daily (ExchangeRate se modela como daily ÷ 30)
