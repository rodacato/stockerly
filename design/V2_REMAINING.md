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

Two tables. **Both re-run on 2026-08-28 against `423425f`**, after TOTP and the Historial rebuild
landed (the ADR-019 commit between them touches no `app/views`, and re-running returned the same numbers) — the commands are printed so the next pass counts the same way, and so re-measuring is
always cheaper than trusting the numbers.

**What moved since the first pass:** `positions` went from 1 i18n key to 16 and from the pre-redesign
table to the drawn screen; `trades` went 76 → 36 token uses as its index was deleted, and 16 → 33
keys; `two_factor` and `totp_enrollments` are new and were 2.0 from birth. **The list of directories
still carrying hardcoded copy did not change**: `profiles`, `shared`, `welcome`/`help`,
`bug_reports`, `legal` and the mailers.

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
| `assets` | 0 | 40 | 49 | ✅ 2.0 | yes |
| `components` | 0 | 56 | 13 | ✅ 2.0 | the kit |
| `dashboard` | 0 | 20 | 18 | ✅ 2.0 | yes |
| `discover` | 0 | 25 | 17 | ✅ 2.0 | yes |
| `layouts` | 0 | 10 | 4 | ✅ 2.0 | the shell |
| `market` | 0 | 186 | 100 | ✅ 2.0 | yes |
| `notifications` | 0 | 9 | 11 | ✅ 2.0 | yes |
| `onboarding` | 0 | 47 | 34 | ✅ 2.0 | yes — gained the Seguridad step |
| `password_resets` | 0 | 14 | 20 | ✅ 2.0 | 3 of 5 |
| `portfolios` | 0 | 16 | 23 | ✅ 2.0 | yes |
| `positions` | 0 | 13 | 16 | ✅ 2.0 | **yes — rebuilt as Historial 2026-08-28** |
| `sessions` | 0 | 2 | 10 | ✅ 2.0 | yes |
| `settings` | 0 | 32 | 24 | ✅ 2.0 | yes |
| `setup` | 0 | 2 | 12 | ✅ 2.0 | yes |
| `totp_enrollments` | 0 | 15 | 12 | ✅ 2.0 | yes — new 2026-08-28 |
| `trades` | 0 | 36 | 33 | ✅ 2.0 | the sheet; the index is gone |
| `two_factor` | 0 | 8 | 13 | ✅ 2.0 | yes — new 2026-08-28 |
| `profiles` | 0 | 64 | **0** | ◐ copy | **no** — AJU-1, the last big one |
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

**20 kit components (0.9.0) against 15 partials, and all 15 are referenced** — lowest is 1 file,
highest is `_empty_state` at 9. It was 16 until 2026-08-28: `_asset_badge` lost every render site
when the trade rows became cards and went with them (X6).

The inline primitives moved the wrong way again, which is KIT-1's whole argument: `bg-bg-surface` is
at **123 template lines** (99 when first counted, 121 a day ago) and `bg-primary` at 60.

The full crossing lives in the *Kit → code* section below; four rows are open and the other sixteen
are shipped.

---

## Where this stands — 2026-08-29

Counted from this file, never incremented — the commands are printed for the same reason the other
two tables print theirs. The third derives `DECISIONS.md`'s header, which lives here because that
file's columns have been wrong seven times from being carried forward.

```sh
grep -cE '^### [A-Z]+[0-9-]'    design/V2_REMAINING.md   # every finding heading
grep -oE '^### [^ ]+ [✅🔴🟡⚪]' design/V2_REMAINING.md | awk '{print $NF}' | sort | uniq -c
# DECISIONS: parse the verdict COLUMN, not the row — a resolved entry may cite an open Dn
python3 -c "import re;rows=[l for l in open('design/DECISIONS.md') if re.match(r'^\| \*\*D\d+\*\* \|',l)];v=[re.search(r'[✅⏳]',l.strip().strip('|').split('|')[3]) for l in rows];print(len(rows),'entries',sum(1 for m in v if m and m.group()=='✅'),'resolved',sum(1 for m in v if m and m.group()=='⏳'),'open')"
```

| | Findings | |
|---|---:|---|
| ✅ closed | **23** | shipped or measured away |
| 🔴 open | **9** | ACT-1 · CKP-1 · CKP-8 · ALR-1 · AJU-1 · X9 · X10 · X11 · X12 |
| 🟡 open | **22** | a real gap inside a working screen |
| ⚪ open | **17** | debt and hygiene, mostly `.pen` edits |
| — open | **2** | `TD2` and `TD5` carry no severity glyph — see below |

**71 headings carry a glyph and 73 findings exist.** It opened at 53 with
[#386](https://github.com/rodacato/stockerly/pull/386). **Sixteen were added on 2026-08-29 by one
review** — `X9`–`X20` and `CKP-8`–`CKP-11`, from measuring the three screens that answer the daily
question (Panorama, Activos, `/market/:symbol`) against their code rather than against their
artboards. Before that: `KIT-5` out of building `KIT-3`, then `X8`, `TD9` and `TD10`. The two outside
the tally are `TD2` (hardcoded controller strings, a real finding of its own) and `TD5` (a pointer to
`CKP-7`, not an independent one); assigning them a severity is a call, not a count, so they are shown
rather than absorbed.

**The count went up, and that is the finding.** Every previous revision of this block reported the
list shrinking. This one nearly doubled the open reds, because the review looked at a layer earlier
audits had not: not *does the code match the artboard*, but *does the data the code reads exist and
mean what the screen implies*. Four of the five new reds are data-shape defects invisible to a
screen-by-screen audit — `X10` in particular describes a capability with a single non-visual
consumer, which is exactly the kind of thing a walk through the views cannot see.

**`DECISIONS.md`: 72 entries · 68 resolved · 4 open** — D3, D15, D33 and D64. **This block
previously listed D55 and D57 as open and they are both resolved**, and gave a stale entry total;
that file's header carried the same two errors. D68–D70 were raised and resolved on 2026-08-29 by a
panel consultation, which is why the open count fell rather than rose. Run the third command above;
do not adjust the old numbers.

**What the nine reds are.** Five predate this review: `ACT-1` (the empty state's CSV and demo doors),
`CKP-1` (`Movimientos`, un-gated by D42), `ALR-1` (`Confluencia` as a screen, gated on D3's engine),
and `AJU-1` (retire `/profile` into the hub). Four are new and three of those share one root — the
app keeps thirty days of price history (`X9`), so the indicators it already computes never run in
their full mode, and the nightly writer discards the ones it does compute (`X10`). `CKP-8` is a
product gap rather than a data one: the two references a buy-or-sell decision needs are both in the
database and neither is on the screen that needs them. `X11` and `X12` are consistency defects across
the three screens.

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

**Mostly paid.** The 16 uses in `positions/_positions_table` went with the file on 2026-08-28
(ACT-2), which was always the plan. What the earlier pass found and paid:

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

### X3 🟡 Drawn screens with no code — one left of six

Counted across flows, so it does not read as four separate small gaps:

| Screen | Flow | Status |
|---|---|---|
| `TOTP · Alta` | auth | no route, no gem, no column ([CODE_CHANGES §14](CODE_CHANGES.md)) |
| `Códigos de recuperación` | auth | same |
| `Código de recuperación` | auth | same |
| `2FA` | auth | same — and `sessions_controller#create` goes straight to `dashboard_path` |
| `Seguridad` (wizard step 3 of 4) | onboarding | no route, no action, no view |
| `Movimientos` | cockpit | no route, no controller, no view |

**Five of the six shipped on 2026-08-28.** The three auth screens, `2FA` and the wizard step were
one build (ADR-018 + D52), which is how they were built — [#391](https://github.com/rodacato/stockerly/issues/391),
[CODE_CHANGES §14](CODE_CHANGES.md).

**`Movimientos` is the one left**, and it was always its own: un-gated by D42, the query exists, and
nothing about TOTP touched it. See CKP-1.

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

### X6 ✅ Dead code with a passing spec — four instances found and removed 2026-08-28

**The pattern kept recurring, and twice the deletion created the next one.** Recorded together
because the shape is the finding: a file nothing renders, kept green by a spec that asserts it
works rather than that anything uses it.

| | How it died |
|---|---|
| `PortfolioChartHelper` | zero render sites; D2 replaced it with `lightweight-charts` |
| `TradesHelper#trades_summary_by_currency` | lost its only call site when `/trades` went (ACT-2) |
| `components/_asset_badge` | lost **every** render site when the trade rows became cards (KIT-4) |
| `Trading::UseCases::LoadPortfolio` + `UpcomingDividendsPresenter` | lost their only caller when Historial replaced `/positions` |

`logo_spec`'s badge block went with the third, including an example that visited the asset detail and
asserted the symbol appeared — **which passes whether the badge exists or not.**

⚠ **Two near-misses, and they are the more useful half.** The same sweep almost took
`PeriodReturnsCalculator` and `Position#total_gain`, both of which had lost their production callers.
Neither is dead: `time_weighted_return_spec`'s *"diverges exactly where D12 said it would"* contrasts
the money-weighted calculation against TWR, so the calculator is **the executable form of D12's
argument**; and `multi_currency_audit_spec` uses `total_gain` to pin which methods are
currency-aware. **A callerless object is not automatically dead — a spec that documents a decision
is a consumer.** Both were restored before commit.

The original entry, kept:

####  `PortfolioChartHelper` deleted 2026-08-28 — dead code with a passing spec

`portfolio_chart_helper.rb` is one method, **zero
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

### X8 ✅ Four code changes shipped ahead of their artboards — closed 2026-08-29 (#417)

**This file's usual finding is the code trailing the design. These four are the inverse**, which is
the harder one to notice: the screens still look right, and the `.pen` is quietly describing a
product that has moved. Logged the day it happened rather than discovered in the next audit, and
**worked the same day** — three of the four are drawn; the fourth turned out to have no artboard to
update at all, which is D64.

| Flow | What the code does now | What the artboard still shows |
|---|---|---|
| ✅ `settings.pen` | The Ajustes hub's *Tus datos* section opens the importer — [`settings/show.html.erb`](../app/views/settings/show.html.erb) | **Drawn 2026-08-29** on both the mobile and desktop hubs, as a `NavRow` carrying the same label and description as the Activos door |
| ✅ `settings.pen` | Yahoo serves ticker search, at 30/min instead of 5 | **Drawn 2026-08-29** on all three Integraciones artboards. Its card had read *3 / 5 por minuto* — which matched the database and **not** `ProviderDefaults`, where the figure was 6 |
| ✅ `assets.pen` | The importer's unknown-symbol screen is a checkbox list with a bulk action | **Drawn 2026-08-29.** `Símbolos desconocidos` now lists nine checked rows with a *Todos / ninguno* toggle, replacing the chip grid. The uniform per-row source label is **D63** |
| `assets.pen` | Ticker search answers company names, and *Agregar activo* autofills Sector | **Nothing to update — the form is not drawn.** `Tracked · Buscar` is the *list filter*, not the typeahead. Two shipped changes have no artboard: **D64** |
| ⏳ `alerts.pen` | The bulk alta ends in a **system notification** — *Di de alta N símbolos de tu archivo* | `reglas-bandeja.png` draws no row for it. Found while auditing: the file was not open, so it is left rather than risked |

**Closed with three drawn and one converted to a decision.** The fourth was not skipped: the
*Agregar activo* typeahead has no artboard to update, so it became **D64** rather than a task. A
fifth artboard was drawn that this entry never predicted — the Bandeja's row for the bulk-alta
notification — because auditing *what else did we move* is what found it.

**What this pass did not do:** `settings.pen` has no `grid-*` variables and its brief still carries
**seven dated lines** from before the Log/brief split existed. A `Log · Ajustes` frame now exists and
today's entries went into it, so the pollution stopped growing — migrating the seven, and reflowing
the bands onto the grid, is left as its own pass because a reflow moves artboards and invalidates
every export in this flow.

**A correction to this entry's own first draft.** It closed by asserting *"D62 is untouched and still
open — the door still names three brokers the engine cannot read."* **Both halves were false.** D62
was resolved on 2026-08-28, and `assets.pen`'s middle door has read *Importar movimientos* ever
since; the claim was copied from a branch whose `design/` predated that. This is X7's own lesson —
*a record describes the world when it was written* — committed inside the entry whose subject is
keeping the record honest, which is the strongest argument for the counting script that section
asks for.

**And then the correction itself carried a second false claim, caught the same way.** Its first
draft added that `design/exports/activos-holdings-vacia.png` was *"genuinely stale and still shows
the three named brokers"*. It is not: re-exporting the artboard produced a **byte-identical file**,
so the committed PNG has been current since D62 landed. Both errors came from reading a branch whose
`design/` predated master and not re-checking against the tree in front of me — the same root cause,
twice, inside eight lines. Verifying is cheap; remembering is what is expensive.

What did not change: the architecture record. [ADR-017's amendment](../docs/architecture/adr/0017-python-bridge-for-yahoo-finance.md)
carries the provider swap and the raised ceiling, TD9 carries what is left of Alpha Vantage.

**And the audit for "what else did we move" turned up a bug nothing in this session caused.**
`reglas-bandeja.png`'s last row reads *Sincronización de precios reanudada · Alpha Vantage volvió a
responder tras 2 horas*. **Alpha Vantage has never served prices.** It is registered
`capabilities: %i[fundamentals]` and nothing else; prices come from Alpaca, Finnhub, CoinGecko,
DataBursatil and Yahoo. The row attributes a price outage to the one provider that could not have
caused it — a plausible sentence that is wrong on the fact it exists to report, which is the kind of
copy a reader has no way to catch. It is also the second place TD9 has to visit: retiring Alpha
Vantage would leave this row naming a provider the instance no longer has. 🐞 Fix it in `alerts.pen`
in the same pass as the notification row above.

### X9 🔴 Thirty days of price history — the floor every indicator stands on

[`BackfillPriceHistoryJob::DAYS`](../app/jobs/backfill_price_history_job.rb#L8) is `30`, and
[`RecordPriceHistory`](../app/contexts/market_data/handlers/record_price_history.rb) adds one row a
day going forward. No job prunes the table, so a series does grow — but an asset added last month
has about thirty bars, and that is the number every downstream calculation actually sees.

Measured against what the app already computes:

| Needs | Bars | Available |
|---|---:|---|
| RSI(14) | 15 | ✅ |
| Bollinger 20×2σ | 20 | ✅ |
| MACD(12,26,9) | 35 | ❌ |
| SMA50 | 50 | ❌ |
| SMA200 | 200 | ❌ |
| 52-week range | ~252 | ❌ locally |

**The consequence is not theoretical.** `TrendScoreCalculator` switches to its five-factor blend at
**≥35 closes** and otherwise falls back to RSI + momentum
([`trend_score_calculator.rb:22`](../app/contexts/market_data/domain/trend_score_calculator.rb#L22)).
Its two callers ask for `recent(30)` and `recent(50)` against a table holding ~30 — so **MACD, the
EMA crossover and the volume factor have never once been computed in production.** The code exists,
it has specs, and it has never run on real data. That is X10's other half.

**Widening it has a trap that must be fixed in the same change.**
[`BackfillMissingHistoriesJob::MIN_HISTORIES`](../app/jobs/backfill_missing_histories_job.rb#L10) is
`7`: the weekly orchestrator only re-fetches assets holding **fewer than seven rows**. Raise `DAYS`
alone and new assets get the wider window while every asset already tracked stays at thirty
permanently. The threshold has to move with the window.

**And one gateway needs a step added.**
[`YfinanceGateway::PERIODS`](../app/contexts/market_data/gateways/yfinance_gateway.rb#L20) tops out
at `365 => "1y"` and `period_for` falls through to `"max"` above that — so asking for 400 days
downloads the asset's entire history, decades of it for a US large cap. Alpaca is unaffected
(`fetch_daily_bars` takes a date range and paginates), but it requests `feed: "sip"`, which is not
in every Alpaca plan; **that one is a fact to establish with a live call, not by reading.**

The chain itself is already right and already fires on add: `BackfillHistoryOnAssetCreation`
listens for `AssetCreated`, and `attempt` walks the registry — Alpaca, then Yahoo for US;
DataBursatil for BMV; CoinGecko for crypto. Only the window is wrong.

**One gateway will not take the wider window, and it was found by making the change rather than by
planning it.** `DAYS` feeds *every* historical source.
[`CoinGeckoGateway#fetch_historical`](../app/contexts/market_data/gateways/coingecko_gateway.rb#L54)
passes `days` straight through as a `market_chart` query param, and CoinGecko's free and demo tiers
cap that range at **365 days** — so a 400-day request is expected to be refused for the one asset
class it serves. Crypto backfill would start failing where it currently succeeds. **This is D71**,
because the fix is a shape decision and not a constant: either each gateway clamps to its own
ceiling, or `DAYS` becomes per-asset-type. Alpaca and DataBursatil take `(from, to)` ranges and are
unaffected.

**Resolved 2026-08-29 — `DAYS` moved to 365 and neither mechanism was needed (D71).** 400 calendar
days is ~276 trading sessions against 365's ~252, and the deepest window the app asks for is SMA200
at **200 rows**, so nothing it computes notices the difference. 365 is also exactly CoinGecko's
ceiling, so one global constant is honoured by every registered source. The table grows a row a day
and is never pruned, so the initial fetch only has to cover day one.

**The `>= 35` gate is gone too, and it was withholding more than MACD.** `TrendScoreCalculator`
computed nothing beyond RSI and momentum below 35 closes — but `ema_crossover` needs only **21** and
`volume_trend` only **20 volumes**, so all three were gated behind the strictest one's requirement.
Each factor now gates on its own minimum and `blend_5_factor` already renormalised over whatever was
present, so the change was to delete the branch rather than to write one. A reading below a factor's
mathematical minimum is still refused rather than approximated — `EMA26` cannot be seeded from 20
points, and a number there would be invented. `FACTORS` minus a reading's own keys is what it is
missing.

### X10 🔴 The nightly job computes every indicator factor and throws it away

`trend_scores` has a **`factors` jsonb column**, and `TrendScoreCalculator.calculate` returns
`{ score:, label:, direction:, factors: }` where `factors` carries `rsi`, `momentum`, and — in
five-factor mode — `macd`, `volume_trend` and `ema_crossover`. Two writers disagree about it:

| Writer | Window | Volumes | Persists `factors` |
|---|---|---|---|
| [`RecalculateTrendScoreOnPriceUpdate`](../app/contexts/market_data/handlers/recalculate_trend_score_on_price_update.rb) | `recent(50)` | yes | ✅ |
| [`CalculateTrendScoresJob`](../app/jobs/calculate_trend_scores_job.rb#L14) | `recent(30)` | no | ❌ omitted from `create!` |

The job runs nightly at 11:30pm and `Asset#latest_trend_score` orders by `calculated_at DESC`, so
each night the poorer row becomes the latest reading. The richer one is still in the table; nothing
reads it either — `trend_scores` has exactly one consumer, `Alerts::Domain::AlertEvaluator`, and it
reads `.score` only. No view has ever rendered a factor.

**This is what corrects CKP-3 and [#306](https://github.com/rodacato/stockerly/issues/306).** That
issue states the `Señales` block "would have to either compute the indicators at render time or
persist a daily snapshot, which is a new table and a new job". **The table exists, the column
exists, the nightly job exists, and the calculator already produces every value the block needs.**
What is missing is that one writer drops the payload and no reader was ever written. The
architectural discovery the issue asks for is largely already answered by the schema.

### X11 🔴 The same asset is ordered three different ways on three screens

| Screen | Order | Source |
|---|---|---|
| Activos · Cartera | `order(:id)` — insertion order, i.e. none | [`load_assets.rb:44`](../app/contexts/trading/use_cases/load_assets.rb#L44) |
| Activos · Watchlist | `created_at: :desc` | same file |
| Panorama · Radar | maturity first, then `-change.abs` | [`assemble_panorama.rb:117`](../app/contexts/trading/use_cases/assemble_panorama.rb#L117) |

The Radar's ordering is deliberate and defensible — it is a "what moved today" list. The other two
are not orderings at all, and no screen offers a control. Six holdings appear in three sequences
across three screens, so positional memory of your own portfolio is impossible to form. **D68.**

### X12 🔴 Two row components put different meanings in the same visual slot

[`_asset_row`](../app/views/components/_asset_row.html.erb) ends in `money_cell(amount)` — **what you
hold is worth**. [`_watch_row`](../app/views/components/_watch_row.html.erb) ends in
`format_currency_mx(asset.current_price)` — **what one unit costs**. Same position, same font, same
weight, different kind of number.

On Activos the two never meet: they are separate tabs. **On the Panorama they are interleaved in one
list** — [`dashboard/show.html.erb`](../app/views/dashboard/show.html.erb) renders `asset_row` for a
`:position` entry and `watch_row` for a `:watchlist` entry inside the same Radar, with nothing
distinguishing them. A right-aligned column where `$48,200` is a holding and `$182.50` is a quote is
a misreading waiting to happen.

The same discontinuity runs vertically: Activos · Cartera never shows a price, and the asset
detail's `Análisis` tab never shows your amount, so the leading number changes meaning as you
navigate between them. **D69.**

**Amended 2026-08-29 — measured in the `.pen`, and the diagnosis was wrong about whose defect this
is.** `cockpit.pen` has **no `WatchRow` component at all**, and its Panorama artboard's radar is five
`AssetRow` instances (AAPL, NVDA, BTC, VOO, CETES) — all holdings. `WatchRow` is flow-local to
`assets.pen`, and `ui-kit.CHANGELOG.md` says so explicitly: *"One flow — promote only if a second
needs it."*

**So the design never drew a mixed radar.** The interleaving of positions and watchlist rows in one
list is something the code does and no artboard backs — not drift between two versions of the same
idea, but a screen the code invented. That makes D69's radar clause a decision about a list the
design has not yet accepted, which is worth knowing before it is built.

### X13 🟡 "Hoy" is two different numbers on the same screen

Rows use `asset.change_percent_24h` — a rolling 24-hour figure from the provider.
[`_patrimonio_strip`](../app/views/dashboard/_patrimonio_strip.html.erb) uses `summary.day_gain`,
computed by `PortfolioSummary`. Both are labelled *hoy* and rendered within one viewport of each
other on the Panorama, and they have no reason to agree — a rolling window and a calendar day are
different questions.

### X14 🟡 The sparkline and the chart disagree about what window they draw

[`sparkline_heights`](../app/helpers/sparkline_helper.rb#L5) takes **7 points**; the asset detail's
chart takes **30 days**. Both are silhouettes of the same series with no scale, so a row and the
screen it links to imply different shapes of the same asset. Neither states its window.

### X15 ⚪ `sparkline_heights` runs one query per row

[`sparkline_helper.rb:5`](../app/helpers/sparkline_helper.rb#L5) calls `PriceSeries.for(asset)` from
inside the row partial, so the Radar issues six and Activos issues one per holding. `PriceSeries`
does have a `loaded?` path that reuses an eager-loaded association — neither caller preloads
`asset_price_histories`, so it never takes it. Invisible at ten assets; still the wrong shape.

### X16 ⚪ `trend_scores` grows without bound

`RecalculateTrendScoreOnPriceUpdate` is subscribed to price updates and `create!`s a row each time.
High-priority stocks sync every 5 minutes ([`recurring.yml`](../config/recurring.yml)), and the
nightly job adds one more per asset. The only cleanup entry in `recurring.yml` is
`cleanup_old_logs`, which covers `SystemLog`. Nothing prunes this table.

### X17 ⚪ The CSP still authorizes TradingView; the widget it was for is gone

[`content_security_policy.rb`](../config/initializers/content_security_policy.rb) permits
`https://s3.tradingview.com` in `script_src`, `https://*.tradingview.com` plus its websocket in
`connect_src`, and `frame_src`. D2 rejected the iframe and CODE_CHANGES §3b records the widget's
removal; the permissions stayed. Either they are removed or they are used deliberately — **D66
decides which**, and this entry closes with it.

### X18 ⚪ Provenance and the `≈` conversion exist only on the detail

[`_asset_price`](../app/views/components/_asset_price.html.erb) shows the approximate value in your
preferred currency and a caption naming which provider supplied the number. Neither row component
carries either, and the watchlist mixes currencies without converting (D10 is why — every value
names its own). Consistent with D10; worth a deliberate call rather than an omission, since
"where did this number come from" is the one question this product's screens exist to answer.

### X19 🟡 `PriceSeries#recent(n)` counts calendar days; both callers read it as rows

[`recent(days)`](../app/contexts/market_data/queries/price_series.rb) is
`since(days.days.ago.to_date)` — a **date window**, not a row count. Its only two callers are the two
`trend_scores` writers, and both use it to satisfy a threshold expressed in *closes*:
`TrendScoreCalculator` needs **≥ 35 closes** for five-factor mode and `volume_trend` needs ≥ 20
volumes.

A stock trades about five days in seven, so `recent(50)` yields roughly **35 rows** — sitting exactly
on the threshold, where two market holidays inside the window silently drop the asset back to the
two-factor blend. Crypto trades seven days a week and clears it comfortably. **The same call returns
a different mode depending on the asset class and the calendar**, and nothing reports which one ran.

`PriceSeries#latest(n)` already exists and takes *n rows*. Switching the two writers to it is the
fix; it is a behaviour change to both and belongs in its own commit, not folded into X10.

**Found by fixing X10, not by auditing** — the same pattern as `TD9`/`TD10`. Aligning the two
writers put both on the same call and made the ambiguity visible; reading either one alone had not.

### X20 ⚪ A missing volume is scored as zero

`volume` is nullable on `asset_price_histories`, and both `trend_scores` writers do
`pluck(:volume).map(&:to_f)` — which turns `nil` into `0.0` rather than excluding the row. A gap in
volume data therefore drags `volume_trend` toward a reading it did not earn, instead of degrading to
the factor being absent. Pre-existing and shared by both writers; noted, not fixed, because the
honest alternative (drop the factor when volumes are incomplete) is a scoring decision.

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
| `HeaderBar` | `components/_header_bar` | ✅ — its `Accion` slot is **KIT-5** |

### KIT-1 🟡 The four primitives were never extracted — un-gated by D61, which picked the shape

`Card`, `Field`, `ButtonPrimary` and `ButtonSecondary` were the bet: the four the translation would
pay for itself on, or not. **It did not.** Every slice shipped without them, and
`bg-bg-surface` went from **99 template lines to 124** over the redesign — 123 before `KIT-3` added the `HeaderBar`, which is a bar and not a card.

That flips what the item is. Extracting them now is a change with **no slice behind it** — a
refactor of shipped, working, on-contract markup. It is a decision, not leftover work, and the
honest options were: extract them as their own pass, or accept the inline style as this codebase's
idiom and drop the four rows from the kit's expectations.

**Answered 2026-08-28 by [D61](DECISIONS.md): extract, and `rounded-2xl` is the shape.** The
measurement that settled it is why this stalled three times — of the 124 lines, **70 carry a border
and a radius in one `class` attribute**, splitting **45 `rounded-2xl` · 23 `rounded-xl` · 2
`rounded-lg`** (which sums to exactly 70), and only 26 of them share `p-5`. There is no *one* Card, which is
what a partial taking a radius and a padding argument would have encoded. The majority shape wins,
the `rounded-xl` sites are drift corrected as they are touched, and the six files putting
`bg-bg-surface` on a `<header>`/`<nav>` are out of scope — those are bars.

**Still nothing else in this file depends on it**, so it stays 🟡: unblocked, not urgent.

### KIT-2 ✅ `MarketCard` is built — the old inventory was measuring one directory

Recorded as *"Net-new, not built"*. It is `app/views/dashboard/_sentiment_card.html.erb`, rendered
from `dashboard/show.html.erb:19`: the uppercase mono label, the 4xl value, the delta line — the
kit's `MarketCard` shape. It lives in `dashboard/` rather than `components/`, which is the only
reason it read as missing.

Closed here. Left in the table so the correction is visible rather than silent.

### KIT-3 ✅ `HeaderBar` — shipped 2026-08-28, and the dead end is closed

Promoted to the kit at 0.9.0 after `settings.pen` hand-built it four times and `alerts.pen` twice.
Its artboards — `Registros`, `Estado y mantenimiento`, `Integraciones`, `Bandeja`, `Confluencia` —
all draw a back arrow, an 18px display title and an optional text action.

In code there is nothing. `admin/logs/index`, `admin/settings/show` and `admin/integrations/index`
each set `content_for(:page_title, t(".titulo"))` and stop, and `layouts/app` renders a TopBar that
is logo + bell. **So on a phone, Ajustes → Registros is a one-way trip**: no back affordance exists
except the browser gesture or jumping to another tab.

This was the one kit gap that was a navigation defect rather than a styling one.

**Shipped as `components/_header_bar`, and it is four render sites, not five.** Counting the
artboards gave six instances; counting the code gives four. `Integraciones · Estados` is a state of
the `Integraciones` artboard rather than a second screen, and `Confluencia` has no route at all —
it is ALR-1. The four are `admin/logs`, `admin/settings`, `admin/integrations` (back to the hub)
and `notifications` (back to Reglas, per D13).

**It replaces the mobile `TopBar` rather than sitting above it** — the artboards draw one bar or
the other, never both — so it carries the `h1` that `layouts/app` otherwise emits `sr-only`. The
layout picks between the two on `content_for?(:header_bar)`, and the same condition stands the
sr-only heading down, which is why the h1 count per breakpoint did not move.

Not `TopBarDetail`: that one is cockpit-local, has a two-line ticker title and a bookmark, and was
measured against `HeaderBar` and found to be a different component.

### KIT-5 ✅ The `HeaderBar` action slot — answered 2026-08-28: the body keeps it on desktop

The kit's third slot — `Accion`, 44 tall, icon plus an optional label — was **deliberately not
built** with KIT-3, and the reason is worth keeping rather than rediscovering.

Two of the four screens draw an action, and both already have that control in the code:
`Registros` draws `download` (icon-only, label disabled) and the export-CSV link exists in the body;
`Bandeja` draws `check-check` with a label and *Marcar todas* exists the same way. Moving either
into the bar looks like pure fidelity — **and it would delete the control on desktop**, because
`HeaderBar` is `lg:hidden` and there is no `Registros · Desktop` or `Bandeja · Desktop` artboard
saying where the action goes there. `settings.pen` drew desktop variants for the Hub, Integraciones
and Estado y mantenimiento; the two screens that have an action are the two it skipped.

A slot with no consumer is not a partial worth shipping either, so the local was removed rather
than left unused.

**Answered 2026-08-28: the action stays in the body on desktop, and no artboards are owed.**
Drawing `Registros · Desktop` and `Bandeja · Desktop` only to relocate a control that is already
correctly placed buys nothing — the bar exists to give a phone a way back, and on desktop the
sidebar already is the way back. The slot ships if and when a screen needs an action that has no
home in its body.

**One more thing the artboards owe.** `Bandeja` never overrode the master's placeholder label — it
still reads `Acción` where the screen means *Marcar todas*. That is a `.pen` edit, and it belongs to
whoever answers the paragraph above.

### KIT-4 ✅ `MovementItem` is a card — shipped 2026-08-28 with ACT-2

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

### AUTH-1 ✅ TOTP — shipped 2026-08-28 (#391)

`grep -rn "otp\|two_factor\|2fa" app/ config/routes.rb -i` returns nothing. The order is
[CODE_CHANGES §14](CODE_CHANGES.md): a gem, a migration (`otp_secret` + enrolled-at + hashed
recovery codes), routes, and a second factor in `sessions_controller#create`, which today runs
`start_session` → `redirect_to dashboard_path` with nothing in between.

**Shipped in two slices on 2026-08-28** — the login second factor, then enrolment from both entry points D52 named. The record is [CODE_CHANGES §14](CODE_CHANGES.md).

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

### ONB-1 ✅ The wizard has four steps — shipped 2026-08-28

[`onboarding_controller.rb:4`](../app/controllers/onboarding_controller.rb#L4) is `STEPS = 3`.
[`_step_header.html.erb`](../app/views/onboarding/_step_header.html.erb) derives *"Paso n de 3"* and
the progress percentage from that constant, so **every step label in the running app is wrong
against the design**: the artboards read `Paso 1 de 4 · 25%`, `Paso 2 de 4 · 50%`,
`Paso 3 de 4 · 75%` (Seguridad), `Paso 4 de 4 · 100%`.

**Shipped.** `OnboardingController::STEPS` is 4, `onboarding/security` exists, and the step sits
between the assets step and the summary. It **offers and lets the reader skip**, per D52 — blocking
first boot on a phone the reader may not have in hand is the trap. It is step 3 rather than step 1
so the recovery codes land next to a wizard already invested in.

The sequencing held: AUTH-1 shipped first, so *Activar ahora* had somewhere to go rather than
shipping disabled, which is the thing D13/D16/D23 keep telling us not to do.

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

### ONB-4 ✅ Copy divergences — six, not two, all aligned 2026-08-28

| | Artboard | Code |
|---|---|---|
| Welcome CTA | *Ir al panel* | *Ir al Panorama* |
| Third guide card | *Configura una alerta* | *Configura una regla* |

**Applied — and reading the locale turned two divergences into six.** Every one has the same shape:
the code names the destination and the artboard says a generic *panel*, or the artboard uses the
1.0's word. The code is right in all six.

| Artboard said | Code says | Where |
|---|---|---|
| *Configura una alerta* | *Configura una regla* | Welcome ×2 |
| *Ir al panel* | *Ir al Panorama* | Welcome CTA ×2 |
| *Lanzar e ir al panel* | *Lanzar e ir al Panorama* | Complete |
| *Ir al panel sin sincronizar* | *Ir al Panorama sin sincronizar* | Complete |

The tab is *Reglas*, D13 settled that vocabulary, and *alerta* is the word the 1.0 used. This is the
artboard following the code — the documented exception `assets.pen` already took for D48, and
correct for the same reason: the copy shipped first and reads better.

Exports re-shot for Welcome, Welcome · Desktop and Complete.

### ONB-5 ⚪ The Assets step draws four categories against the code's five

`Administration::Domain::AssetCatalog::CATALOG` has five keys and `onboarding.categorias` in the
locale has five entries — `us_stocks`, `crypto`, `etfs`, `mexican_stocks`, `fixed_income`. The
`Assets` artboard draws four; **`Acciones · México` is missing**.

**Measured 2026-08-28 rather than deferred on a hunch, and the measurement found a product question
underneath.** The mobile artboard is 390×844 with its `Col` already at 793, and a two-item group
costs ~119px (what `CRIPTO` costs), so the artboard has to grow past 844 — allowed, since D7 is a
floor and `Welcome` is already 915, but it is an artboard resize plus the desktop `Form Panel`, not
a copy fix.

**The real blocker is what the group would show.** The catalogue's only two MX entries are
`GENIUSSACV.MX` (Genius Sports) and `IVVPESO.MX` (iShares S&P 500 in MXN) — a sports-betting
company and a repackaged US index. Featuring those as *Acciones · México* on the screen that shapes
a first run is a product call in C1 Lucía's lane, not a catch-up edit. **Either the catalogue's MX
entries change or the group does; drawing what is there today would ship a recommendation nobody
made.**

### ONB-6 ✅ D59 — applied 2026-08-28: it stays a promise, and lost its checkmarks

**Decided: bullets instead of checkmarks, a fourth item, and the claim on its own line.** The
`Stepper` is already a correct progress indicator, so giving the checklist real state would create a
second source of truth for the same fact and require the two to agree forever — D53's shape, in
pixels.

**Measured on canvas before deciding, because where it appears decides how bad it is:** the panel
carries the checklist on `Setup · Desktop`, `Integrations · Desktop` **and** `Assets · Desktop`, and
correctly drops it on `Welcome · Desktop`. So inside the wizard a reader sees *"Paso 1 de 4 · 25%"*
beside three ticked items. On mobile the panel is not drawn at all, so this is desktop-only.

**Applied to all three panels**, and the exports re-shot. The `Brand Panel` is `space_between`, so
promoting the claim from a `Checklist` item to a panel-level `Claim` text pins it to the bottom on
its own — no spacer, no variant.

**Verified against the committed file, not against `git status`** — which showed nothing while the
first write was still in flight, exactly as the method warns. `Protege tu cuenta` 1 → 4 (the
`Seguridad` title plus three new rows), `100% libre y open source` **5 → 5** (moved, not
duplicated), icon names `check` 32 → 20 and `minus` 0 → 12, which is 3 panels × 4 rows.

⚠ **The `Brand Panel` is hand-built three times** and this edit had to be applied three times
because of it. That is the `HeaderBar` shape — built four times in `settings.pen`, twice in
`alerts.pen`, promoted to the kit at 0.9.0 on two consumers. **Three consumers is past that bar.**
Not promoted here, because the method says not to promote unasked; logged so the next edit to this
panel is the last one that costs three.

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

**Amended 2026-08-29 — the filter has nothing to filter.** `1A` and `Máx` are the two ranges the
artboard leads with, and X9 measures the table at ~30 bars. The control is buildable today and
would render four identical charts and a fifth. It is gated on X9, not on effort — and the
`O/H/L/C/Vol` strip is unaffected: `asset_price_histories` carries all five columns per row.

### CKP-3 🟡 `Señales` and `Más análisis` — blocked on a reader, not on a schema (#306)

The artboard's `Señales` block reads *current* state: `RSI (14) 72 · sobrecomprado`, the moving-average
sentence, the Bollinger sentence, distance to the 52-week range. `Más análisis` adds `DISPARADORES`
and `VOLUMEN`.

`TechnicalObservation` stores **events, not state** — nothing persists today's RSI, so the block
cannot be rendered from what exists. This is [#306](https://github.com/rodacato/stockerly/issues/306),
labelled `discovery-needed`, and it is the one genuinely blocked item in the cockpit.

The code ships `_recent_observations` (*Observaciones notables*, the event log the artboard also
draws) and `_confluence` — so the screen is not empty where `Señales` would go, it is one block
shorter.

**Amended 2026-08-29 — the paragraph above is right about `TechnicalObservation` and wrong about the
conclusion it draws, and the heading changed with it.** Everything said about events-not-state holds:
`persist_if_fresh` really does apply a weekly cooldown, and `indicator_snapshot` really is the reading
at the crossing. What does not hold is *"so the block cannot be rendered from what exists"* — that
reasoning searched `technical_observations` and stopped. **`trend_scores` is a daily indicator-snapshot
table and it has existed all along**: a `factors` jsonb column, a nightly `CalculateTrendScoresJob`, and
a calculator that already produces RSI, momentum, MACD, the EMA crossover and a volume factor. X10 has
the measurement.

So #306's Definition of Done asks for a decision — *"computed per request, or a daily snapshot with its
own job"* — that the schema answered before the issue was written. What is actually owed is smaller and
more specific: **one writer stops dropping its payload (X10), the window gets wide enough for the
five-factor mode to ever run (X9), and someone writes the reader.** The staleness requirement in the DoD
survives intact and matters more here than it did — `factors` is dated by `calculated_at`, and a
three-day-old MACD presented in the present tense is exactly what ADR-014's panel warned about.

**How this was missed is the useful part.** The issue was written while building the Análisis scroll,
from the observations table outward, and `trend_scores` was never in frame because its only consumer is
`Alerts::Domain::AlertEvaluator` reading `.score` — no view has ever touched it. A capability with one
non-visual reader is invisible to an audit that walks screens. That is the same shape as D53: the
conclusion was current with what had been looked at, not with what exists.

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

**Amended 2026-08-29 — the shared root is real and it is not what this said.** Per X10 the state
*is* persisted, in `trend_scores.factors`, which carries a `label` and a `direction` per asset per
day — the two fields a row chip would render. The semáforo's third light stays gated on D3's
engine; the **chip does not**, and it was blocked on a taxonomy that turns out to be a column.

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
### CKP-8 🔴 The asset detail has no anchor — the two references a decision needs are both present and neither is legible

The screen answers *what is this asset doing*. It does not answer *what is it doing *relative to
me**, which is the question that precedes every buy and every sell. Both references exist in the
database already:

- **What you hold** — `position.avg_cost` is rendered in
  [`_position_summary`](../app/views/market/_position_summary.html.erb), in the third cell of a
  three-column grid, on the **`Mi posición` tab**. The current price lives on the *other* tab. So
  "am I above or below my own cost" costs a tab switch and a subtraction. For an owner who averages
  down deliberately, that is the primary reading of the screen, and it is the one arrangement that
  makes it hardest to take.
- **What you only watch** — `alert_rules` carries `condition` + `threshold_value`, so *"tell me if
  it drops below 150"* is already settable and already fires.
  [`_asset_rules`](../app/views/market/_asset_rules.html.erb) lists those rules **as prose with an
  active/paused pill** and never renders the distance to the threshold. The watchlist rows do not
  mention them at all. The anchor exists as data and is drawn as text.

Note what `entry_price` is and is not. `watchlist_items.entry_price` is captured in a
`before_create` from `asset.current_price` and surfaces as *"sigues +X%"*
([`assets_helper.rb:45`](../app/helpers/assets_helper.rb#L45)). That is **the price when you started
watching** — a reference point, not a target. `_asset_rules`'s own comment says *"no target price
exists anywhere in the code"*, and it is right: the alert threshold is the closest thing, and it was
never read as one.

**No migration is implied.** Holding → `avg_cost`; watching → the active rule's `threshold_value`;
both → position within the 52-week range (CKP-9). Three anchors, three columns that already exist.

**Amended 2026-08-29 while designing it — this entry understated the finding, and in the direction
that matters.** It said the two references are in the database and neither is on the screen. True,
and incomplete: **`cockpit.pen`'s `Asset · Análisis` artboard already draws the whole anchor**, as a
`VS. TU PLAN` block with three rows — `Tu costo · 120 → +53% · +MXN 61,000`, `Meta · 200 → faltan
+9%`, and `Regla · vender si RSI>70 3 días → día 1 / 3`.

The code ships **one of those three rows**, and on the wrong tab. `market/_asset_rules` renders only
the rules, and `show.html.erb` mounts it inside **Mi posición**, while the artboard puts the block in
**Análisis** — where the price it anchors actually lives. `Mi posición`'s own artboard draws no
`VsPlan` at all, so the code's placement matches no artboard.

**And the dropped row nobody explained is the load-bearing one.** `_asset_rules`'s comment justifies
dropping `Meta` (*"no target price exists anywhere in the code"* — correct, and D67 settles it), and
says nothing about `Tu costo`, which `position.avg_cost` has backed all along. So this is not a
design gap to fill; it is **an implementation that shipped a third of a designed block** and a
comment that accounted for one of the two omissions.

### CKP-9 🟡 The 52-week range is registered, filled by two providers, and hidden in an accordion

`fifty_two_week_high` and `fifty_two_week_low` are registered metrics
([`metric_definitions.rb:128`](../app/contexts/market_data/domain/metric_definitions.rb#L128)) in
category `:risk`, populated by `AlphaVantageGateway` and `FmpGateway`. They are **not** in
`SUMMARY_METRICS` ([`fundamentals_helper.rb:76`](../app/helpers/fundamentals_helper.rb#L76)), so they
appear only behind *Ver todos* — and there as two bare numbers rather than as **where the price sits
between them**, which is the reading that answers *"is this expensive right now"*.

[#306](https://github.com/rodacato/stockerly/issues/306) already names this as its cheap half,
buildable without any of that issue's blocked work. **Amended 2026-08-29: it was already drawn, and
in the worst possible place.** The artboard carried a full `DISTANCIA A MÁX/MÍN 52 SEM` row — track,
marker, `mín 108 / máx 190` and the sentence *"A 3% de su máximo de 52 semanas"* — **inside the
`Señales` block**, which is the one block #306 says cannot be built. The single buildable row was
tied to the blocked ones. Hoisted out to sit under the price as `Rango52` on 2026-08-29, so #426
ships on its own. This entry is now a move, not a build. Two caveats it does not name: **crypto has no
values** (CoinGecko does not fill them, and `ath_price` is a different question), and there is **no
local fallback** until X9 lands — a 52-week range computed from thirty bars would be a lie with a
number's formatting.

### CKP-10 🟡 Fundamentals are ten bare numbers behind a popover that costs ten clicks

`SUMMARY_METRICS` is a fixed ten, identical for every equity, with the remaining ~26 in a *Ver
todos* accordion. [`_metric_card`](../app/views/market/_metric_card.html.erb) already carries a
per-metric teaching popover with *¿Qué mide?* and *¿Cómo leerlo?* — good copy, and it asks the
reader to open it ten times to read one screen. The owner reports not knowing how to use the block
at all, which is the honest measurement of that design.

D36 drew the line that constrains the fix: interpretive chips are built **only where the threshold
can be written down and defended**, because *"a chip that invents a threshold is worse than no chip
— it reads as analysis and is a guess"*. That rules out *caro* / *barato*. It does not rule out
**comparison against the metric's own history**, which is a fact rather than a judgement, and
[`PeHistoryCalculator`](../app/contexts/market_data/domain/pe_history_calculator.rb) already computes
exactly that shape for P/E over 90 days. **D70.**

### CKP-11 🟡 `news_articles` is synced every 30 minutes and read by nobody

`SyncNewsJob` runs every 30 minutes in production ([`recurring.yml`](../config/recurring.yml)) and
`SyncArticles` writes rows carrying `related_ticker`. The table has a dedicated index on
`(related_ticker, published_at)` — built for exactly one query, *"news for this symbol"* — and that
query does not exist anywhere in the app. Grepped: the only reader of `NewsArticle` is the writer.
Descubrir does not use it either; its single mention of news is in a comment.

So the instance spends provider quota every half hour filling a table with no consumer, while the
asset detail has no answer to *"did something happen that I missed"*. D31 deleted `/news` as a
listing and was right to — a river of headlines is the bubble Descubrir exists to leave. **Per-symbol
news on the asset detail is a different screen and a different question**, and the schema was already
shaped for it.


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

### ACT-2 ✅ `Historial` shipped 2026-08-28 as the three drawn sections

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

### ACT-3 ✅ `/trades` is gone — Historial absorbed it 2026-08-28 (D60)

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

**The label is the other half, and it matters more than it looks.** The artboard says
`PRESUPUESTO DIARIO · FUNDAMENTALES`; the code says `Presupuesto de hoy` (`assets.tracked.presupuesto_titulo`).
The design names **which** budget, and that is the accurate one: the panel reads
`FundamentalsBudget`, whose `PROVIDER` is hardcoded to `"Alpha Vantage"` — so it has never shown
"today's calls", it has shown one provider's fundamentals quota. Adopting the design's label is a
one-line locale change and it is a precondition for TD9: retiring Alpha Vantage retargets this
panel, and a title that already says what it counts survives that, while *Presupuesto de hoy* does
not.

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

### AJU-2 ✅ The hub has its `Seguridad` row — shipped 2026-08-28

The `Hub` artboard draws it under **Cuenta**, third row: *Verificación en dos pasos · TOTP y
códigos de recuperación*. The code's Cuenta section has two rows and stops.

**Shipped.** The row reads the account's real state rather than only offering the feature: it points at enrolment when the factor is off and at the codes when it is on, and its description says how many recovery codes are left.

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

**The new controller reverts on a rejected value**, because the pill is the only place the choice is
visible and leaving it on a value the server refused would report a state the instance does not
have. `toggle` did not do this; **it does now** — same contract, fixed 2026-08-28 in the same pass
that found it.

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

### DSC-3 ✅ D56 closed as *not a defect* — decided 2026-08-28

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

**Both halves paid.** `positions_controller`'s four strings went with the rebuild on 2026-08-28.
The original split, kept because the reasoning is the useful part:

**Split 2026-08-28. `trades_controller`'s half is paid; `positions_controller`'s is not.** The six
that survive D60 are now `trades.flash.*` keys — including `trade_notice`, whose *Compra*/*Venta*
resolves through `side_compra`/`side_venta` rather than an inline ternary. `i18n-tasks` reports no
missing and no unused keys. `positions_controller`'s four go with ACT-2's rebuild: writing keys for
a screen being replaced is the same waste TD3 and TD4 are deferred for.

### TD3 ✅ — deleted with `trades#index` on 2026-08-28

Filter parsing, `filter_side`, `filter_currency`, the year `pluck`, the 50-row cap and the two
counts all live in the controller, reading `current_user.portfolio.trades` directly. `positions`,
`alerts`, `assets`, `market`, `dashboard` and `portfolios` all call a `UseCase` or a `Queries::*`.
This is the one that did not.

**Not fixed, and that is the call:** D60 deletes `trades#index` and these exact methods with it.
Extracting a query object for code scheduled for deletion is the waste this tracker exists to
name.

### TD4 ✅ — the endpoint is gone (2026-08-28)

`position.update(notes:, labels:)` plus a `parse_labels` that splits, strips, dedups and caps at 10
— domain rules in a controller private method.

**Answered by measuring, and the answer was to delete.** No view in `app/views` ever posted to
`positions#update`, and no artboard draws `notes` or `labels` — a write endpoint reachable only by
hand, with a spec keeping it green. That is X6's shape, so it went the same way. **The columns stay**:
dropping data is its own decision and the endpoint was the dead part.

### TD5 — `market_controller#show`

See CKP-7. 21 assignments, three inline AR reads, a job enqueued from a GET.

### TD6 ✅ — done. See X6.

### TD7 🟡 — partly done. See X1: 6 of 22 uses migrated, `accent` deleted, 16 left in the file ACT-2 removes.

### TD8 ✅ — done. See X2.

### TD10 ⚪ — the adaptive backoff is written and never read

[`AdaptiveScheduling`](../app/jobs/concerns/adaptive_scheduling.rb) exists so a job that hits a rate
limit backs off instead of hammering the provider. `adaptive_backoff` doubles a multiplier in the
cache on failure and `adaptive_reset` clears it on success — both are called from real jobs.

**`adaptive_multiplier`, the only reader, appears nowhere but its own usage comment.** No job
consults it to decide whether to skip or delay a run, so the multiplier is computed, stored with a
24-hour TTL, and never consulted. The concern is a no-op that reads as a safety net.

Two ways out and they are not equivalent. Wiring it up means every including job gains a skip
condition — real behaviour change across `SyncMarketIndicesJob`, `SyncPriorityAssetsJob` and the
rest, and each needs its own spec. Deleting it means saying out loud that Solid Queue's retry plus
the per-provider `RateLimiter` already cover this, which is arguably true: the limiter refuses
locally before a call goes out, which is what the backoff was protecting against.

**Found while fixing the index sync's logging (#418), not looked for.** Nothing is broken by it
today — that is exactly why it survived. Left as a decision rather than a drive-by.

### TD9 🟡 — Alpha Vantage may have nothing left to do, and nobody has decided

**Measured 2026-08-29 against the real library, not assumed.** After the ticker search moved to the
Yahoo bridge ([ADR-017's amendment](../docs/architecture/adr/0017-python-bridge-for-yahoo-finance.md)),
Alpha Vantage has exactly two consumers left, and `yfinance` covers both:

| What is left | Covered? | How it was measured |
|---|---|---|
| `:fundamentals` → [`sync_fundamental_job.rb`](../app/jobs/sync_fundamental_job.rb) via `GatewayChain#fetch_overview` | **34 of 34 fields** | every key `AlphaVantageGateway#parse_overview` reads, looked up in `yfinance.Ticker('AAPL').info`. Nothing missing. |
| Statements → [`sync_statements_job.rb`](../app/jobs/sync_statements_job.rb) | all three, annual **and** quarterly | `income_stmt` 39 rows, `balance_sheet` 69, `cashflow` 53, four fiscal years each |
| `search_tickers` | already migrated | `081ac98` — the method is now dead code |

**What retiring it would buy.** One less mandatory API key, which is the same packaging argument that
moved the search. The statements job spends **three calls per asset** (one per `STATEMENT_TYPES`
entry); `yfinance` reads all three off one `Ticker`, so 39 tracked assets go from ~117 calls to ~39.

**What it would cost, honestly.** Alpha Vantage is an official API with a published contract;
`yfinance` is a browser-impersonating scrape. That dependency is already load-bearing — prices,
history, dividends, splits, earnings, indices and now search all run through it — so this extends an
existing risk rather than introducing a new one. It does concentrate more of the product behind a
single unsanctioned door, which is the ADR-017 quarantine getting thinner each time this is done.

**Three things to settle in the same pass, not after it:**

1. **`FundamentalsBudget` is hardcoded to Alpha Vantage** — `PROVIDER = "Alpha Vantage"` in
   [`fundamentals_budget.rb`](../app/contexts/market_data/domain/fundamentals_budget.rb). The
   *Presupuesto de hoy* panel on `Tracked` reads it. Retire the provider and that panel counts a
   source that no longer exists. It needs repointing or rethinking, not deleting.
2. **FMP is the other registered `:fundamentals` source** and is `maintainer_only` — its `/api/v3`
   403s for accounts created after 2025-08-31. Decide in the same pass whether it stays as Adrian's
   own fallback or goes too.
3. **The search has no fallback today.** If Alpha Vantage's gateway is deleted, that stops being a
   choice. If a chain is wanted behind `SearchTickers`, it has to be built before the deletion, not
   remembered after it.

**Not urgent, and that is the point of writing it down:** nothing is broken today. Alpha Vantage
still answers fundamentals and statements at 25 calls a day. This is a *return-to-it* item — come
back with the three questions above answered, not with a deletion PR.


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
| TD9 | Does Alpha Vantage get retired now that `yfinance` covers all 34 fundamentals fields and all three statements? Settle the budget panel, FMP and the search fallback in the same pass | Adrian |

**Five open decisions in `DECISIONS.md`** — D3, D15, D33, D55, D57 — recounted from the file on
2026-08-28 after D58, D59 and D60 landed. Recount it; never increment it (D53).

## Builds, in dependency order

1. ~~**AUTH-1** — TOTP with recovery codes.~~ ✅ **Shipped 2026-08-28** (#391), and it took ONB-1 and
   AJU-2 with it exactly as predicted: three tracker findings, one build.
2. ~~**ONB-1 + AJU-2**~~ ✅ shipped in the same pass.
3. **ACT-1** — the three-door empty state. The two missing doors are the product's own named fixes;
   each needs its own card.
4. **AJU-1** — retire `/profile` into the hub. Needs the design pass first.
5. ~~**ACT-2** — rebuild `Historial`, delete `/trades#index`.~~ ✅ **Shipped 2026-08-28** ([§16](CODE_CHANGES.md)).
   It took ACT-3, KIT-4, TD3, TD4, TD2's second half and most of X1/TD7 with it — **seven items**,
   which is what deferring them for this rebuild was betting on.
6. **CKP-1** — `Movimientos`. Un-gated by D42, metric stated, query exists.
7. **ALR-2** — suggested rules in the empty state. Assembly over data already in hand.
8. **CKP-2** — the chart's range control. Data already loaded.
9. ~~**KIT-3** — the `HeaderBar` partial.~~ ✅ **Shipped 2026-08-28** — four render sites, not the
   five the entry claimed, and it left **KIT-5** behind.
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
