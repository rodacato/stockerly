# First beta invite — checklist + message draft

> S10 (#125). One-time runbook for the first invite. Once the first amigo lands and reports back, fold lessons learned into [beta-support.md](beta-support.md) and retire this doc.

---

## 0 · Who first

Per [project memory: vision](../../.local/CLAUDE.md) and project_vision: **closed beta B+**, ≤20 invited friends. **Start with one.** A single first amigo who:

- already knows what Stockerly is for (you don't want to onboard *the concept* and *the product* in the same conversation),
- invests in MX equities or CETES (so the product surface he sees is the one we built first),
- has the patience to send screenshots when something breaks,
- you can ping on WhatsApp without it being awkward — this is for high-bandwidth reactive support during the first 48h.

## 1 · Pre-flight checklist

Run through these before generating the invite code. Each one is a known failure mode from S07–S10 we don't want the first amigo to discover.

### App-level

- [ ] Local smoke spec passes: `bundle exec rspec spec/system/beta_smoke_spec.rb`
- [ ] CI on `master` is green
- [ ] Production deploy is current (last `master` commit is what's served)
- [ ] Visit `/login`, `/register`, `/dashboard`, `/market`, `/portfolio`, `/alerts`, `/earnings`, `/notifications`, `/profile` in a browser. All es-MX. No 500s, no broken images, no English copy in nav/buttons/headings.
- [ ] Submit `/report-bug` form with a dummy report. Confirm it lands in `support@notdefined.dev`.
- [ ] Trigger a password reset on a throwaway account. Verify email arrives, logo header shows, copy is es-MX, link works.

### Data

- [ ] At least 1 BMV asset seeded that the amigo will actually look up (WALMEX.MX / GFNORTEO.MX / AMXL.MX).
- [ ] `SyncEarnings` ran recently — `EarningsEvent.upcoming.count` returns a non-zero number for the next 30 days.
- [ ] FX rates fresh — `FxRate.where("created_at > ?", 6.hours.ago).any?`.

### Monitoring

- [ ] `SENTRY_DSN` is set in production env. Confirm via the Sentry "Issues" page that the most recent deploy registered a release.
- [ ] Tail production logs in a second terminal during the invite session: `bin/rails runner "Rails.logger.info('beta-invite-go')"` — you should see it in the live log stream.
- [ ] Solid Queue dashboard accessible to admin (existing `/admin/jobs` if wired; otherwise just `SolidQueue::Job.where(finished_at: nil).count` in a console).

### Invite mechanics

- [ ] Generate a fresh invite code:
  ```ruby
  bin/rails runner 'puts InviteCode.create!(created_by_user: User.where(admin: true).first, note: "first beta amigo — <name>").formatted_code'
  ```
- [ ] Copy the formatted code (`xxxx-xxxx-xxxx`).
- [ ] Verify the code works in a fresh incognito session by going through `/register` end to end and reaching the dashboard. **Then immediately reset it to unused:**
  ```ruby
  bin/rails runner "InviteCode.find_by(note: 'first beta amigo — <name>').update!(used_at: nil, used_by_user_id: nil)"
  ```
  *Also delete the test user you just created.*

### Comms

- [ ] You have the amigo's preferred channel ready (WhatsApp / Signal / direct email).
- [ ] You can stop what you're doing and respond within ~30 min for the first 24h.

---

## 2 · Invite message draft (es-MX)

Send via the channel you already use with them. Keep it personal, short, and explicit about what kind of feedback you want.

> Hey [Nombre], te quería mostrar un proyecto en el que llevo trabajando un rato — **Stockerly**, una plataforma para seguir mercados, portafolios y reportes con foco en BMV + CETES.
>
> Está en beta cerrada y me gustaría que seas la primera persona que la usa fuera de mí. Te dejo el link y un código:
>
> - **Stockerly**: [https://stockerly.notdefined.dev](https://stockerly.notdefined.dev)
> - **Código de invitación**: `xxxx-xxxx-xxxx`
>
> No es una demo bonita ni un pitch — quiero que la rompas. Si algo no se entiende, no funciona, o sientes que falta, dímelo *en cuanto pase*. Hay un botón "Reportar un bug" arriba a la derecha cuando ya entraste, o me escribes acá directo.
>
> Lo que me sirve más:
> - Qué te confunde en los primeros 5 minutos.
> - Qué información buscaste y no encontraste.
> - Si vieras esto en producción, ¿lo usarías? ¿Por qué sí / no?
>
> Gracias por probarlo. Cuando estés, dime aquí y voy contestando dudas en vivo.

---

## 3 · While the amigo is using it

- Keep this checklist + Sentry tab + production log tail open in adjacent windows.
- If they DM "no funciona X" or "no entiendo X", grab the asset of context (screenshot, URL, time, what they tried) before debugging — first instinct is to fix, but the report is more valuable than the fix in the first hour.
- File anything they say verbatim into the GitHub bug-triage issue (#125) as a comment, even if it sounds trivial. Sprint retro will pull from there.

---

## 4 · After the session

- [ ] Add the amigo's email to a "beta cohort" list (just a markdown bullet in this file for now — it's <20 people).
- [ ] Decide go/no-go on inviting the second amigo. Default = wait until S10 retro to see if anything from the first surfaced as systemic.
- [ ] Update [beta-support.md](beta-support.md) §5 if a new failure mode appeared that's not covered.
- [ ] Drop a one-paragraph note in `docs/sprints/2026-S10-design-completion-and-invite-readiness/log.md` summarizing the session — surprised by what, what broke, what to take to retro.

---

## 5 · Known gaps to mention proactively (or not)

Decide before pressing send whether to tell the amigo about these or let him discover them:

- **No mobile-app build yet** — web only. If he asks, "está en planeación post-beta".
- **No real money / no brokerage connection** — Stockerly is data + alerts, not a broker. Make this clear if their mental model is "Robinhood for MX".
- **BMV earnings dates may be unconfirmed** — Yahoo returns date ranges for some emisoras. UI marks them "fecha por confirmar".
- **Spanish-only** — explicit, no plans for English right now (ADR-0007).

---

## 6 · Rollback / kill switch

If something goes catastrophically wrong during the session:

- **Toggle `registration_open` to `"false"`** to prevent new sign-ups while you fix:
  ```ruby
  bin/rails runner 'SiteConfig.set("registration_open", "false")'
  ```
- **Toggle `maintenance_mode` to `"true"`** if you need to put the whole app behind a banner:
  ```ruby
  bin/rails runner 'SiteConfig.set("maintenance_mode", "true")'
  ```
- The amigo's session is already created, so toggling these doesn't kick him out — only prevents NEW sessions/registrations.
