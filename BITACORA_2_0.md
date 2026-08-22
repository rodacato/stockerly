# Bitácora 2.0

> Running highlights for a future blog post — raw material, not the post itself. Written in English
> (repo convention) with Adrian's verbatim intentions kept in Spanish. Tell me to switch the whole
> thing to Spanish if you'd rather draft the post directly here.

## The thesis (the blog-post angle)

> *"Un blogpost sobre el slop de AI: cómo a pesar de no llegar a donde quería, una buena arquitectura
> me ayudó a hacer el pivot a un nuevo lugar."*

Stockerly was built over many evening/weekend sessions with heavy AI assistance. A lot of it was
**AI slop** — features and engineering theater built for personas that didn't exist, a closed beta
that failed on UX. The original destination (a multi-audience fintech platform) was never reached.

But the part that *wasn't* slop — the architectural discipline (hexagonal + DDD + event-driven,
clean bounded contexts, a real test suite) — is exactly what made the pivot **cheap**. When the
audience collapsed to a single self-hosted user, a 5-stage code audit + a 7-expert panel reached one
verdict: **EVOLVE, not rewrite.** The boundaries had isolated the damage. The pivot is a cleanup,
not a rebuild. That's the story: *good architecture is what lets you be wrong cheaply.*

## Highlights log

### 2026-08-22 — The gate: rewrite vs evolve

- Pivoted to a **self-hosted single-user tracker** (ADR-0010) after the closed beta failed on UX
  (empty first-run, unreadable indicators, data-entry chore).
- The seductive question resurfaced: *"¿empezamos de cero?"* — diagnosed (again) as emotional escape.
- Ran a **5-stage parallel code audit** against the target architecture. Verdict: **5/5 EVOLVE.** The
  abstractions the target wants (registries, event bus, projections, clean read boundary) already
  exist — *under-wired, not absent.* The multi-user surface is peripheral (every FK outbound →
  FK-clean delete). This is the hexagonal boundaries paying rent.
- **Slop moment worth the post:** we *believed* the multi-currency P0 bug was still open (it's cited
  as "the foundation fix" across memory, vision, and an ADR). It was **already fixed and tested**
  months ago. The context had rotted; the docs lied. The audit caught it. Lesson: AI-maintained
  context drifts, and the code is the only source of truth.
- Ran a **7-expert panel** as independent agents (not ventriloquized) — told explicitly not to
  rubber-stamp. Unanimous EVOLVE, but each pushed back: `dhh` (don't build a plugin framework you
  don't need), `mancuso` (verify the test suite is a real safety net first), `vernon` (cure the
  anemia, don't move it), `kleppmann` (harden serialization before trusting a log), `esther`/
  `el-usuario` (ship a screen, don't gold-plate the backend).
- Decision: **EVOLVE.** Started the cleanup phase — branch `evolve_2_0_pre`, tag `pre-2.0-evolve`
  marking the baseline.
- **Green baseline: 2762 examples, 0 failures, 94% line coverage.** The safety net is real —
  which is what makes deleting half the app a low-risk cleanup instead of a gamble.
- Cleanup began with the two most isolated pieces of beta scar tissue: `email_event` (Resend
  delivery tracking) and `user_activity` (usage-audit telemetry, #172). Both were **write-only** —
  built to answer "did the beta amigos use it?", read by nothing in the product. ~57 specs deleted
  with them; the suite stayed green at every step. The blog-post beat: *the AI-built features that
  measured a fantasy audience were the first things to go, and the architecture let them go cleanly.*
