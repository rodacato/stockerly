# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Cerrar los 2 JTBDs sin superficie verificable (#3 CETES maturity, #6 Notable Observations) y dejar ADR-002 escrito para desbloquear el sprint arquitectónico — todos los 6 JTBDs canónicos quedan con feature observable en producto.

**Sprint period:** 2026-05-15 → ~2026-05-17 (estimated ~25–28 session-hours, factor 1.5× new-feature)

**Sprint number / milestone:** S04 — `2026-S04-jtbd-gap-fill`

---

## Why this goal and not another

S03 cerró la honestidad de los cálculos (axis #4: 40% → 95%) y eliminó ~25% de código sin JTBD (axis #1: 50% → 80%). Los 4 calculadores supervivientes ya rinden valores correctos en `user.preferred_currency`. El problema restante para Axis #1 (Every feature maps to a JTBD) no es código sobrante — es código faltante: **JTBD #3 (CETE maturity) y JTBD #6 (notable technical observations) son canónicos en `docs/vision/jobs-to-be-done.md` pero no tienen superficie en el producto.**

JTBD #3 es además P0 (label `beta-blocker` implícito): Adrian tiene CETES en su portafolio real; sin alertas de vencimiento, la primera demo de la beta es un dashboard que ignora el instrumento que más capital tiene asignado en MXN. Cerrar #29 antes de la beta no es opcional.

JTBD #6 es P2 pero estratégico: el panel JTBD ya menciona "RSI/BB/MA notable zones" — si la beta abre sin esta superficie, Renata (axis #1 owner) marcará una contradicción canon-vs-código. #40 entrega la superficie mínima descriptiva (no prescriptiva, ADR-001-compliant).

El trabajo paralelo cumple la regla de mantener los ejes vivos sin absorber esfuerzo principal:
- **#37 slice S04**: 2 componentes + 1 vista importante migrados a tokens semánticos (continúa la migración S3-S6).
- **ADR-002 draft**: research issue nuevo (≤3h) que escribe la decisión arquitectónica para que #33 entre a S05 sin bloqueo de ADR.

Referencias: [JTBDs #3 + #6](../../vision/jobs-to-be-done.md), [Sprint 3 retro](../2026-S03-jtbd-alignment/retro.md), [ADR-001 (descriptive language)](../../architecture/adr/0001-descriptive-not-prescriptive-language.md).

---

## What's NOT in this sprint (anti-scope)

- **No implementación de ADR-002.** Solo la decisión escrita. La refactorización del leak Trading↔MarketData (#33) es S05.
- **No prescriptive copy rewrite.** S06 (#36). Cualquier copy nuevo en #29/#40 ya debe ser descriptivo desde el día 1 — pero no se reescribe copy existente.
- **No semantic tokens full migration.** Solo el slice S04 de #37: 2 componentes + 1 vista. El resto queda para S05/S06.
- **No screenshot regeneration as a goal.** Baseline pre-S4 al abrir (carry-over de S03 retro); regenerar al cerrar solo las vistas que cambiaron visualmente.
- **No expansión de la beta.** S04 deja los 6 JTBDs con superficie; la invitación al primer amigo es S07 (beta-prep).
- **No tocar PortfolioSnapshot.** S03 dejó `currency` agregado; no es S04 territory.
- **No ADR-007 (Administration BC).** Es S05.
- **No SimpleUseCase pattern (#38).** Es S05.
- **No zombie events cleanup (#35).** Es S05.
