# Sprint Goal

> A single sentence. Non-negotiable during the sprint.
> If the goal needs to be revised mid-sprint, close this sprint early with retro and open a new one.

**Goal:** Cerrar los pre-beta blockers que la research surface (terms + risk + privacy + ARCO + Art. 8 consent + cost-basis P0) y revampear el auth-flow (login + register) para que el primer amigo invitado se registre sobre fundaciones legalmente correctas y matemáticamente truthful.

**Sprint period:** 2026-05-17 → TBD (cerrar por QA + retro, no por fecha)

**Sprint number / milestone:** S08 — 2026-S08-beta-readiness

---

## Why this goal and not another

S07 cerró con el sistema funcionalmente listo para invitar al primer amigo a beta cerrada. Pero la research paralela ejecutada el 2026-05-17 surface 5 pre-beta blockers + 1 carry-over P0 que **hacen el invite irresponsable** en el estado actual:

1. **Terms of Service y Risk Disclosure son defectuosos** — declaran actividades de broker (margin/leverage/liquidation/NY jurisdiction) que Stockerly NO hace. Un invitado "acepta" documentos que misrepresentan el producto. Vicio de consentimiento + posible responsabilidad civil.
2. **El Aviso de Privacidad** rewriteado en S07 #73 es es-MX y bien-intencionado, pero quedó incompleto frente al NLFPDPPP (DOF 20-mar-2025): falta SABG (INAI extinto), distinguir finalidades necesarias vs voluntarias (Art. 15), retention policy (Art. 11), declaración de remisiones internacionales (Arts. 35-36 — actualmente dice "no transferimos a terceros" lo cual es falso).
3. **No hay express consent para datos patrimoniales** (Art. 8 NLFPDPPP). El register actual acepta términos + privacy pero el portfolio + trades del usuario requieren consent específico no-pre-marcado.
4. **No hay procedimiento ARCO operativo** documentado (Art. 32 NLFPDPPP, 20 días hábiles).
5. **TakeSnapshotsJob suma cross-currency sin conversión** — el dashboard del mockup #90 muestra `MXN 1,247,580.40` como total consolidado, pero el job que produce esa cifra hoy suma USD + MXN como si fueran misma unidad. **Las matemáticas del dashboard son ficción para portfolios mixtos.**

Adicional al cierre de blockers, S08 revampea **/login** + **/register** para Lumen + es-MX (auth-family completion iniciada en S07 #73). El register naturally integra el B-03 Art. 8 consent — co-fix.

**Lo que se desbloquea:** el sistema queda **realmente** listo para enviar el primer invite, con fundaciones legalmente correctas y matemáticamente truthful. El auth flow es coherente y native es-MX.

---

## What's NOT in this sprint (anti-scope)

- **Design revamps de pantallas operacionales** (#90 dashboard, #91 portfolio, #92 market, #93 asset-detail, #94 alerts, #97 profile, #98 trades, #99 password recovery) — los mockups Stockerly-2.0 ya están listos en `.local/`, pero implementación es **S09**. La razón: no tiene sentido implementar el dashboard mientras el TakeSnapshotsJob produce datos falsos; la implementación post-fix será sobre matemáticas truthful.
- **S08 candidates del research no priorizados:** C2 tax_regime, C3 natural-language alerts, C4 single-primary-number dashboard, C5 microcopy técnica, C6 liquidity tag, C7 FIBRA distributions, C8 UDI third unit. Defer a S09+.
- **Audit findings no críticos:** F-01 encryption-key fallback (audit-security), Notification.create! bypass (audit-architecture-drift), admin/settings + ExecuteTrade concurrency coverage gaps (audit-test-coverage). NO son beta-blockers. Worth tackling pero defer.
- **Earnings + Notifications mockups pendientes** (#100, #101) — Adrian los genera mañana cuando se reinicie su quota de Claude Design.
- **External legal review** del nuevo terms + risk disclosure + privacy — sigue como TODO post-beta (consistent con S07 #73 decisión).
- **Discovery-card audit script automation** — process discipline carry-over de S07 retro, applied manualmente este sprint.
