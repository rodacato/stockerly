# Trend Explorer (Public) — Spec

> **Zona:** Publica
> **Estado:** static-html

---

## Identificacion

| Campo | Valor |
|-------|-------|
| **Ruta** | `/trends` |
| **Layout** | `public` |
| **Controlador** | `TrendsController#index` |
| **Vista principal** | `app/views/trends/index.html.erb` |
| **Fase** | 1 |

---

## Diseno de referencia

- **Captura:** `screen.png`
- **HTML Stitch:** `code.html`
- **Variantes:** Ninguna

---

## Secciones y elementos

- **Dark filter bar:** Filtros por sector, exchange y market cap. Barra horizontal con fondo oscuro.
- **Stock detail card:** Tarjeta principal con ticker, nombre de empresa, precio actual y metricas clave.
- **Performance chart SVG:** Grafico de linea SVG mostrando rendimiento historico del activo.
- **Trend Score circle:** Indicador circular (0-100) que muestra la puntuacion de tendencia del activo. Usa conic-gradient para el donut.
- **Key metrics grid:** Grid de metricas clave (volumen, P/E ratio, market cap, etc.)

---

## Datos necesarios

- **Modelo:** Asset (hardcodeado por ahora)
- **Campos usados:** ticker, company_name, price, change_percent, sector, exchange, market_cap, trend_score, volume, pe_ratio
- Actualmente todos los datos estan hardcodeados en la vista. Se conectara al modelo Asset cuando se implemente el backend de Market Data.

---

## Formularios y acciones

Ninguno. Los filtros son de presentacion estatica por ahora. CTA "Sign up for full access" redirige a `/register`.

---

## Stimulus controllers

Ninguno identificado

---

## Turbo

No aplica

---

## Empty state

No aplica (datos hardcodeados)

---

## Estado de implementacion

| Etapa | Estado |
|-------|--------|
| Diseno (Stitch) | Completo |
| HTML estatico | Completo |
| Backend conectado | Pendiente |
| Tests | Pendiente |

---

## Notas

- Esta es la version "preview" publica del Market Explorer autenticado (`/market`).
- Incluye CTA "Sign up for full access" para conversion de usuarios anonimos.
- Los filtros se conectaran al backend en una fase posterior (probablemente Fase 3 con Market Data).
- El grafico SVG es inline, no usa libreria de graficos externa.
