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
| `ui-kit.lib.pen` | **0.9.0** | ✅ | — |
| `flows/assets.pen` | **0.8.1** | ✅ | — |
| `flows/cockpit.pen` | **0.8.1** | ✅ | 3 items, one an owner's call |
| `flows/auth.pen` | **0.8.1** | ✅ | — |
| `flows/alerts.pen` | **0.9.0** | ✅ | — |
| `flows/settings.pen` | **0.9.0** | ✅ | — |
| `flows/discover.pen` | **0.8.1** | ✅ | — |
| `flows/onboarding.pen` | 0.7.0 | — | TOTP lands in the wizard (D52): nine artboards move |
| `_playground.pen` | **0.8.1** | ✅ | — |
| `brand.pen` | **0.9.0** | ✅ | — |

> **This table drifted, and it is worth naming rather than silently correcting.** Until 2026-08-27
> it read `0.8.0` on six rows and `n/a` on `brand.pen`. The per-flow *Done* column was maintained
> and the `kit` column was not: when the kit went 0.8.0 → 0.8.1 → 0.9.0, the consumers were
> re-vendored and the table was not. **A registry that records a version has to be re-read from the
> variable, not from what the last edit remembered** — the same failure D53 is parked about, in the
> file that documents the failure. Every value above was read from `GetVariables()`.
>
> **Rows at different versions are not drift.** `0.8.1` was a token-and-treatment patch every
> consumer took; `0.9.0` added `HeaderBar`, so only the two flows that vendor it moved. Behind is
> allowed; diverging is not.

---

## `flows/cockpit.pen` — migrated 2026-08-27, except three items

**Shell consolidated.** Six hand-built TopBars and four BottomNavs are now instances of three
vendored components — `TopBar` (390×76), `TopBarDetail` (390×76) and `BottomNav` (390×62) — and
`TopBarDesktop` moved 76 → 80. Zero local shell copies remain, verified by query, not by eye.

**The six TopBars were two variants, not six copies of one**, and measuring them before replacing
is what kept the file honest — the same lesson `NavRow` taught in `assets.pen`:

- Three root bars (`Brand`/`Bell`) → the kit's `TopBar`.
- Three detail bars (`TL`/`Bm`) → `TopBarDetail`, **a kit gap**: the kit ships the root bar only.
  `Mi posición` carries `bookmark-check` and `Análisis` carries `bookmark` — a deliberate state
  difference, preserved as an instance override rather than flattened.
- 🐞 **`Movimientos` was carrying the asset detail's leftovers** — the subtitle *"Nvidia"* and a
  bookmark icon, on a screen that lists signals across the whole portfolio. Both dropped.
- `Back` and `Bm` were 22 and 20px. They are 44 now, matching the kit's root bar and the code, which
  already had it (`_asset_header.html.erb`, `size-11`). Fixing the root and not the detail would have
  introduced an inconsistency in the pass that exists to remove them.

**Also done:** the 14 tokens and `kit-version-source` 0.8.0 · `Panorama / Black swan` deleted (D51)
· `considera vender` restored (D54) · the brief rewritten whole, not patched · `Movimientos` grown
733 → 844 to meet D7's floor, a pre-existing breach · all nine artboards re-shot.

### Still pending here

- ❓ **Rename `Movimientos` per D48.** The observation word is *Señales*, but adopting it gives one
  word to a screen, to the Panorama's `Movimientos de interés` band (a name ADR-013 explicitly
  blessed) and to a block that already exists inside `Asset · Análisis`. **Owner's call.**
- **`Señales` carries no reading date.** Measured: zero timestamps in the block. ADR-013 and ADR-014
  both require it — *a stale reading may not be presented as today's state* — and #306's DoD asks
  for it. This is new design, not migration: it needs the copy decided.
- **The `Cerrar posición` confirmation still does not exist.** A destructive write flow with no
  confirmation step.
- `Más análisis` **is not in this file under that name** — the earlier version of this ledger assumed
  it was. Whatever it refers to, it is not an artboard here.

## `flows/auth.pen` + `_playground.pen` — done 2026-08-27

Worked as a pair, the one place the one-file-at-a-time rule genuinely bites. The panels were
verified on disk in the destination **before** being deleted from the source — a move where the
delete lands and the insert has not is how exploration disappears.

- ✅ `Panel · V1…V4` moved to `_playground.pen`. Moved, not deleted: they are the reasoning behind
  the login's brand panel.
- ✅ `_playground.pen` had the kit **installed**, not re-vendored — it was one 800×600 frame with
  zero variables. It now carries all 51 tokens at 0.8.0.
- ✅ Brief rewritten. It called the auth choice *"settled: password + TOTP, email OTP fallback"* —
  half true, half contradicted — and claimed `kit-version-source 0.1.0` against a variable reading
  0.7.0. It now opens with ADR-018's three boundaries.
- ✅ **Three artboards drawn**: `TOTP · Alta` (QR + manual key + 6-digit verify), `Códigos de
  recuperación` (ten one-time codes, display-once) and `Código de recuperación` (entry at login).
  Per D4 none has a desktop variant — they are forms in a card and diverge on nothing.
- ✅ 🐞 **The 2FA screen offered `Enviar código por correo`.** ADR-018 puts email OTP explicitly out
  of scope; the link is now `Usar un código de recuperación`, which is the path that actually
  exists. Re-shot.
- **This flow vendors no shell**, so 0.8.0's 57 → 76 never reached it. The migration was tokens
  plus the new screens.

**Found here, logged as D55:** the argument that kills email OTP also applies to
`/forgot-password`, which this flow already ships.

## `flows/alerts.pen` — done 2026-08-27, on 0.8.1

- ✅ 14 tokens · `info-fg` · `kit-version-source` **0.8.1** · `TopBar` 57 → 76 · the accent-on-muted
  rule applied to 8 text nodes.
- ✅ 🐞 **The bell's badge was clipped.** `BellWrap` was 26×22 with the count badge at `x=11`,
  spilling out of its own box — the file's one reported layout problem. It is 44×44 now, which also
  buys the touch target. **The count badge stays**: this is the flow that owns the inbox, and a
  number is more informative than the kit's `UnreadDot`. Logged below as a kit gap.
- ✅ **Two channels, not three (D16).** The brief grounded on
  `alert_preferences (browser_push, email_digest, sms_notifications)`. `db/schema.rb` has exactly
  **two** booleans — `email_digest` and `urgent_email`. `browser_push` went with #293 and
  `sms_notifications` never existed. The `Avisos en la app` switch is gone, and the block's footer
  stopped promising it — it named a toggle that no longer exists.
- ✅ **`SwitchRow` re-vendored.** Two hand-built rows had drifted to a 13px label against the kit's
  14 and had lost the row padding. The OFF state on `Avisos urgentes` was **deliberate**
  (`$border-strong`, knob at `x:3`) and survives as an instance override — the `NavRow` lesson again.
- ✅ **`Confluencia`: the warning was half stale and half live.** STALE — *"el semáforo está
  diseñado, no construido"* is false: lights 1 and 3 shipped and render at
  `market/_confluence.html.erb`, reached from `_analysis`. **LIVE** — the shipped subtitle reads
  *"Tres señales, leídas por separado"*, which is the honest description: nothing combines them.
  The artboard promised *"cuando las tres se prenden dentro de la misma ventana"* and drew a
  `Ventana de confluencia · 5 días` control nothing computes. The window keeps its artboard (D8) and
  now carries the `motor pendiente` treatment light 2 already had.
- ✅ **Luz 3 stopped claiming MACD.** It exists only as a 20 %-weighted factor inside
  `TrendScoreCalculator`, not as a signal; the light reads `ma50/ma200_crossed_*`.
- ✅ **`HeaderBar` consolidated, and it is NOT `TopBarDetail`.** Bandeja and Confluencia each
  hand-built the same back-header. Measured before promoting anything: cockpit's detail bar has a
  two-line ticker title and a bookmark, this one an 18px display title and an optional text action —
  different components. Both back buttons were 20px and are 44 now.
- ✅ Brief rewritten. **Sixth of six** found contradicting its own file: it claimed
  `kit-version-source 0.3.0` against a variable reading 0.7.0.

## `flows/settings.pen` — done 2026-08-27, on 0.9.0

- ✅ Tokens · `info-fg` · `TopBar` 57 → 76 · `TopBarDesktop` 76 → 80 · the accent-on-muted rule on
  8 text nodes.
- ✅ **`HeaderBar` promoted to the kit (0.9.0).** This flow hand-built it four times and `alerts`
  twice — the second consumer the 0.8.0 gap note asked for. Measured before promoting: it is **not**
  cockpit's `TopBarDetail`. All four back buttons were 20px and are 44 now.
- ✅ 🐞 **The BottomNav master had TWO active items** — `Descubrir` and `Ajustes`, both `$primary`,
  with no instance override hiding it. When Descubrir became the fifth destination (D31) the active
  state was set on it and never cleared from Ajustes, so all eight artboards drew two highlighted
  tabs. Only Ajustes is active now.
- ✅ 🐞 **A Registros row read `Polygon Sync · Rate limit alcanzado · 5 llamadas por minuto`** —
  sample data naming a retired provider, in the brief's own words *"dead config on a screen whose job
  is configuration"*. Now Yahoo Finance and its real 6/min cap from `ProviderDefaults` (ADR-017).
- ✅ `Registros` grew 670 → 844 to meet D7's floor, a pre-existing breach.
- ✅ **D52's `Seguridad` row** added to Cuenta — *Verificación en dos pasos · TOTP y códigos de
  recuperación*.
- ✅ **The `Trabajos` badge question is answered, and the answer was already in the repo.**
  `CODE_CHANGES.md` §8 records that counting `SolidQueue::FailedExecution` put a cross-database query
  in the hub's request path and **aborted the transaction outright in test**. The row carried a
  hardcoded `0`; it carries nothing now and links to Mission Control. The real numbers already render
  on Estado y mantenimiento (`admin/settings/show.html.erb:14`), a screen you open on purpose.
- ✅ **D17 is FIXED and the brief was two versions behind.** It carried a ⚠ and a 🔴 saying two of the
  three SiteConfig toggles did nothing. Re-measured: `auto_sync_enabled` is read by
  `pausable_sync.rb`, `email_notifications_enabled` by `alert_mailer.rb`. The desktop layout that
  *"made the lie louder"* no longer has a lie to amplify.
- ✅ **The ledger's own claim about `CODE_CHANGES.md` §8 was wrong**, and it is worth saying rather
  than deleting quietly. This file used to read *"§8 still repeats the retired verdict — fix it in
  the same pass."* It does not: §8 **strikes** the pools verdict through and records the reversal,
  dated 2026-08-27, with the tree verified. What §8 *did* still owe was the failed-jobs badge note,
  which said the artboard showed a count it should not — true for two months, fixed here.
- ✅ Brief rewritten. **Seventh of seven** — every brief in the system, without one exception,
  contradicted its own file. This one claimed `0.5.0` against a variable reading 0.7.0.

### ❓ Still open — owner's call

**Guardar vs auto-save.** The code does both, split by kind, and the split is invisible: theme writes
to `localStorage` on click, the notification switches POST on toggle, and currency is a form with an
explicit `Guardar`. **Tema and Moneda are the same segmented pill drawn twice**, and one commits
instantly while the other waits for a button — that is the defect, not which behaviour is right.
Recommendation, unbuilt: move Moneda to auto-save; `update_currency_path` already exists and writes
only `preferred_currency`, so the toggle pattern applies directly. The artboard draws today's
behaviour until the call is made.

## `flows/discover.pen` — done 2026-08-27

The only flow whose shell was **already fully vendored** — no hand-built copies — so 0.8.0 was a
component update rather than a consolidation.

- ✅ 14 tokens · `kit-version-source` 0.6.0 (claimed by the brief) / 0.7.0 (actual) → **0.8.0**.
- ✅ `TopBar` 57 → 76 and `TopBarDesktop` 76 → 80, both from the same cause: the kit's 44pt bell
  target. The two mobile artboards absorbed 19px; `Sin datos` is fixed-height and its Content took it.
- ✅ 🐞 `TopBarDesktop`'s master read *"Activos / CARTERA · MXN"* — residue from this file being
  seeded off `assets.pen`. Its single instance overrode it, so nothing rendered wrong, but the
  default was meaningless here. Master and instance agree now and the override is gone.
- ✅ **D47/D46 confirmed by query:** `Reportan pronto` is gone from all three artboards; the only
  remaining occurrences are the brief's own prose explaining the removal.
- ✅ **D33 closed.** The brief's N9 has read CLOSED since the block was built, while the registry row
  stayed open — `PolicyCalendar.horizon`, `calendario_agotado` and the `tentative` rows all exist.
- ✅ **D41 applied**, and applying it produced **D56**: its decided change (the `Aviso` paragraph to
  `$fg-default`) had never been executed, and two of its supporting claims do not survive
  measurement. Neither of those is fixed here — both are token-level.
- ✅ Brief rewritten. Fifth of five found contradicting its own file.

## `flows/onboarding.pen`

- Check for a third `OptionCard` → `NavRow` consumer (kit 0.4.0 parked this for "when next open").
- **It became the large one.** D52 puts a skippable TOTP step in the wizard, so the `Stepper`
  gains a stage and all nine artboards move.

## `brand.pen` — done 2026-08-27, on 0.9.0

Billed as *"hygiene only"*. Measuring found a divergence and three stale claims, which is more than
hygiene.

- ✅ 🐞 **It DIVERGED on `info-fg`**, holding the old dark `#7B89FF` against the kit's `#9098FF`. Not
  "behind" — the method allows behind and forbids diverging — and the consistency sweep missed it,
  because that sweep checked token **membership** on the migrated flows and value equality only on
  `auth`. **`flows/onboarding.pen` had the same divergence** and was fixed with it although its own
  migration has not run: a wrong value is a defect now, a missing one is only a schedule.
- ✅ 🐞 **The row whose entire job is to state the version stated the wrong one.** `Brand / Brief ›
  Meta › kit-version-source` read **0.7.0** while the variable read **0.6.0**. Both read 0.9.0 now.
  That is the **eighth** self-contradiction this migration turned up, and the purest: not a brief
  describing its file loosely, but a labelled field disagreeing with the value it labels.
- ✅ 🐞 **The `Estado` row listed three pending items and all three were already done.** *"Pending:
  scale-1 export, flow re-vendor, code change."* `brand-escala-1x.png` exists and measures 1236×222
  — the frame's own size, so `scale: 1` confirmed rather than assumed; all seven flows carry the
  mark; and the code change landed as `CODE_CHANGES.md` §11.
- ✅ The 14 tokens installed. `F2 / Usos` is the only sheet touching the `info` pair and it
  re-exported **byte-identical** — only `info-fg`'s dark value moved and exports render light. Two
  PNGs changed, not eight.
- ✅ 🐞 **Caught while writing this: `alerts.pen`'s brief said `kit-version-source 0.8.1` against a
  variable reading 0.9.0** — created earlier the same day when `HeaderBar` was promoted and the
  variable was bumped without the prose. Fixed. It would have been the ninth contradiction, and mine.
- **`Actual / Símbolo` keeps the retired four-bracket mark on purpose** — it is the "before", and the
  ledger was right about that one.

## Cross-flow consistency sweep — 2026-08-27

Run after `settings` closed, against the rules `README.md` states rather than against the plan. Every
line below was measured; nothing here was assumed.

**Clean, verified:**

| Check | Result |
|---|---|
| Exports vs index | **64 PNGs on disk, 64 listed** — zero orphans, zero missing |
| *"Tokens only — zero hex in a flow"* | **zero real hex** in any flow |
| D7's 390×844 floor | **zero** artboards under it (after `Movimientos` 733→844 and `Registros` 670→844) |
| One active nav item per artboard | **zero** doubles left (after settings' master) |
| Retired providers named in artboards | **zero** (after the `Polygon Sync` log row) |
| Token set vs the kit, by membership | exact in `cockpit`, `assets`, `discover`, `alerts`, `settings`, `_playground` |

**Found and fixed: `auth.pen` was missing `scrim`.** The only migrated flow short a kit token — and
**the reason generalises, which is the real finding**: every migration in this pass installed the
*delta* (0.8.0's 14 new tokens) and never reconciled against the kit's full set. A count check would
not have caught it either, since 52 vs 52 hides a missing token paired with an extra one. Only set
membership does. **Reconcile against the kit's list, never against the diff.**

**Found, not fixed:**

- **The hex rule has no token for its own exception.** `cockpit.pen` carries 44 literals and all 44
  are `#00000000` — transparency, not colour. The kit has no `transparent` token, so a hex literal is
  the only way to say "no fill", and the rule as written forbids the only available spelling. Worth a
  token in a future bump, or a sentence in the rule.
- `_playground.pen` sits at **0.8.1** against the kit's 0.9.0. Behind, not diverging: 0.9.0 added a
  component and no tokens, and `_playground` has no back-header to vendor it into.
- `brand.pen` sits at **0.6.0** without the 14 new tokens. Behind by design — the ledger has always
  said hygiene only.

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
