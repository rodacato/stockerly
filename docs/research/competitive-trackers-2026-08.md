# Competitive landscape: self-hosted portfolio trackers (2026-08)

> **Snapshot as of 2026-08-20; re-checked 2026-08-27.** The survey of the nine tools has not been
> re-run and their facts are as of the original date. What changed since: the multi-currency P0
> this document calls open **was fixed and is tested** — `ExecuteTrade` captures
> `fx_rate_at_execution` from the Banxico FIX settlement series and cost basis derives at
> historical FX ([ADR-009](../architecture/adr/0009-fx-history-strategy.md)). The conclusions
> below stand; two rows that treat that fix as pending are corrected inline.
>
> Research run to inform the pivot to a self-hosted, single-user tracker ([ADR-0010](../architecture/adr/0010-pivot-to-self-hosted-single-user-tracker.md)).
> **Lens = Stockerly's three concrete failures** from the closed beta: (1) empty first-run / no guidance, (2) can't read the indicators, (3) data entry is a *chore*.
> Nine tools surveyed. Sources cited inline; site facts triangulated from GitHub READMEs (primary) and reputable third-party reviews where marketing sites were JS-rendered SPAs.

---

## Per-tool findings (condensed)

- **Ghostfolio** — closest architectural sibling. Multi-asset (stocks/ETFs/crypto), effectively single-user self-hosted (first user = admin), first-class Docker Compose. Onboarding is decent (public live demo, 3-step, sets base currency). Data entry: manual + rigid-schema CSV/JSON + a `POST /api/v1/import` API; prices from Yahoo/CoinGecko. **No broker/exchange sync** — a self-acknowledged gap ([issue #6003](https://github.com/ghostfolio/ghostfolio/issues/6003)); its CSV has one currency column and **no trade-time FX capture**. Stack: Angular + NestJS + Prisma + Postgres + Redis.

- **Maybe Finance** — cautionary tale, **same Rails/Hotwire/Postgres stack**. Company shut down mid-2025, repo archived; community fork "Sure" continues it. Automated sync was Plaid, **the paywalled feature**; self-hosted falls back to CSV + manual. **Died partly because a VC-funded consumer-finance app couldn't sustain the Plaid cost model** — the cost-justified-technology lesson in its most expensive form.

- **Portfolio Performance** — best-in-class import. Desktop-only (Java/Eclipse RCP), single-user. Flagship: **PDF broker-statement import with 90+ institution-specific parsers** + a 3-step CSV wizard with saved templates + IBKR XML. But onboarding is its weakest axis (blank file, docs-driven) and metrics (TTWROR/IRR) are **explained only in the manual** — literally Stockerly's failure #2 (recurring forum confusion about TTWROR).

- **Wealthfolio** — modern local-first (Tauri + Rust + React + SQLite), single-user, has Docker. **Best onboarding pattern:** a real first-run wizard with a per-account **Tracking Mode: Transactions vs Holdings** — a holdings snapshot gets you to first value without backfilling every trade. Data entry: manual + **AI-assisted CSV column mapping** (infers mappings, tolerant number/date parsing, idempotency keys); live 30+ broker sync is a **paid** add-on.

- **Actual Budget** — self-hosting UX gold standard. **Genuinely one-command** (single container, no external DB). Onboarding standout: a live demo and it **actively steers users away from historical import** — set an opening balance on a recent date, sync forward only. Data entry: **learned rules** auto-generated from behavior (manual entry decays over time). Region-segmented bank sync incl. **Pluggy.ai (LatAm)**. Budgeting, not portfolio — but the UX patterns transfer.

- **Firefly III** — power/correctness, heavy setup (3–4 containers, 15+ env vars, silent cron failures). Double-entry, multi-user. **Anti-reference** for the "any technical person, one command" goal.

- **Beancount + Fava** — plain-text double-entry. Correctness reference (native cost-basis + multi-currency lots — exactly Stockerly's P0 FX modeling), but the **steepest onboarding of all** (learn double-entry syntax). Onboarding anti-pattern.

- **Rotki** — privacy-first crypto. **Read-only exchange API keys + read-only wallet addresses** (see-but-never-withdraw) + DeFi decoding. The cleanest low-custody sync model — the right shape for a future crypto slice.

- **Snowball (SaaS) & Kubera (SaaS)** — not self-hosted, kept as UX references. Snowball: **`?`-tooltip on every metric** + a single distilled "Dividend Rating" score → the metric-readability reference. Kubera: **AI PDF/screenshot statement import** → the low-friction-import reference.

---

## Comparison table

| Tool | Self-host | Scope | Onboarding | Data-entry solution | Metric readability |
|---|---|---|---|---|---|
| **Ghostfolio** | ⭐ Compose (3 svc) | stocks+crypto, ~single | live demo, 3-step | manual/CSV/JSON + import API; **no broker sync**; Yahoo/CoinGecko prices | medium (ROAI, ranges) |
| **Maybe (Sure fork)** | ✅ Compose (Rails) | multi-asset | — | Plaid (US) + CSV | medium |
| **Portfolio Performance** | ❌ desktop | multi-asset, single | ⚠️ blank/docs-only | ⭐ **90+ broker PDF parsers** + templated CSV | deep but manual-only |
| **Wealthfolio** | ✅ Docker/desktop/iOS | multi-asset, single | ⭐ **wizard + Holdings mode** | manual + **AI-mapped CSV**; live sync paid | clean, fewer metrics |
| **Actual Budget** | ⭐ **one-command** | budgeting, single | ⭐ demo + **skip-history default** | CSV/OFX + bank-sync (incl. **Pluggy LatAm**) + **learned rules** | n/a |
| **Firefly III** | ⚠️ 3–4 containers | double-entry, multi-user | steep | separate importer + GoCardless, cron | dense |
| **Beancount/Fava** | ✅ pip, single | multi-asset | ❌ steepest (syntax) | manual text + configured importers | low |
| **Rotki** | ⭐ Docker, no account | crypto+multi, single | no-account first run | ⭐ **read-only keys + wallet addrs** + DeFi | FIFO/LIFO P&L |
| **Snowball** (SaaS) | ❌ | multi-asset | categories + targets | Yodlee/SnapTrade + CSV | ⭐ **?-tooltips + distilled score** |
| **Kubera** (SaaS) | ❌ | net-worth | 14-day trial | aggregator mesh + **AI PDF/screenshot import** | dashboard-clean |

---

## The load-bearing finding

**Nobody in the field has solved the data-entry chore for a self-hosted tool.** The self-hosted leaders all fall back to CSV + manual entry; automated sync always sits behind a paid aggregator. Maybe Finance — Stockerly's exact stack — died partly on aggregator economics. **So Stockerly's manual/CSV path is on par with the leaders, not behind them.** The win isn't magic sync; it's making manual/CSV *not feel like a chore*, plus explaining the indicators. Both are cheap, and both are exactly what the beta friends were missing.

The MXN/USD + Banxico-FX-at-execution angle stays the differentiator — a generic tracker's single-currency CSV glosses over trade-time FX. **That P0 is now fixed** (ADR-009), and fixing it did double as a data-entry improvement: the trade sheet auto-fills the FIX for the date entered.

---

## Patterns to steal, mapped to the three failures

1. **Skip-history opening-balance default** (Actual) → failures #3 + #1. Enter a current-holdings snapshot for instant value; make historical trade+FX backfill optional. *Highest leverage, lowest effort.*
2. **Holdings-vs-Transactions tracking mode per account** (Wealthfolio) → #3 + #1. The mechanism that makes snapshot entry work.
3. **`?`-tooltip on every metric + one distilled signal score** (Snowball) → #2. Explain RSI/MA200 inline in one sentence. Cheapest fix for the literacy failure.
4. **Learned rules from behavior** (Actual) → #3. Manual entry *decays* instead of staying constant.
5. **AI/heuristic CSV column mapping + idempotency** (Wealthfolio) → #3. The realistic backbone; not Ghostfolio's rigid schema.
6. **Seeded demo / example portfolio before setup** (Ghostfolio, Actual, Kubera) → #1. Never a blank first screen — ship a realistic MXN/USD+CETES sample.
7. **Read-only API keys / wallet addresses** (Rotki) → #3, for the crypto slice when triggered. Correct low-custody security posture.
8. **AI PDF/screenshot statement import** (Kubera) → #3. Highest-payoff net-new idea; needs a documented trigger before building.

---

## Data-entry options ranked (self-hosted single-user)

| Rank | Option | Effort | Payoff | Verdict |
|---|---|---|---|---|
| 1 | Holdings snapshot + skip-history default | Low | High | **Do first** — instant value, sidesteps FX backfill |
| 2 | Smart CSV (heuristic mapping, MX formats, idempotency) | Med | High | **Core backbone** |
| 3 | Manual made pleasant (autocomplete, **Banxico FX auto-filled at trade**, learned rules) | Low–Med | Med–High | **Table stakes** — the FX auto-fill shipped with the P0 currency fix; autocomplete and learned rules remain |
| 4 | Crypto: read-only exchange keys + wallet addresses | Med | High (crypto) | Worth it for the crypto slice |
| 5 | AI PDF/screenshot statement import | Med–High | High | Promising — **needs a trigger** |
| 6 | Per-broker CSV auto-parsers | High | Med (few MX brokers) | **Skip for now** |
| 7 | Aggregator sync (Plaid/Yodlee) | High | Low @ MX scale | **Reject** — the trap that helped kill Maybe (Pluggy/Belvo only behind a real trigger) |

---

## Anti-patterns to avoid (each is one of Stockerly's failures in another tool)

- **Aggregator dependency** — a cost/business-model trap with thin MX coverage.
- **Rigid import schema** (Ghostfolio) — recreates the chore.
- **Metrics documented only in a manual** (Portfolio Performance) — literally failure #2.
- **Blank-canvas first run** (Portfolio Performance, Beancount) — literally failure #1.
- **Heavy multi-container setup** (Firefly III) — breaks the one-command goal. Target Actual's single-container simplicity.
- **Double-entry mental model as the entry point** — don't make the user learn accounting to get first value.

---

## Expert consultation

**Renata (fintech UX/UI):** *"Your three failures are empty-state and comprehension problems, not feature gaps. Don't build features, build a floor: never show a blank screen, never force historical backfill, put a `?` on every indicator. Your polish is bought with explanation — free — not with aggregators you can't afford."*

**Esther (product scope):** *"The survey is a warning, not a menu. Maybe was your stack and died chasing Plaid. Snapshot entry + inline tooltips + skip-history are days of work that fix exactly the three things that killed the beta. AI-PDF import and crypto keys are attractive — write them a trigger and a JTBD before touching them, or they're anti-pattern #1 wearing a competitive-analysis costume. And auto-filling Banxico FX at trade time improves onboarding and fixes the currency P0 in the same commit."*
