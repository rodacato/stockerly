# Migration ledger — kit 0.8.0 across the flows

> **This file has an end.** It exists while the seven flows re-vendor kit 0.8.0 and adopt D48's
> vocabulary. When the last row says done, delete it — the per-flow status lives in
> [README.md](README.md) and the decisions live in [DECISIONS.md](DECISIONS.md). A ledger that
> outlives its migration becomes the fourth place to look.

**Written 2026-08-27.** Every claim here was verified against the file or the code, not inferred
from an earlier document — this project's registries have a measured habit of aging badly.

## Why every flow has to move

Kit **0.8.0** is not additive in practice even though it renames nothing:

- **`TopBar` grew 57 → 76.** The kit had been missing the 44pt touch target since 0.5.0 while the
  code always had it. Every artboard that vendors the mobile bar moves its content down 19px.
- **`TopBarDesktop` grew 78 → 80.**
- **14 new tokens** — `chart-1..8` + `chart-neutral` and `sentiment-1..5`, mirrored from
  `app/assets/tailwind/application.css`. Install them even where nothing renders differently; the
  method's rule is that approximations only surface when you re-vendor and diff.
- **`Segmented3`** exists, and `Segmented` carries D49's own-width rule.

## Status

| File | kit | Done | Pending |
|---|---|---|---|
| `ui-kit.lib.pen` | **0.8.0** | ✅ merged | — |
| `flows/assets.pen` | **0.8.0** | ✅ PR #368 | — |
| `flows/cockpit.pen` | 0.7.0 | — | the largest job; see below |
| `flows/auth.pen` | 0.7.0 | — | TOTP is now real (ADR-018) |
| `flows/alerts.pen` | 0.7.0 | — | one artboard is dangerous to build from |
| `flows/settings.pen` | 0.7.0 | — | a reversed decision still drawn |
| `flows/discover.pen` | 0.7.0 | — | the artboard is behind the code here |
| `flows/onboarding.pen` | 0.7.0 | — | nearly clean, unless TOTP lands in the wizard |
| `_playground.pen` | **none** | — | it is empty; this is an install, not a re-vendor |
| `brand.pen` | n/a | — | hygiene only |

---

## `flows/cockpit.pen` — the largest, and the only one that redraws the shell

**It does not vendor `TopBar`/`BottomNav`.** It carries **6 local TopBar copies and 4 local
BottomNav copies**, so the 57 → 76 change is six edits here against one anywhere else. D32.1 logged
this as waiting for "a batch someone asks for". This is that batch — consolidate while it is open.

- **Remove the `Evento de mercado · caídas generalizadas hoy` banner** — D25 cancelled.
- ❓ **Does `Panorama / Black swan` survive without it?** The banner may be the only thing that
  distinguished it from `Default`. If so the artboard is redundant and goes in the same pass.
  **Owner's call, blocking.**
- **Un-gate `Movimientos`** (D42) and rename it per D48 — the observation sense is **Señales**.
- **Draw the `Cerrar posición` confirmation.** It does not exist. A destructive write flow with no
  confirmation step, confirmed against `exports/README.md`'s complete inventory.
- **`Señales` / `Más análisis` need the reading's date**, per #306's DoD and ADR-013 — a stale
  reading may not be presented as today's state. Whether the artboard has a date slot is unknown.
- Verify `considera vender` really left the artboard (D36 decided it; execution unrecorded).

## `flows/auth.pen` + `_playground.pen` — the only pair that must be open together

- **Move `Panel · V1…V4`** out of `auth.pen` into `_playground.pen`. Move, not delete. Two files
  open at once; this is the one place the one-file-at-a-time rule genuinely bites.
- **`_playground.pen` is EMPTY** — one 800×600 frame, zero variables, zero components. Verified by
  reading it. It is *not* "behind on 0.6.0" and cannot be drawing the retired mark. Install the kit.
- **Rewrite the brief.** It calls the auth choice *"settled: password + TOTP, email OTP fallback"*.
  Half of that is now true and half is contradicted: **ADR-018 builds TOTP with recovery codes and
  puts email OTP explicitly out of scope.** Its Tunnel/Tailscale premise was also disproved.
- **Three artboards that do not exist:** TOTP enrollment (QR + secret + verify), the one-time
  recovery-code display, and recovery-code entry at login.
- ❓ **Where does the product *ask* for enrollment** — Ajustes, or a first-boot wizard step? A
  wizard step adds a `Stepper` stage and touches all nine onboarding artboards. **Owner's call.**
- Per D4 none of the new auth screens needs a desktop variant.

## `flows/alerts.pen`

- **`Confluencia` is dangerous to build from.** It still carries *"el semáforo está diseñado, no
  construido"* (lights 1 and 3 shipped), **and it describes a mechanism that does not exist** —
  nothing combines the three lights inside a window, and there is no confluence window in code.
- **Drop the third channel toggle.** Its first channel is `browser_push`, whose column and plumbing
  were deleted 2026-08-25 (#293). D16: *"Ajustes had it right"* — two switches, not three.
- **Re-vendor `SwitchRow`** — 3 hand-built copies.

## `flows/settings.pen`

- **One API key per provider.** D18 voted to keep the pools; **ADR-015 retired them** and the table
  was dropped. Four providers explicitly prohibit multiple credentials to beat a free tier. Drop the
  per-provider key count and the rotation note. (`CODE_CHANGES.md` §8 still repeats the retired
  verdict — fix it in the same pass.)
- Does `ajustes-estado` surface `discover:last_seen`? It is the evidence D31's kill criterion needs.
- ❓ The `Trabajos` badge: drop it, or give the count a source that is not a cross-database query in
  the hub's request path.
- ❓ `Guardar` button or auto-save on the hub — the artboard implies one, the code does the other.
- A `Seguridad` section, **if** TOTP enrollment lives in Ajustes.

## `flows/discover.pen`

- Confirm the *Reportes* block is gone from all three artboards (D47; commit `63f4051` suggests yes).
- **D41's contrast fix** was resolved *in code* — `primary` on `primary-muted` measured 3.68:1 light
  and 4.22:1 dark, both under 4.5:1. Whether the artboard was corrected is unrecorded.
- **D33 — here the code is ahead of the design.** The candidate answer was never marked adopted, but
  it shipped: `PolicyCalendar.horizon`, the `calendario_agotado` copy and `tentative` rows all exist.
  The artboard should catch up, and D33 should be closed.

## `flows/onboarding.pen`

- Check for a third `OptionCard` → `NavRow` consumer (kit 0.4.0 parked this for "when next open").
- Only large if TOTP enrollment becomes a wizard step — see the auth question.

## `brand.pen`

- Hygiene only, and now unblocked: D45/D46/D47 were duplicated in the registry and are fixed.
- `Actual / Símbolo` keeps the retired four-bracket mark **on purpose** — it is the "before".
- If `F2 / … › Escala` is re-exported it must go at `scale: 1`. It is a measurement, not a review
  artifact: at 2× a "16 px" sample renders 32 px and flatters itself.

---

## Kit gaps found while migrating — for the next bump

- **`NavRow` has no recommended/primary state.** Found vendoring it into `assets.pen`: three copies
  had drifted ~6% larger and snapped back, but a fourth carried a deliberate `$primary` accent
  because it is the recommended path out of an empty portfolio. It ships as an instance override.
  If a second flow needs it, that override has earned a variant.

## Method notes this migration paid for

- **A `.pen` write reaches disk with a LAG.** `git status` showing "modified" and `git hash-object`
  differing from HEAD prove that *something* landed, not that *everything* did. **Verify by grepping
  for the specific content you wrote.** This cost a commit that shipped a stale brief (#367/#368).
- **`Export` resolves its path from the repo root, not from the `.pen`.** `Export(…, "./exports")`
  from `design/flows/` writes to `/exports`. Move the files afterwards.
- **Measure `ctx.bounds` in a different `execute` than the one that writes.** In the same call it
  returns pre-reflow positions and reports clipping that is not real.
- **Verify the artboard names before writing.** Node ids repeat across flow files because the flows
  were created by duplicating each other; an id never proves which file you are in.
- **After a merge, verify master by content.** #366 merged only its first commit and nobody noticed
  until the next session read the file.
