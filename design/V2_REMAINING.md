# What is left to finish the 2.0 revamp

> **The question this file answers:** flow by flow, what is still unconnected, what disagrees
> between the design and the code, and what debt the revamp is carrying. It is the punch list for
> declaring 2.0 done.
>
> **Every finding here was measured on 2026-08-28**, against `master` at `f9401fd` and the ten
> `.pen` files as they sit on disk. Nothing is carried forward from an earlier document.
>
> **`master` moved from `f9401fd` to `ffff721` while this was being written**, and all five commits
> were read against it rather than assumed harmless. Four touch nothing here — the sprint folder,
> `todo.md`, `.notdefined.yml` with an orphaned screenshot, and the dead user columns
> (`is_verified`, `email_verified_at`, `status` and the `:suspended` branch in
> `sessions_controller`). The fifth, `46a95aa`, **fixes one finding this file had written**:
> `CODE_CHANGES §14`'s stale dependency line. AUTH-1 records it as already closed rather than
> pretending it was never found.

## This file replaced two, and here is what happened to them

Three documents were answering *where does the migration stand* — from three angles, by hand, going
stale at three different rates. That is the question D53 parked. **It is answered by consolidation,
2026-08-28:**

- **`FIDELITY_AUDIT.md` — retired into this file.** It asked *does the code look like the artboard?*
  Its measurement table lives on below, re-run rather than copied; its seven open TODO items are all
  carried, re-verified; its fifteen closed ones were execution history that
  [`CODE_CHANGES.md`](CODE_CHANGES.md) already owns. Two of the seven turned out to be stale on
  arrival and are closed here.
- **`COMPONENT_INVENTORY.md` — retired into this file.** It crossed the kit against
  `app/views/components/`. Its live half is the *Kit → code* section below — four gaps this audit
  would have missed, because it read screens and that document read components. Its dead-partial
  triage was fully resolved and went with it.

What stays, because each owns something nothing else does:

| | Owns |
|---|---|
| [`README.md`](README.md) | the method, the flow inventory, the canvas rules |
| [`CODE_CHANGES.md`](CODE_CHANGES.md) | the execution record — what shipped, and the work orders |
| [`DECISIONS.md`](DECISIONS.md) | the reasoning. Findings here cite `Dn` rather than restating it |
| [`ui-kit.CHANGELOG.md`](ui-kit.CHANGELOG.md) | the kit's version history and its open gaps |
| **this file** | **where the migration stands, and what is left** |

**Nothing in this file is a new decision.** Where a call is owed, it says whose it is.

**One thing was deliberately not carried:** `FIDELITY_AUDIT`'s flow-by-flow narrative, which was
mostly a record of its own corrections — *"this section said X for two days after X stopped being
true"*. That evidence is what produced D53, D53 records it, and re-copying it here would be the rot
it describes. It is in git history if the argument is ever needed again.

### Where its seven open items went

So a reference to the old numbering is still resolvable without the file.

| Was | Now |
|---|---|
| 6 — Mi posición's two gaps (#301) | **CKP-4** |
| 15 — retire or qualify the *DONE* convention | **X7** — reframed: the verb was never the problem |
| 16 — the README's `done · in review` reads the `.pen`, not the ERB | **X7**, and the README now points here |
| 17 — two stale branches | ✅ **closed** — `docs/pivot-self-hosted-tracker` and `design/discover` are both gone from `origin`. Five others have taken their place; see X7 |
| 18 — `welcome` / `help` carry no i18n | **ONB-3** |
| 19 — the Confluencia artboard is out of date | ✅ **closed** — the artboard was fixed 2026-08-27; only the TODO line was stale. See ALR-1 |
| 21 — *Guardar* vs auto-save in Ajustes | **AJU-3** (= D58) |

Its other fifteen items were closed work. `CODE_CHANGES.md` is where that record lives.

## How this was measured

| Side | How |
|---|---|
| Design | Pencil MCP: every artboard enumerated per flow, every brief read, every text node dumped with `resolveInstances: true`, all 51 token values hashed per file |
| Code | `config/routes.rb` read end to end, every view under `app/views` listed, the views behind each artboard read in full, `grep` for each claim |

Token divergence across the ten `.pen` files is **zero** — verified by hashing the sorted
`name=value` list of all 51 tokens in each file, not by comparing names. Kit is at `0.9.0`;
`ui-kit`, `alerts`, `settings`, `onboarding` and `brand` vendor it, the other five vendor `0.8.1`.

---

# Where the migration stands

Two tables. **Both were re-run on 2026-08-28** against `46a95aa` — the commands are printed so the
next pass counts the same way, and so re-measuring is always cheaper than trusting the numbers.

## 1. Is each screen on the 2.0 contract?

`slate-*`/`gray-*` are the pre-2.0 palette; `bg-bg-*`/`text-fg-*`/`border-border-*` are the Lumen
token contract; `t(...)` is ADR-011. **The unit is a matching line, not a match** — the two differ
by roughly 2×, and a later pass counting the other way would read a regression that is not there.

```sh
grep -rcE '\b(slate|gray)-[0-9]+'          app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
grep -rcE 'bg-bg-|text-fg-|border-border-' app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
grep -rcE '\bt\('                          app/views/<dir> | awk -F: '{x+=$NF} END{print x+0}'
```

> `\b(slate|gray)-` and not `slate-`: the loose pattern matches inside `translate-`, which counted
> transform utilities as pre-2.0 palette. It was worth 13 of 1510 matches when it was found.

| View dir | slate | tokens | i18n | | Artboard? |
|---|---:|---:|---:|---|---|
| `admin` (logs · integrations · settings) | 0 | 65 | 52 | ✅ 2.0 | yes |
| `alerts` | 0 | 49 | 36 | ✅ 2.0 | yes |
| `assets` | 0 | 35 | 47 | ✅ 2.0 | yes |
| `components` | 0 | 56 | 13 | ✅ 2.0 | the kit |
| `dashboard` | 0 | 20 | 18 | ✅ 2.0 | yes |
| `discover` | 0 | 25 | 17 | ✅ 2.0 | yes |
| `layouts` | 0 | 10 | 4 | ✅ 2.0 | the shell |
| `market` | 0 | 186 | 100 | ✅ 2.0 | yes |
| `notifications` | 0 | 9 | 11 | ✅ 2.0 | yes |
| `onboarding` | 0 | 40 | 27 | ✅ 2.0 | yes |
| `password_resets` | 0 | 14 | 20 | ✅ 2.0 | 3 of 5 |
| `portfolios` | 0 | 16 | 23 | ✅ 2.0 | yes |
| `sessions` | 0 | 2 | 10 | ✅ 2.0 | yes |
| `settings` | 0 | 33 | 22 | ✅ 2.0 | yes |
| `setup` | 0 | 2 | 12 | ✅ 2.0 | yes |
| `trades` | 0 | 76 | 16 | ◐ copy | **no** — ACT-3 |
| `positions` | 0 | 30 | **1** | ◐ copy | drawn, not built — ACT-2 |
| `profiles` | 0 | 64 | **0** | ◐ copy | **no** — AJU-1 |
| `shared` | 0 | 40 | **0** | ◐ copy | mixed |
| `welcome` · `help` | 0 | 2 · 2 | **0** | ◐ copy | yes · no — ONB-3 |
| `bug_reports` | 0 | 11 | **0** | ◐ copy | **no** |
| `legal` | 0 | 89 | **0** | ◐ copy | **no** — deliberate, S5 |
| mailers (`alert` · `user` · `bug_report`) | 0 | 0 | **0** | ◐ copy | **no** |

**The pre-2.0 palette is gone from `app/views` entirely** — `grep -rcE '\b(slate|gray)-[0-9]+'
app/views` returns 0 across every file. That column has been zero since 2026-08-27 and this pass
confirms it held.

**What the zero hides is X1:** eight colour tokens live in the CSS that the kit contract does not
define, six of them in use. A directory can score 0 on the slate column and still be painted in
pre-2.0 semantics, because this measurement does not look for them.

**The last column is what separates a defect from a decision.** A directory below the line *with* an
artboard is unfinished work. One *without* is either deliberate (`legal` is verbatim by design) or a
surface nobody drew — and migrating an undrawn screen means inventing design, which is why AJU-1
needs a design pass before it needs a slice.

## 2. Is each kit component in the code?

```sh
ls app/views/components/*.html.erb                        # the partials
grep -rc "components/<name>" app lib spec                 # render sites, per partial
```

**20 kit components (0.9.0) against 16 partials, and all 16 are referenced** — lowest is 1 file,
highest is `_empty_state` at 9. Unchanged from the 2026-08-27 crossing, which is the first time this
table has been re-run without moving.

The full crossing lives in the *Kit → code* section below; four rows are open and the other sixteen
are shipped.

---

## Severity

| | Meaning |
|---|---|
| 🔴 | The revamp is not done while this stands — a designed screen with no code, or a screen the design retired that is still shipping |
| 🟡 | A real gap inside a screen that otherwise works |
| ⚪ | Debt, hygiene, dead code. Nothing is broken; something is unpaid |

---

# Cross-cutting

Findings that belong to no single flow. Fixing them once fixes them everywhere.

### X1 🟡 Off-contract tokens — six of the eight are gone, and the rest die with ACT-2

The 2.0 measurement above asks whether `slate-*`/`gray-*` survive. They do not — that column is
genuinely zero. But the `@theme` block in `app/assets/tailwind/application.css` defines **eight
colour tokens the kit's 51-token contract does not have**, and six of them are in use:

| Token | Uses in `app/` | In the kit? |
|---|---:|---|
| `success`, `success-fg` | 12 | no — the contract's word is `positive` |
| `error`, `error-fg` | 4 | no — the contract's word is `negative` |
| `background-dark`, `background-light` | 4 | no |
| `secondary` | 1 | no |
| `accent` | 0 | no — **dead** |

A screen can score 0 on the slate column and still be painted in pre-2.0 semantics.

**Partly paid 2026-08-28.** Every one of these is an exact alias of a contract token — `success` and
`accent` are `positive` to the hex, `error` is `negative`, `secondary` is `fg-default`,
`background-light`/`background-dark` are the two halves of `bg-canvas` — so migrating is a rename,
not a re-colour. What decided the scope was **where they live**: 16 of the 22 source uses are in
`positions/_positions_table.html.erb`, the file ACT-2 deletes.

- **Migrated (6 uses, 4 files):** `_public_navbar`, `_donut_chart`, `layouts/application` and
  `_asset_badge`. `layouts/application`'s `bg-background-light dark:bg-background-dark` collapses to
  a bare `bg-bg-canvas`, which already carries both halves.
- **`--color-accent` deleted** from the `@theme` — 0 uses, in either theme.
- **Left standing:** the declarations `_positions_table` still needs. They go with the file, not
  before it. Migrating them now would be re-writing 16 lines scheduled for deletion.

### X2 ✅ `bg-primary-bg` was not a token — fixed 2026-08-28

`--color-primary-bg` does not exist. Tailwind 4 generates nothing for a class whose variable is
undefined, so the avatar circle in the Ajustes hub and the icon circle on the password-reset-sent
screen have **no fill at all**.

- [`settings/show.html.erb:5`](../app/views/settings/show.html.erb#L5)
- [`password_resets/sent.html.erb:9`](../app/views/password_resets/sent.html.erb#L9)

**Fixed:** both now read `bg-primary-muted`, the token the pair was reaching for. It was listed
first because it is invisible in review and visible on screen.

### X3 🟡 Four screens are drawn and have no code at all

Counted across flows, so it does not read as four separate small gaps:

| Screen | Flow | Status |
|---|---|---|
| `TOTP · Alta` | auth | no route, no gem, no column ([CODE_CHANGES §14](CODE_CHANGES.md)) |
| `Códigos de recuperación` | auth | same |
| `Código de recuperación` | auth | same |
| `2FA` | auth | same — and `sessions_controller#create` goes straight to `dashboard_path` |
| `Seguridad` (wizard step 3 of 4) | onboarding | no route, no action, no view |
| `Movimientos` | cockpit | no route, no controller, no view |

Six, not four, once the wizard step and the observation feed are counted. The three auth screens
plus the wizard step are **one build** (ADR-018 + D52); `Movimientos` is its own.

### X4 ⚪ Six briefs disagree with their own file about the kit version they vendor

The briefs in `cockpit`, `assets`, `auth` and `discover` all close with
`kit-version-source 0.8.0`; the variable in each of those files reads **`0.8.1`**. `alerts`,
`settings` and `onboarding` are correct at `0.9.0`.

This is D53's exact shape — a number mirrored into prose that the artifact already owns. The brief
should stop restating it, the way `ui-kit.CHANGELOG.md` already stopped.

`assets.pen`'s row is genuinely stale on `master`: its brief closes with `0.8.0` against a variable
reading `0.8.1`. An earlier draft of this file blamed an unmerged branch for it; that was wrong, and
X7 records why.

### X5 ⚪ Three component masters carry a default that is residue from where the file was seeded

An instance override hides each one, so nothing renders wrong today — and the next instance someone
adds inherits the wrong default.

| File | Master | Default it carries | Should be |
|---|---|---|---|
| `cockpit.pen` | `AssetRow` (`rD21s`) | `oportunidad` | a state word (`neutral`) — every one of its 10 instances overrides it |
| `cockpit.pen` | `TopBarDetail` (`FFHXR/NijZc`) | `Nvidia` | empty — it leaks a ticker into the `Movimientos` artboard's header, which is not an asset screen |
| `discover.pen` | `TopBarDesktop` | already fixed 2026-08-27 | — |

The third row is there because it is the precedent: the same bug was found and fixed in `discover`
and never swept for elsewhere.

### X6 ✅ `PortfolioChartHelper` deleted 2026-08-28 — dead code with a passing spec

[`portfolio_chart_helper.rb`](../app/helpers/portfolio_chart_helper.rb) is one method, **zero
render sites**. It hand-computes SVG polyline coordinates and hardcodes `#10b981` / `#ef4444` — the
pre-2.0 green and red, as raw hex. D2 replaced it with `lightweight-charts`.

`spec/helpers/portfolio_chart_helper_spec.rb` had four examples pinning it, so the suite stayed green
over a file nothing rendered. **Both deleted.** The suite went 2691 → 2687 examples and line coverage
*rose* 95.37% → 95.50%, which is what removing tested-but-unreachable code looks like.

### X7 ⚪ Registry hygiene — what the retired audit's last group was really about

Its final group asked to *"retire the DONE convention in `CODE_CHANGES.md`, or qualify it"*. Read
against the tree on 2026-08-28, **the verb was never the problem**. Every `Status:` line in
`CODE_CHANGES` is accurate about its own scope — §4 *"shipped, both halves"* is true of the Activos
tab it describes, and ACT-1 is open because the empty state was never in §4's scope. The failure mode
is the one D53 names: **the record is written when a decision is taken and not re-read when reality
moves.** A better verb does not fix that; re-reading does.

Three concrete instances remain, none of them a `DONE`:

- **The `DECISIONS.md` header is wrong again** — `53 resolved · 6 open` against an actual
  `52 · 7`. This is the error D53's unshipped third fix exists to prevent, and it has now happened
  four times. **Scripting the recount is the highest-value hygiene item in the design folder**,
  because it is the only one that stops recurring on its own.
- **The `README.md` flow table still reads the `.pen`, not the ERB.** Every row says
  `done · in review`, which is true of the design file and says nothing about the code. The banner
  above it now points here, which is the honest version — but the column itself still invites the
  wrong read.
- **`origin/design/assets-brief` is superseded, not pending — and getting that wrong is the fourth
  instance of the pattern this section is about.** It carries one unique commit whose message says
  the Activos brief rewrite *"had not reached disk when #366 was committed, so the merged file
  carries the old brief"*. A hash comparison agrees: the working tree's `assets.pen` matches
  `master`'s and differs from that branch's. **Both facts are true and the conclusion drawn from
  them was wrong.** [PR #367](https://github.com/rodacato/stockerly/pull/367) was closed on
  2026-08-27 — *"wrong base … superseded by the new PR, which carries the migration, this brief, and
  the NavRow vendoring together"* — and that PR merged. `master`'s `assets.pen` contains `Holdings`
  and `D48`, so the brief there is the rewritten one; the branch's differs because its base is
  older, not because it is ahead.

  **The lesson is the section's own:** a commit message describes the world when it was written, and
  a hash proves difference, not direction. Neither is a substitute for reading what happened next.
  The branch is safe to delete.

  Its sibling `design/kit-0-8-0` was fully merged by patch-id and was deleted on 2026-08-28, along
  with `docs/reduce-footprint`. The two the old item named — `docs/pivot-self-hosted-tracker` and
  `design/discover` — were already gone. What remains is
  `chore/35-cleanup-zombie-ghost-events`, unmerged since 2026-05-15 with a single unique commit that
  edits a memory file, and two Dependabot branches. **Verify before deleting any of them.**

---

# Kit → code

`ui-kit.lib.pen` holds **20 components at 0.9.0**. Sixteen are in the code; three are not, and one
is there in the wrong shape. This section is what `COMPONENT_INVENTORY.md` was for — a screen audit
does not find these, because a screen can be faithful and still be built out of inline markup.

> **A blind spot inherited from that document, worth naming before reading the table:** it crossed
> the kit against `app/views/components/` **only**, so a component implemented flow-locally read as
> *not built*. It caught `settings/_nav_row`, `onboarding/_step_header` and `trades/_trade_row` by
> hand and missed `dashboard/_sentiment_card`, which is `MarketCard` (see KIT-2). The table below
> crosses against all of `app/views`.

| Kit component | In code | |
|---|---|---|
| `TopBar` | `components/_top_bar` | ✅ |
| `BottomNav` | `components/_bottom_nav` | ✅ |
| `SidebarNav` | `components/_sidebar_nav` | ✅ |
| `TopBarDesktop` | `components/_top_bar_desktop` | ✅ |
| `AppShellDesktop` | `layouts/app.html.erb` | ✅ composed, not a partial |
| `AssetRow` | `components/_asset_row` | ✅ (but ACT-7, CKP-5) |
| `Segmented` · `Segmented3` | `components/_segmented` | ✅ **one N-ary partial for both masters — the code is right and the kit is the compromise.** Do not mirror the split into the ERB |
| `NavRow` | `settings/_nav_row` | ✅ flow-local, 6 renders |
| `SwitchRow` | `settings/_notification_switches` | ✅ flow-local, 2 consumers |
| `Stepper` | `onboarding/_step_header` | ✅ flow-local (but ONB-1 — it counts to 3) |
| `Logo` · `LogoMark` | `shared/_logo` · `shared/_logo_mark` | ✅ |
| `MarketCard` | `dashboard/_sentiment_card` | ✅ flow-local — **KIT-2** |
| `Card` | inline, 121 lines | 🟡 **KIT-1** |
| `ButtonPrimary` · `ButtonSecondary` | inline, 62 lines | 🟡 **KIT-1** |
| `Field` | raw form helpers, 37 calls | 🟡 **KIT-1** |
| `MovementItem` | `trades/_trade_row` | 🟡 **KIT-4** — exists, but as a `<tr>` |
| `HeaderBar` | — | 🟡 **KIT-3** |

### KIT-1 🟡 The four primitives were never extracted, and the inline counts went up

`Card`, `Field`, `ButtonPrimary` and `ButtonSecondary` were the bet: the four the translation would
pay for itself on, or not. **It did not.** Every slice shipped without them, and
`bg-bg-surface` went from **99 template lines to 121** over the redesign.

That flips what the item is. Extracting them now is a change with **no slice behind it** — a
refactor of shipped, working, on-contract markup. It is a decision, not leftover work, and the
honest options are: extract them as their own pass, or accept the inline style as this codebase's
idiom and drop the four rows from the kit's expectations.

**Nothing else in this file depends on the answer**, which is why it sits at 🟡 rather than blocking.

### KIT-2 ⚪ `MarketCard` is built — the old inventory was measuring one directory

Recorded as *"Net-new, not built"*. It is `app/views/dashboard/_sentiment_card.html.erb`, rendered
from `dashboard/show.html.erb:19`: the uppercase mono label, the 4xl value, the delta line — the
kit's `MarketCard` shape. It lives in `dashboard/` rather than `components/`, which is the only
reason it read as missing.

Closed here. Left in the table so the correction is visible rather than silent.

### KIT-3 🟡 `HeaderBar` has no ERB equivalent, and the four screens behind the hub have no way back

Promoted to the kit at 0.9.0 after `settings.pen` hand-built it four times and `alerts.pen` twice.
Its artboards — `Registros`, `Estado y mantenimiento`, `Integraciones`, `Bandeja`, `Confluencia` —
all draw a back arrow, an 18px display title and an optional text action.

In code there is nothing. `admin/logs/index`, `admin/settings/show` and `admin/integrations/index`
each set `content_for(:page_title, t(".titulo"))` and stop, and `layouts/app` renders a TopBar that
is logo + bell. **So on a phone, Ajustes → Registros is a one-way trip**: no back affordance exists
except the browser gesture or jumping to another tab.

This is the one kit gap that is a navigation defect rather than a styling one. It is also small —
one partial, five render sites.

Not `TopBarDetail`: that one is cockpit-local, has a two-line ticker title and a bookmark, and was
measured against `HeaderBar` and found to be a different component.

### KIT-4 🟡 `MovementItem` exists as a table row, and the design retired the table

`trades/_trade_row.html.erb` is a `<tr>` with nine table tags, rendered from `trades/index.html.erb:113`
and `positions/_positions_table.html.erb:37`. The kit's `MovementItem` is a card row, promoted in
0.2.0 with the note *"reused for trade log rows"*, and D43 has `Historial` built from it.

**This resolves with ACT-2 and ACT-3, not before.** Both of its render sites are the two screens
those findings are about — rebuild `Historial` as the three drawn sections and the `<tr>` has no
callers left. Doing it first would mean restyling a table on a screen that is about to stop
existing.

---

# Flow by flow

## Auth — `flows/auth.pen`

**9 artboards · 5 have code · 4 do not.**

| Artboard | Code | |
|---|---|---|
| `Login` | `sessions/new.html.erb` | ✅ full i18n, split-panel desktop matches |
| `Forgot` | `password_resets/new` | ✅ |
| `Email sent` | `password_resets/sent` | ✅ (but see X2) |
| `Reset` | `password_resets/edit` | ✅ |
| `Login · Desktop` | `layouts/auth.html.erb` | ✅ brand panel left, form right |
| `2FA` | — | 🔴 nothing |
| `TOTP · Alta` | — | 🔴 nothing |
| `Códigos de recuperación` | — | 🔴 nothing |
| `Código de recuperación` | — | 🔴 nothing |

### AUTH-1 🔴 TOTP: four artboards, zero lines, and the work order is written

`grep -rn "otp\|two_factor\|2fa" app/ config/routes.rb -i` returns nothing. The order is
[CODE_CHANGES §14](CODE_CHANGES.md): a gem, a migration (`otp_secret` + enrolled-at + hashed
recovery codes), routes, and a second factor in `sessions_controller#create`, which today runs
`start_session` → `redirect_to dashboard_path` with nothing in between.

**One line of §14 said this landed after `onboarding` and `settings` were migrated. Both migrated
to kit `0.9.0` on 2026-08-27, so the queue had already drained — and `46a95aa` corrected the line
while this audit was being written.** Recorded because the conclusion is what matters and it did not
change: **TOTP is blocked by nothing in the design.** What it owes is its own 4-filter card and a
GitHub issue, which is a ticket nobody has written rather than work nobody has drawn.

### AUTH-2 ⚪ Two shipped screens have no artboard

`password_resets/expired.html.erb` and `password_resets/success.html.erb` exist, render, and are
drawn nowhere. Both are one-message screens, which is probably why — but *the design draws every
screen* is either true or it is not, and right now the flow's artboard count under-reports the
surface by two.

---

## Onboarding — `flows/onboarding.pen`

**10 artboards (6 mobile + 4 desktop) · the wizard is 4 steps in design and 3 in code.**

### ONB-1 🔴 The wizard has three steps; the design has four

[`onboarding_controller.rb:4`](../app/controllers/onboarding_controller.rb#L4) is `STEPS = 3`.
[`_step_header.html.erb`](../app/views/onboarding/_step_header.html.erb) derives *"Paso n de 3"* and
the progress percentage from that constant, so **every step label in the running app is wrong
against the design**: the artboards read `Paso 1 de 4 · 25%`, `Paso 2 de 4 · 50%`,
`Paso 3 de 4 · 75%` (Seguridad), `Paso 4 de 4 · 100%`.

There is no `onboarding/security` route, action or view. The `Seguridad` artboard (`ewGdS`) is a
card and two buttons — *Activar ahora* / *Ahora no · lo activo desde Ajustes* — and per D52 it
**offers, it does not enrol**, so it is cheap. But it cannot ship before AUTH-1: pressing *Activar
ahora* needs somewhere to go.

Sequence: AUTH-1 → ONB-1, or ONB-1 ships with the button disabled, which is the thing D13/D16/D23
keep telling us not to do.

### ONB-2 🟡 The empty first run is one of the three failures the 2.0 exists to fix, and it is unbuilt

See ACT-1. It is the Activos flow's artboard but it is the *onboarding* problem — it is what the
reader meets immediately after `Complete`.

### ONB-3 🟡 `/welcome` and `/help` are the only authenticated screens with zero i18n keys

`app/views/welcome/` and `app/views/help/` are at **0 `t(...)` lookups** and 2 token uses each; the
copy lives inline in [`shared/_welcome_body.html.erb`](../app/views/shared/_welcome_body.html.erb).
ADR-011 permits hardcoded es-MX on a surface the redesign has not reached — but this surface *has*
an artboard (`Welcome`, `Welcome · Desktop`), which is the audit's own test for unfinished work
rather than queue position.

Two drifts inside it, found while reading:

- It paints with opacity modifiers over raw utilities — `text-white`, `bg-primary/90`,
  `border-primary/20`, `bg-primary/5`, `shadow-primary/20` — where the contract has `fg-inverse`,
  `primary-hover`, `primary-muted`. `welcome/show.html.erb` is the densest instance in the app.
- The desktop brief specifies a **900px centred column** so the Guide's three cards sit side by
  side; the code is `max-w-2xl` (672px). The three cards do go side by side at `sm:`, so the
  intent survives — the width does not.

### ONB-4 🟡 Two copy divergences between artboard and code

| | Artboard | Code |
|---|---|---|
| Welcome CTA | *Ir al panel* | *Ir al Panorama* |
| Third guide card | *Configura una alerta* | *Configura una regla* |

The second is the more interesting one: **the code is right and the artboard is behind**. The tab
is *Reglas*, D13 settled the vocabulary, and *alerta* is the word the 1.0 used. Fix the artboard.

### ONB-5 ⚪ The Assets step draws four categories against the code's five

`Administration::Domain::AssetCatalog::CATALOG` has five keys and `onboarding.categorias` in the
locale has five entries — `us_stocks`, `crypto`, `etfs`, `mexican_stocks`, `fixed_income`. The
`Assets` artboard draws four; **`Acciones · México` is missing**. The brief already records this
category split as *"not a design call — the code had already made it"*, so the artboard simply
did not finish catching up.

### ONB-6 🟡 D59 — decided 2026-08-28: it stays a promise, and loses its checkmarks

**Decided: bullets instead of checkmarks, a fourth item, and the claim on its own line.** The
`Stepper` is already a correct progress indicator, so giving the checklist real state would create a
second source of truth for the same fact and require the two to agree forever — D53's shape, in
pixels.

**Measured on canvas before deciding, because where it appears decides how bad it is:** the panel
carries the checklist on `Setup · Desktop`, `Integrations · Desktop` **and** `Assets · Desktop`, and
correctly drops it on `Welcome · Desktop`. So inside the wizard a reader sees *"Paso 1 de 4 · 25%"*
beside three ticked items. On mobile the panel is not drawn at all, so this is desktop-only.

**Three artboard instances to edit:** checkmarks → bullets, insert *Protege tu cuenta* third (the
order is Integraciones · Activos · Seguridad · Listo), and split *100% libre y open source* onto its
own line.

---

## Cockpit — `flows/cockpit.pen`

**9 artboards.** Panorama, the asset detail's two tabs and Consolidado are built and faithful. One
whole screen is not.

### CKP-1 🔴 `Movimientos` — a designed screen with no route

The observation feed (`lNpAd`): date-grouped `compra`/`vende` readings with the footer *"Solo
aparecen los cruces con lectura de compra o venta"*. There is no route, no controller, no view.

The Panorama knows it: [`dashboard/show.html.erb:32-34`](../app/views/dashboard/show.html.erb#L32)
carries a comment explaining that the artboard's *"Ver más"* is **deliberately absent because no
screen lists observations**. The link is missing on purpose, pointing at a screen that was designed
and never built.

**D42 un-gated the build on 2026-08-27** — *"hagámoslas, sí planeo usarlas"* — and named the usage
metric: whether it gets opened in a week where the Panorama's 3-day window hid something. The
`NotableObservations` query it needs already exists and is capped at 3 rows over 3 days
([`notable_observations.rb:7`](../app/contexts/market_data/queries/notable_observations.rb#L7));
this screen is the surface that lifts that cap without touching the Panorama.

### CKP-2 🟡 The asset-detail chart has no range control and no OHLC readout

`Asset · Análisis` draws `1S · 1M · 3M · 1A · Máx` under the chart, plus an
`O / H / L / C / Vol` strip. Neither is in
[`market/_analysis.html.erb`](../app/views/market/_analysis.html.erb) — the chart renders one fixed
series. The Consolidado *does* have its period control
(`components/segmented` over `AssembleConsolidado::PERIODS`), so the pattern exists and this screen
did not get it.

`@price_histories` is already loaded; the range control is a filter over data in hand, not new data.

### CKP-3 🟡 `Señales` and `Más análisis` — the two blocks the data cannot support (#306)

The artboard's `Señales` block reads *current* state: `RSI (14) 72 · sobrecomprado`, the moving-average
sentence, the Bollinger sentence, distance to the 52-week range. `Más análisis` adds `DISPARADORES`
and `VOLUMEN`.

`TechnicalObservation` stores **events, not state** — nothing persists today's RSI, so the block
cannot be rendered from what exists. This is [#306](https://github.com/rodacato/stockerly/issues/306),
labelled `discovery-needed`, and it is the one genuinely blocked item in the cockpit.

The code ships `_recent_observations` (*Observaciones notables*, the event log the artboard also
draws) and `_confluence` — so the screen is not empty where `Señales` would go, it is one block
shorter.

### CKP-4 🟡 `Mi posición` is missing `Rendimiento` and `Cerrar posición` (#301)

Both are recorded in the code itself
([`_position_summary.html.erb`](../app/views/market/_position_summary.html.erb): *"Cerrar posición
is drawn beside it and still not built"*):

- **`Rendimiento`** — `12% de tu cartera` plus `1M / 3M / 1A / Total`. No per-window return series
  exists per position. The portfolio-level TWR engine does exist
  (`Trading::Domain::TimeWeightedReturn`), so the shape is not new, only its scope.
- **`Cerrar posición`** — a write flow. A sell is already a movement, so the product question is
  whether this is a shortcut or a distinct action. That is why #301 is `discovery-needed`.

The FX split the product exists for — `DEL ACTIVO +45% / DEL PESO · TC +8%` — **is built** and
reconstructs the total exactly.

### CKP-5 🟡 Radar rows carry no state chip and no semáforo dots

`components/_asset_row.html.erb` says so in its own header comment: the design draws both, the code
backs neither — the chip taxonomy does not exist and the semáforo is D3, whose engine is gated. The
Panorama artboard's rows read `neutral · estirado · renta fija` against rows that render none.

Same root as CKP-3: no persisted current state. **One fix serves both.**

### CKP-6 ⚪ The brief says the Consolidado's comparison engine is build-gated. It shipped.

`Brief · Cockpit` still reads *"its two comparison cards are designed in full but their engine is
build-gated and needs TWR, not the money-weighted period returns (D12)"*.

Measured: [`assemble_consolidado.rb:30`](../app/contexts/trading/use_cases/assemble_consolidado.rb#L30)
builds `Domain::TimeWeightedReturn`, `:40` computes `vs_cetes` against
`MarketData::Queries::CetesReinvestedReturn`, `:41` computes `vs_hold`, and
`portfolios/show.html.erb:78-100` renders both cards plus the TWR note. The gate is gone; the brief
is the last place that still says otherwise.

### CKP-7 ⚪ `market_controller#show` assigns 21 instance variables in a 52-line file, and enqueues a job on a GET

[`market_controller.rb`](../app/controllers/market_controller.rb) takes 9 values out of
`LoadAssetDetail` and then derives 7 more itself — including three direct ActiveRecord reads
(`@asset.technical_observations`, `current_user.watchlist_items`, `current_user.alert_rules`), an
inline `.where(...).order(...).limit(3)` for the rules card, and `trigger_fundamental_sync`, which
**enqueues `SyncFundamentalJob` from a read action**.

None of it crosses an ADR-002 boundary (checked: no context reaches into another's models or
gateways anywhere in the app). It is the one controller that did not move its assembly into the use
case that already exists for it.

---

## Activos — `flows/assets.pen`

**12 artboards.** The largest flow and the one with the most unbuilt surface.

### ACT-1 🔴 The empty state offers three doors; the code has one, and two of them are the product's own named fixes

`Holdings / Vacío` draws three paths out of an empty portfolio, plus a watchlist escape hatch:

| Path | Artboard copy | Code |
|---|---|---|
| Manual | *Captura lo que ya tienes · Ticker, títulos y costo promedio. 30 segundos por activo.* | ✅ the trade sheet exists |
| CSV | *Importar CSV de tu broker · GBM, Kuspit, Binance o el formato de Stockerly.* | 🔴 **nothing** — `grep -rni csv app/ lib/` returns only the admin **log export** |
| Demo | *Explorar con datos de ejemplo · Una cartera de demostración para ver cómo se lee todo.* | 🔴 **nothing** — `db/seeds.rb` seeds demo users in `development` only, and there is no in-app path |

The code renders `components/_empty_state`: an icon, a title, a body and one optional CTA. It cannot
express three paths, and the primary/`NavRow` accent the design gives *Captura lo que ya tienes*
has nowhere to land.

**Why this is the top item and not a nice-to-have:** `project_vision` names three failures the 2.0
must fix, and this artboard is two of them — *empty first-run → seeded demo* and *data-entry
fastidio → smart CSV*. Both are drawn. Neither exists. The third (*can't read indicators*) is
CKP-3/CKP-5.

Both need their own 4-filter card before a build, and CSV import in particular is a feature, not a
screen.

### ACT-2 🔴 `Historial` is designed as three sections; the code is the pre-redesign `/positions` with four tabs

The artboard (`Y6vkn`) is one scroll, three sections, no tab control: **Movimientos · Dividendos
cobrados · Posiciones cerradas**. D43 dropped *posiciones abiertas* because it duplicated Holdings.

[`positions/_positions_table.html.erb:5-17`](../app/views/positions/_positions_table.html.erb#L5)
still renders four tabs, defaulting to `open` — the tab the design deleted — as a bordered table
with hardcoded es-MX headers (`Fecha`, `Activo`, `Operación`, `Títulos`…) and `bg-primary/10`
opacity classes. The screen is at **1 i18n key**.

Three more things are wrong around it:

- The page title is `"Posiciones y movimientos"`, hardcoded at
  [`positions/index.html.erb:3`](../app/views/positions/index.html.erb#L3). The design calls it
  **Historial**.
- Both the view and [`positions_controller.rb:2-4`](../app/controllers/positions_controller.rb#L2)
  say *"the nav has four destinations"*. It has had five since #292 closed on 2026-08-27.
- `positions#update` writes `notes` and `labels` straight from the controller with no use case —
  and **neither field is drawn in any artboard**. Either the design owes them a home or they are a
  1.0 feature nobody retired.

### ACT-3 🔴 `/trades` has zero inbound links — decided 2026-08-28: `Historial` absorbs it (D60)

Measured: every `trades_path` in a **view** lives inside `app/views/trades/` itself, and the only
others are `trades_controller`'s own redirects. Nothing in the nav, the Activos screen, the
Consolidado or the asset detail links to it — `NavigationHelper` lists `trades` among the Activos
tab's controllers, so the tab lights up once you are there, but nothing takes you there. It is
reachable by typing the URL.

Behind that orphan sits the app's largest controller action — filters for `tipo`, `mercado` and
`anio`, a `distinct.pluck(EXTRACT(YEAR …))`, a 50-row cap, `@shown_count`/`@total_count` — and a
187-line view. The design's `Historial` covers the same trade log as one of its three sections.

**Decided as [D60](DECISIONS.md): `Historial` absorbs it, and the filters do not come along.**

**The capability question came back clean**, which is what made the call easy: editing and deleting a
trade live in `trades/_trade_row`, which renders from `trades/index` **and** from
`positions/_positions_table` — so both affordances already exist on the surviving screen, through
the same partial. `market/_position_trades` is read-only and loses nothing.

What it costs instead is rebuilding that inline edit/delete inside a `MovementItem` card rather than
a `<tr>` — **which is KIT-4's work, owed anyway**, not work this decision creates.

**The filters are dropped, not ported.** They are real, and they were built for a screen nobody ever
opened, which is the strongest available evidence that nothing needed them. They return with a
documented trigger.

**What lands:** the three drawn sections at `/positions`; `trades#index`, its 187-line view and the
controller's filter methods deleted; the HTML fallbacks that redirect to `trades_path` repointed.
`trades#new/create/edit/update/destroy` all stay — the sheet and the inline row flows are not this
route.

### ACT-4 🟡 The Tracked budget panel states a total; the design breaks it down by tier

Artboard: `25 llamadas · 34 activos en Tracked · 5 en Holdings · 6 en Watchlist · 23 al final`, with
*"Se gastan en ese orden. Si el presupuesto se acaba, los últimos esperan al día siguiente."*

[`assets/tracked.html.erb`](../app/views/assets/tracked.html.erb) renders `@budget.remaining`, a
progress bar and `used/limit`. The tier breakdown — which is the whole point of D9's ladder, since
the tier *is* the budget — is not rendered. `@held_ids` and `@followed_ids` are already in scope for
`tracked_tier`, so the three counts are in hand.

### ACT-5 🟡 The Tracked list has no search

The artboard draws `Buscar entre tus 34 activos` above the list and a `Ver los 28 restantes` foot.
The code renders every tracked asset with no filter and no truncation.
`assets#search_ticker` exists but serves the *add* form (`Tracked · Buscar`), which is a different
control: that one searches the catalogue to add, this one filters what you already track.

### ACT-6 🟡 `Tracked · Buscar` — one state of the artboard is unverified

The artboard shows results tagged with their tier (`Watchlist` / `Siguiendo` vs `Seguir`) plus the
foot *"¿No está en la lista? Da de alta el activo…"*. `assets#search_ticker` and `_track_form`
exist; whether the results carry the tier state was not read line by line in this pass. Listed as
**unverified**, not as a gap.

### ACT-7 ✅ The row-subtitle clip — the other half fixed 2026-08-28

D46 recorded it. `assets/_tracked_row.html.erb` wrapped correctly; `components/_asset_row.html.erb`
still truncated — and that is the row the Panorama Radar, Holdings and Watchlist all render, so the
fragility had been fixed on the one screen that reported it and left on the three that share the
component. **`truncate` is gone**; the subtitle wraps and the row grows, which is what D46 decided
for its twin.

### ACT-8 ⚪ `assets.pen` draws advice copy that ADR-0001 forbids — 11 instances

Every `AssetRow` and `WatchRow` in `assets.pen` carries the chip **`oportunidad`** — master *and*
all instances. `discover.pen`'s finding N1 rejected exactly that word on `WaveRow` for exactly this
reason, and `cockpit.pen` overrides its master to state words (`neutral`, `estirado`,
`renta fija`) on every instance.

So the vocabulary was settled twice and `assets.pen` did not get the pass. The code renders no chip
at all, which is why nothing shipped wrong — but the artboard is the spec, and as drawn it specifies
a violation.

---

## Reglas y avisos — `flows/alerts.pen`

**5 artboards.** Reglas and the Bandeja are the closest match in the app. Two gaps.

### ALR-1 🔴 `Confluencia` is a screen in the design and a partial in the code

The artboard (`N0Uajy`) is a standalone screen reached from Reglas: three lights with their
provenance (*Se calcula hoy con technical_observations* / *Motor pendiente* / *Se calcula hoy con
trend_scores*), a **`Ventana de confluencia · 5 días`** control, and a
**`Convertir en regla · próximamente`** action.

In code, `market/_confluence.html.erb` renders the three lights **inside the asset detail**. There
is no `/confluence` route, no link from `/alerts`, no window control and no rule conversion.

**This was carried as an open TODO for three days and it was already fixed:** the item said the artboard *"still carries the
notice 'El semáforo está diseñado, no construido'"* and asks for it to be fixed before anyone builds
from it. Read on 2026-08-28, the artboard now says *"Hoy se leen por separado: nada las combina
todavía, y la ventana de abajo es diseño, no motor"*, marks light 2 `próximamente` with
*Motor pendiente*, and gates the conversion action. The artboard was fixed; the TODO item was not
updated.

What remains is the real question, which is D3's: the screen is honest now, and it is still a screen
that mostly says *not yet*. Building it before the engine means shipping a route whose payload is a
disclaimer.

### ALR-2 🟡 The empty state drops the suggested rules, which is the entire reason it is an artboard

`Reglas / Vacío` exists as its own artboard — rather than as a string swap like `Bandeja / Vacío` —
**specifically because it carries different content**: a `A PARTIR DE LO QUE YA TIENES` block with
three rules derived from what you hold, each with a `Crear` button:

- *AAPL cae 5% en un día* — `Tienes 12 títulos · % cambio en el día`
- *NVDA entra en sobrecompra* — `RSI(14) por encima de 70`
- *Tus CETES 28d están por vencer* — `Vence el 18 sep · subasta de Banxico`

[`alerts/_empty_rules.html.erb`](../app/views/alerts/_empty_rules.html.erb) renders an icon, a title
and a sentence. The suggestion engine — read positions, pick conditions that apply, pre-fill the
sheet — does not exist.

Everything it needs does: the seven rule kinds, `alert_condition_summary`, the position list, and
CETES maturity dates. It is assembly, not new data.

### ALR-3 ⚪ The artboard still draws a channel the product deleted

`reglas-lista` draws *Avisos en la app · Campana y push del navegador*. `browser_push` was dropped
on 2026-08-25 (D16, #293); `alert_preferences` has exactly two booleans and the code renders exactly
two switches. **The design is the side that has to move**, and this has been carried as
an open item since 2026-08-25, alongside AJU-5.

Grouped here with the `Trabajos` badge (AJU-4) and the `oportunidad` chips (ACT-8): three artboard
edits, one sitting.

---

## Ajustes — `flows/settings.pen`

**8 artboards.** Every screen behind the hub exists. The hub itself is missing one row, and the
screen it links to was never redesigned.

### AJU-1 🔴 `/profile` is the largest un-redesigned surface in the app, and the hub links to it twice

The design's premise is *one Ajustes, no admin zone* — `/profile` and `/admin` merged into one hub
(D5). The hub was built. `/profile` was not retired, and
[`settings/show.html.erb:19-22`](../app/views/settings/show.html.erb#L19) sends *Nombre y correo*
and *Contraseña* straight into it.

What is behind that link:

- **No artboard.** Not drawn in any flow.
- **0 i18n keys** against 64 token uses — the only authenticated screen with a form and no lookups.
- A pre-2.0 shape: a 2-column grid with an `IdentityCard` sidebar and four tabs
  (`Información · Seguridad · Preferencias · Datos y sesión`), 262 lines across five partials.
- **Duplicated controls.** `profiles/_preferences_tab.html.erb` (118 lines) renders *Apariencia y
  región*, *Moneda preferida* and *Avisos* — the same three the hub renders via
  `settings/_appearance` and `settings/_notification_switches`. Two screens, two implementations,
  one set of settings.
- One control that exists in neither the hub nor any artboard: **Zona horaria**.
- `_identity_card` renders counts (*Posiciones abiertas · Activos en watchlist · Reglas activas*)
  drawn nowhere.

This is the D5 merge, left half-done: the destination was built and the origin was never closed.
Deciding it needs a design pass, because *Nombre y correo* and *Contraseña* have to land somewhere —
inline in the hub, or in two small screens that get drawn.

### AJU-2 🔴 The hub has no `Seguridad` row (D52)

The `Hub` artboard draws it under **Cuenta**, third row: *Verificación en dos pasos · TOTP y
códigos de recuperación*. The code's Cuenta section has two rows and stops.

Blocked by AUTH-1 in the same way ONB-1 is — the row needs a destination.

### AJU-3 ✅ D58 — shipped 2026-08-28: Moneda auto-saves

Measured in the code, not inferred: `theme_controller` writes to `localStorage` on click,
`toggle_controller` POSTs the notification switches on toggle, and **Moneda is a form with an
explicit `Guardar` submit**. Two identical-looking segmented pills, two different commit models,
nothing on screen distinguishing them.

**Shipped** — [CODE_CHANGES §15](CODE_CHANGES.md). Not for symmetry: the currency changes what every
number on every screen means, so a form you can forget to submit leaves you reading MXN while
believing you switched. The theme has no equivalent failure — it applies visibly on click. And
`admin/settings` had already settled the same question the same way, so this is the hub catching up
to a convention rather than inventing one.

⚠ **One correction to the brief and to D58's own recommendation, both of which said the toggle
pattern applies unchanged.** It does not.
[`toggle_controller.js`](../app/javascript/controllers/toggle_controller.js) is boolean by
construction — it reads whether `bg-primary` is present, flips classes, and PATCHes
`{field: true|false}`. Moneda is a two-value enum, so this needs a small sibling controller that
sends a *value* (~30 lines). Cheap, but the entry said free.

The screen drops from **three** commit models to two: instant-local (theme) and instant-server
(currency, switches). The artboard draws no `Guardar`, so design and code converged with no artboard
edit.

**One thing the new controller does that `toggle` does not: it reverts on a rejected value.** The
pill is the only place the choice is visible, so leaving it on a value the server refused would
report a state the instance does not have. `toggle` should do the same and does not — its own
item, not this one's.

### AJU-4 ⚪ The `Estado y mantenimiento` artboard still carries a warning its own brief retired

The artboard (`TeLgy`) renders: *"Los primeros dos interruptores hoy se guardan pero no apagan nada:
ningún job ni mailer los consulta. Se conectan antes de implementar esta pantalla (D17)."*

The brief above it says `✅ D17 IS FIXED`. Verified in code, all three toggles are live:

| Toggle | Read by |
|---|---|
| `auto_sync_enabled` | [`jobs/concerns/pausable_sync.rb:13`](../app/jobs/concerns/pausable_sync.rb#L13) |
| `email_notifications_enabled` | [`mailers/alert_mailer.rb:34`](../app/mailers/alert_mailer.rb#L34) — and deliberately not on `ApplicationMailer`, so a password reset cannot be switched off |
| `maintenance_mode` | [`application_controller.rb:30`](../app/controllers/application_controller.rb#L30) |

The brief was corrected and the canvas was not. This is the D53 rot **on the artboard**, which is
the one surface no `grep` reaches — and it is the copy an implementer would build from.

### AJU-5 ⚪ The `Trabajos` badge: settled, and the artboard still draws a count

Decided (no badge — a cross-database `SolidQueue::FailedExecution` count in the hub's request path
aborted the transaction in test) and written into the code as a comment. The artboard draws a
number the screen will not have. One edit, grouped with ALR-3.

---

## Descubrir — `flows/discover.pen`

**3 artboards.** The closest design↔code match in the app, and the only flow built after its own
artboards were finished. Two small items and no gaps.

### DSC-1 🟡 `Ver las 17 canastas →` is a link in the design and a sentence in the code

[`discover/show.html.erb:72-74`](../app/views/discover/show.html.erb#L72) states the count instead
of linking it, with a comment saying there is no screen behind it. Same shape as CKP-1: an artboard
drew a link before its destination existed.

Unlike CKP-1, this one has no D42 behind it. It is either a fourth screen with its own card, or the
artboard drops the arrow. **Cheapest honest answer: drop the arrow.**

### DSC-2 ✅ The stale comment — rewritten 2026-08-28

[`discover/show.html.erb:13`](../app/views/discover/show.html.erb#L13) reads *"Olas, reportes and
titulares all read Alpaca (D31)"*. *Reportes* was dropped from the product on 2026-08-27, and the
two briefs that record it disagree about which decision did it — `discover.pen` cites **D46**,
the decision that dropped it was **D47**. `DECISIONS.md`'s D46 is the BMV `Tracked · Sin fuente`
finding, so the brief is mis-citing by one.

### DSC-3 ⚪ D56 should be closed as *not a defect* — both its measurements read the wrong token

D56 is the open finding that says two pairs fall below AA and that fixing them ripples across the
kit and the ERB. **Re-measured 2026-08-28 against the token values and the nodes themselves, both
claims dissolve, and they dissolve the same way: `$primary` and `$primary-hover` were treated as one
token.** They are not — `primary` is `#5B6CFF` / `#7B89FF`, `primary-hover` is `#4757E3` / `#9098FF`.

**(a) The Aviso card's heading.** D56 says it measures 4.24:1 in dark "because `info-fg`/`info-bg`
in dark are token-identical to the primary pair D41 rejected". Queried on canvas, the heading node
is `fill: $info-fg`, 15px/700, on a `$info-bg` parent. `info-fg` dark is `#9098FF`, which equals
**`primary-hover`**, not `primary` (`#7B89FF`).

**(b) The `SidebarNav` active item.** D56 says it is `bg-primary-muted text-primary`, citing
`_sidebar_nav.html.erb:10`. That line reads
`bg-primary-muted font-semibold text-primary-hover`, and the kit's own `SidebarNav` master fills
its active icon and label with `$primary-hover`. Neither the code nor the kit uses `text-primary`
here.

Contrast, computed from the token values (WCAG 2.x relative luminance):

| Pair | Light | Dark | AA body (4.5:1) |
|---|---:|---:|---|
| `info-fg` on `info-bg` — what the artboard draws | 4.96:1 | 5.01:1 | ✅ passes |
| `primary-hover` on `primary-muted` — what the SidebarNav uses, kit and code | 4.96:1 | 5.01:1 | ✅ passes |
| `primary` on `primary-muted` — the pair D41 rejected, used by neither | 3.68:1 | 4.24:1 | ❌ fails |

The two numbers D56 reports — **3.68:1 and 4.24:1** — are exactly the third row. They are correct
arithmetic about a pair that is not on the screen. D41's rejection already did its job; D56 measured
the rejected pair and attributed the result to the pair that replaced it.

**Recommended: close D56 with this measurement, and drop the kit-wide token change from the
backlog.** Worth re-deriving before acting — it is arithmetic, and arithmetic is what produced the
entry being corrected.

---

# Surfaces the code ships and the design never drew

Not defects — an inventory, because *"every screen has an artboard"* is the test the audit uses to
tell unfinished work from a decision, and these are the rows where the test cannot be applied.

| Surface | i18n | Note |
|---|---:|---|
| `/profile` | 0 keys | AJU-1 — the one that matters |
| `/privacy`, `/terms`, `/risk-disclosure` | 0 keys | legal; deliberately verbatim, per S5 |
| `/help` | 0 keys | shares `_welcome_body` with `/welcome`, which *is* drawn |
| `/report-bug` | 0 keys | |
| `/trades` (index) | 16 keys | ACT-3 — and unreachable |
| `password_resets/expired`, `password_resets/success` | via `auth.*` | AUTH-2 |
| `shared/maintenance` | 0 keys | |
| `/admin/jobs` | — | Mission Control, third-party, correctly undrawn |

---

# Design-side work — the `.pen` is the side that has to move

Collected so they can be one sitting rather than seven interruptions.

| # | File | Edit |
|---|---|---|
| ACT-8 | `assets.pen` | `oportunidad` → state words, master + 11 instances |
| ALR-3 | `alerts.pen` | drop the `Avisos en la app` channel toggle |
| AJU-4 | `settings.pen` | delete the retired D17 warning from `Estado y mantenimiento` |
| AJU-5 | `settings.pen` | drop the `Trabajos` count badge |
| ONB-4 | `onboarding.pen` | *Configura una alerta* → *una regla*; *Ir al panel* ↔ *Ir al Panorama*, pick one |
| ONB-5 | `onboarding.pen` | add the fifth category, `Acciones · México` |
| X5 | `cockpit.pen` | `AssetRow` master default; `TopBarDetail`'s leaked `Nvidia` |
| X4 | 4 briefs | stop restating `kit-version-source` |
| DSC-1 | `discover.pen` | drop the `Ver las 17 canastas →` arrow, or card the screen |
| DSC-2 | `discover.pen` brief | D46 → D47 |

None of these is a decision. All ten are the record catching up to something already settled.

---

# Code smells and technical debt

Ordered by what they cost to leave.

### TD1 ✅ — fixed 2026-08-28

[`trades_controller.rb`](../app/controllers/trades_controller.rb) (227 lines, the largest controller
in the app) carries this shape **six times**, near-verbatim, in `create`, `update` and `destroy`:

```ruby
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: turbo_stream.prepend("flash_messages",
      partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
  end
  format.html { redirect_to <path>, alert: message }
end
```

**Fixed.** `respond_with_alert(message, fallback:)` collapses all six, `flash_stream(type, message)`
carries the fragment the success paths also built by hand, and `find_trade_or_redirect` absorbs the
preamble `edit` and `confirm_destroy` shared. The controller went **227 → 202 lines** with no
behaviour change; the catch-all in `create` keeps its plain redirect, because routing it through the
helper would start answering Turbo requests with a stream that action never sent.

**Done now rather than with ACT-2 on purpose:** D60 deletes `trades#index` and the filter methods,
not `create` / `update` / `destroy`, which is where all six blocks live.

### TD2 — Six user-facing strings hardcoded in `trades_controller`, four more in `positions_controller`

`"Movimiento no encontrado."`, `"Movimiento actualizado."`, `"Movimiento eliminado."`, the
`trade_notice` composition, `"Cartera no encontrada."`, `"No encontramos la posición."`,
`"Actualizamos la posición."`, `"No pudimos actualizar la posición."`

ADR-011 puts controller error strings on i18n. `sessions_controller` already does it
(`t("auth.flash.…")`), so the pattern is established and these two controllers are the holdouts.

**Split 2026-08-28, and neither half was done.** `positions_controller`'s four strings go with
ACT-2's rebuild, so writing keys for them now is work for a screen being replaced.
`trades_controller`'s six survive D60 and are genuinely owed — they were kept out of this batch so it
stayed a refactor with no copy changes, which is what let the suite prove it.

### TD3 ⏸ — deferred to ACT-2, deliberately

Filter parsing, `filter_side`, `filter_currency`, the year `pluck`, the 50-row cap and the two
counts all live in the controller, reading `current_user.portfolio.trades` directly. `positions`,
`alerts`, `assets`, `market`, `dashboard` and `portfolios` all call a `UseCase` or a `Queries::*`.
This is the one that did not.

**Not fixed, and that is the call:** D60 deletes `trades#index` and these exact methods with it.
Extracting a query object for code scheduled for deletion is the waste this tracker exists to
name.

### TD4 ⏸ — deferred to ACT-2, and it is a product question first

`position.update(notes:, labels:)` plus a `parse_labels` that splits, strips, dedups and caps at 10
— domain rules in a controller private method.

**Deferred, because the refactor is the second question.** Neither `notes` nor `labels` is drawn in
any artboard, so whether they survive at all is part of ACT-2's rebuild. Extracting a use case for
two fields that may not exist next week is work done twice.

### TD5 — `market_controller#show`

See CKP-7. 21 assignments, three inline AR reads, a job enqueued from a GET.

### TD6 ✅ — done. See X6.

### TD7 🟡 — partly done. See X1: 6 of 22 uses migrated, `accent` deleted, 16 left in the file ACT-2 removes.

### TD8 ✅ — done. See X2.

---

# The finish line

What actually stands between here and *the 2.0 revamp is done*, in the order that unblocks the most.

## Decisions owed before anything is built

**Three were answered on 2026-08-28** and are struck through below rather than deleted, so the list
reads as a record instead of a snapshot.

| | Question | Whose |
|---|---|---|
| ~~D58~~ | ~~Tema vs Moneda commit split~~ | ✅ **shipped** — Moneda auto-saves (AJU-3, §15) |
| ~~D59~~ | ~~The Brand Panel checklist~~ | ✅ promise, no checkmarks, four items (ONB-6) |
| ~~ACT-3~~ | ~~Does `Historial` absorb `/trades`?~~ | ✅ it does, without the filters — **D60** |
| D57 | Does `Movimientos` / `Movimientos de interés` take the word `Señales`? Note ADR-013 blessed the current name | Adrian |
| AJU-1 | Where do *Nombre y correo* and *Contraseña* live once `/profile` goes? | design pass |
| D3 | The confluence engine — gates CKP-3, CKP-5 and ALR-1 | 4-filter card |
| D33 | The Calendario's horizon, deliberately left for its builder | Adrian |
| D15 | Urgency per rule — decided in principle, unbuilt | — |
| D55 | The password reset is a mail-dependent recovery path ADR-018's own reasoning rejects | Adrian |
| KIT-1 | Extract `Card` / `Field` / the two buttons as their own pass, or accept inline as this codebase's idiom and drop them from the kit's expectations | Adrian |

**Five open decisions in `DECISIONS.md`** — D3, D15, D33, D55, D57 — recounted from the file on
2026-08-28 after D58, D59 and D60 landed. Recount it; never increment it (D53).

## Builds, in dependency order

1. **AUTH-1** — TOTP with recovery codes. Unblocks ONB-1 and AJU-2. Owes its 4-filter card and issue;
   ADR-018 already approves the decision. Four artboards drawn, zero code.
2. **ONB-1 + AJU-2** — the wizard's fourth step and the hub's Seguridad row. Small, once 1 lands.
3. **ACT-1** — the three-door empty state. The two missing doors are the product's own named fixes;
   each needs its own card.
4. **AJU-1** — retire `/profile` into the hub. Needs the design pass first.
5. **ACT-2** — rebuild `Historial` as the three drawn sections, and delete `/trades#index` with it.
   **Unblocked 2026-08-28 (D60).** Closes KIT-4 and collapses TD1, TD2 and TD3 into the rebuild
   rather than refactoring code that is about to go. Owes a `CODE_CHANGES` work order.
6. **CKP-1** — `Movimientos`. Un-gated by D42, metric stated, query exists.
7. **ALR-2** — suggested rules in the empty state. Assembly over data already in hand.
8. **CKP-2** — the chart's range control. Data already loaded.
9. **KIT-3** — the `HeaderBar` partial. One component, five render sites, and it closes a
   navigation dead-end: the four screens behind the Ajustes hub have no back affordance on a phone.
10. **ACT-4, ACT-5** — the Tracked budget breakdown and list search.
11. **CKP-3, CKP-5, ALR-1** — everything that waits on persisted indicator state (#306 / D3). One
    engine, three screens.
12. **CKP-4** — `Rendimiento` and `Cerrar posición` (#301).
13. **#176** — in-app account deletion. Unblocked (`user.destroy` no longer raises), unbuilt, and the
    hub currently tells the reader to send an email.

## Free wins — no decision, no card

**Paid 2026-08-28:** X2 · X6 (=TD6) · TD1 · TD8 · DSC-2 · ACT-7 · X1/TD7 in part.

**Still open, all canvas except one:** X5 · X4 · AJU-4 · AJU-5 · ALR-3 · ONB-4 · ONB-5 · CKP-6 are
`.pen` edits — they need Adrian at the canvas to save. TD2's `trades_controller` half is the only
code left on this line.

**Deliberately not paid:** TD3 and TD4 refactor code D60 and ACT-2 delete. Doing them now is work
done twice, and saying so is cheaper than doing it.

**One of them is worth doing before the rest, because it is the only item that stops an error from
recurring:** D53's third fix — scripting the `DECISIONS.md` header recount. The header has been
wrong four times now, including today (X7). Everything else on this line is a one-time edit; this
one is a hook.

Plus two registry corrections that **remove** work rather than adding it:

- **DSC-3** — close D56 and drop the kit-wide contrast change from the backlog. Both pairs pass AA;
  the entry measured a token neither the kit nor the code uses.
- **KIT-2** — `MarketCard` is built. The gap was an artefact of crossing the kit against one
  directory.
- **KIT-4** — `MovementItem` needs no work of its own. Both its render sites are the screens ACT-2
  and ACT-3 replace, so it resolves with them or not at all.

---

# What this audit could not check

Stated so a reader does not take silence for coverage.

- **Nothing was rendered.** Every finding is a read of source or of a `.pen`, never a screenshot. The
  three verifications `CODE_CHANGES §0b` owes — typography in a browser, the trade sheet on a real
  iPhone, `/assets` behind Cloudflare — are still owed and are still not checkable from here.
- **The specs were not run.** Coverage and green-ness are unmeasured in this pass; the only test
  finding is X6, which is a spec over dead code and needed no run.
- **ACT-6** was not read line by line and is marked unverified rather than closed.
- **Seven external verifications remain open** in
  [`docs/research/market-data-providers-2026-08.md §6`](../docs/research/market-data-providers-2026-08.md)
  — not four, as the last handoff carried. They need network and credentials: DataBursatil's terms
  of service, `/v2/emisoras` filtering, `descargas archivo=guber`, the Alpha Vantage OSS grant, Alpha
  Vantage's BMV coverage via `.MEX`, DataBursatil's `tasas`/`divisas`/`cables`/`noticias`, and
  whether any sanctioned alternative to Yahoo exists for MX indices and corporate actions.

## One thing that is more finished than the record says

The **backdated-FX refinement is built**, and more than one document still carries it as open.

[`fx_rates_controller.rb`](../app/controllers/fx_rates_controller.rb) resolves
`FxRateHistory.quote_on(base:, quote:, date:)` — the most recent published rate at or before the
trade's own date — the trade sheet re-fetches it whenever the date or currency changes
(`trade_sheet_controller.js:13`), and `ExecuteTrade` accepts it as
`override:` and persists it as `fx_rate_at_execution`
([`execute_trade.rb:15-18`](../app/contexts/trading/use_cases/execute_trade.rb#L15)).

That is exactly what the `Registrar movimiento` artboard promises: *"Se guarda el tipo de cambio del
día de la operación: por eso tu rendimiento en MXN es real y no cambia mañana. Puedes editarlo."*
The multi-currency P0 has no residual.
