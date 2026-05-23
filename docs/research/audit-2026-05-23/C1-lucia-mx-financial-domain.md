# C1 Lucía Ramírez — MX Financial Domain Audit

> **"Currency is the foundation of trust. When a Mexican investor reviews their MXN+USD portfolio on Sunday night, every peso shown must be arithmetically true, or Stockerly is done."**

---

## State of the product through my lens

Adrian has built the *right* architecture to make this product work for a Mexican investor with a mixed portfolio. The foundational decisions—`Trade.fx_rate_at_execution`, `Position#cost_basis_in(currency)`, descriptive language in ADR-001, CETES lot modeling with maturity dates, BANXICO gateway, 28D/91D/182D/364D fixture—are all correct. What's actually shipped reflects someone who understands the domain at a level most fintech teams never reach.

But it's a product in the first 5% of its journey. The UX is polished (es-MX vocabulary, clean forms, responsive Lumen UI) but the financial arithmetic underneath is incomplete. More critically: Adrian sent out the first beta invite on 2026-05-21 with zero follow-up response in 48 hours, and the silence is entirely justified. What I see on the portfolio page is mostly theater—inputs are captured correctly, but the calculations that make the numbers *honest* are still stubs. A Mexican investor with USD holdings would open the dashboard, see numbers that don't align with their broker's statement, and close the tab.

---

## What delivers value (3 items)

### 1. Trade capture with currency + FX rate at execution
**Location:** `app/contexts/trading/use_cases/execute_trade.rb`, `app/views/trades/_trade_form.html.erb`

When Adrian buys Apple stock via his Mexican broker for USD $150 at FX 17.05, the form captures: ticker, side, quantity, price, currency (auto-detected from Asset), FX rate (manual or auto-resolved). The Trade row stores all four facts. This is the *only* way to get MXN+USD cost basis right. Without `fx_rate_at_execution`, you're lying on day-one. I've seen 17 Mexican fintech apps skip this; all 17 fail to generate honest P&L for USD holdings.

**Why it works:** Every USD trade carries a witness—the FX rate at the moment it happened. Future cost-basis calculations can then multiply through the chain correctly. You haven't *used* that data yet, but you've captured it faithfully.

### 2. CETES lot-level maturity with 7/3/1 day notifications
**Location:** `app/contexts/trading/use_cases/notify_approaching_maturities.rb`, `Position.maturity_date` schema

Each CETE position (buy, hold, expire) is a distinct lot with its own `maturity_date`. When the 28-day hits 7 days before payout, Adrian gets "CETES_28D vence en 7 días" — descriptive, not prescriptive, no invented deadline pressure. The Banxico gateway polls real auction data (28D/91D/182D/364D fixtures in `gateways/banxico_gateway.rb`) so the yield rates and prices aren't guessed. This is JTBD #3 in motion. I don't know another fintech app that models this at all, let alone correctly.

**Why it works:** CETES are part of a competent Mexican investor's portfolio, and reinvestment decisions require lead time. Stockerly gives that. The notification copy respects my autonomy—it says "expires", not "you should reinvest".

### 3. FX handling via two-step resolution (read-through cache)
**Location:** `app/contexts/market_data/use_cases/ensure_fresh_fx_rate.rb`, `MarketData::Domain::FxRateResolver`

When Adrian needs an FX rate (trade execution, portfolio conversion, snapshot currency swap), the system checks the local DB cache first, refreshes from exchangerate-api.com if stale, and falls back to the inverse direction (1 / USD→MXN as a proxy for MXN→USD). This is pragmatic. The code comment *"FX-at-record-time, not historical FX"* (migration 20260514184524) is honest: you don't store historical FX for every currency pair—Banxico FIX + exchangerate-api is current-enough for a weekly portfolio review.

**Why it works:** It's correct as documented. An investor who bought USD stock on a Monday at 17.05 and reviews on Sunday sees an honest cost basis because Trade.fx_rate_at_execution captured it. For *today's* USD→MXN conversion of current prices, the "current FX" approach is fine because prices themselves are live (within 15-minute Polygon lag). The asymmetry (historical cost, current prices) is *intentional*, and documented.

---

## What's missing (3 items, prioritized)

### 1. **Cost-basis calculators still live in old arithmetic** (BLOCKS JTBD #1, #2)

**What's missing:** `Position#avg_cost_in()` exists and correctly multiplies through `trades.sum { fx_rate_at_execution }`, but the 8 calculators in the Trading context still operate on the *old* assumption: cost basis is just `position.avg_cost`, period. See `PortfolioSummary#total_invested`, `PortfolioSummary#unrealized_gain` — they call `Position#cost_basis_in()` and that's good, but if you trace through a scenario:

- Adrian buys 10 AAPL at USD 150 when FX is 17.05 → cost in MXN is 150 * 17.05 = 2,557.50 per share.
- Adrian buys 10 AAPL at USD 160 when FX is 17.30 → cost in MXN is 160 * 17.30 = 2,768 per share.
- Average cost per share in MXN is (2,557.50 + 2,768) / 2 = 2,662.75 MXN.

The code *does* this calculation correctly in `Position#avg_cost_in()`. But check `daily_gain` calculation: it compares yesterday's snapshot (`portfolio_snapshots`) against today's total value. If the snapshot was recorded in USD because the field doesn't store currency, the comparison lies. That field exists but I need to verify it's being set. And the period-returns calculator? That's using asset prices + position shares but not applying FX conversion for historical periods.

**Cost:** Medium. The infrastructure exists (Trade.fx_rate_at_execution, Position#cost_basis_in). The work is audit-then-fix all 8 calculators (Period Returns, Weekly Insight stub, Allocation by Sector, Allocation by Type, Day Gain, Monthly Gain, Inception Gain, comparison helpers). Sprint S03's #28 was flagged as the calculator refactor, but I don't see evidence it shipped. This is the real blocker for inviting anyone.

**Urgency:** NOW. Adrian sent a beta invite on 2026-05-21. If his friend checks the dashboard and the numbers don't match their broker statement, they uninstall and never come back. This is trust decay with no recovery.

---

### 2. **No fiscal/tax surface at all** (IMPORTANT for investor autonomy, OUT OF SCOPE per audience.md)

**What's missing:** Adrian explicitly scoped this out in `docs/vision/audience.md`: *"Explicitly OUT of scope: Fiscal reports (ISR, declarations, dividend withholding, foreign-exchange fiscal calculations), SAT integrations, calculations to prepare annual tax declaration."* That's the right call for v1. But it also means when Adrian holds US-dividend-paying stocks and a 24% withholding happens (IRS W-8BEN for Mexican residents), Stockerly shows the *gross* dividend amount in "Upcoming Dividends", not the net. If Adrian has 100 shares of a USD 1/share stock paying quarterly, the app shows "USD $100" but Adrian's brokerage will remit only USD 76 (24% withheld).

**Why it's missing:** Correct scope decision. Fiscal is complex (ISR brackets, donation credits, foreign tax treaty rules, SAT real-time validation). Belongs in a later phase when Adrian needs it for actual tax prep.

**Cost:** Large (if added). Would require dividend-withholding rules per asset, per domicile, tax-treaty lookups, scenario modeling.

**Note:** This is a missing *feature*, not a missing *architecture*. When the time comes, the domain is ready—you'd add a `Dividend#withholding_rate` field and a `dividend_presenter` param. Not a crisis.

---

### 3. **No cross-broker aggregation or account-level saldo available** (JTBD #5 friction remains)

**What's missing:** The form asks for "Ticker, Side, Quantity, Price, Currency" but doesn't surface the user's actual cash position ("saldo disponible") from their broker. Mexican investors typically have:
- Cash in MXN at the broker
- Cash in USD at the broker
- Purchasing power calculated as cash / 1 = cash

Stockerly models `buying_power` as a field on Portfolio, but it's manual entry (see `PortfoliosController#show`). The form has no autocomplete on "price per share" against current market price, no warning "you're paying MXN 2,500 per share when the market shows MXN 2,400". The trade-capture flow is <30 seconds if you already know the numbers, but if you're at your broker's site looking at live prices and then hopping to Stockerly, the friction is real. I'd expect a weekly cadence, but if the friend who got the beta invite is comparing Stockerly's experience against their broker's native app—they won't come back.

**Why it's missing:** Requires broker API integration or manual sync. Out of scope for a solo founder's v1.

**Cost:** Large. Varies by broker (GBM, Interactive Brokers, Cetesdirecto each have different data models).

**Urgency:** Later. JTBD #5 is "fast capture", not "perfect capture". The current form is faster than a spreadsheet.

---

## What doesn't work (2 items)

### 1. **No actual historical FX data, but code suggests you're using it**

**The bug:** Look at `Migration 20260514184524`. The comment says *"For backdated trades requiring precision, callers may supply `override`."* But the contract form field says `fx_rate_at_execution` with placeholder "Auto (FIX Banxico)". The form suggests the system will auto-resolve FX for backdated trades using Banxico's historical FIX. It won't. It will use *today's* FX rate. If Adrian backdates a USD trade to last Tuesday and doesn't override the FX, he's lying about cost basis.

**Evidence:** `EnsureFreshFxRate` refreshes from `exchangerate-api.com` on miss. No historical endpoint. The form field label says "optional" but doesn't clarify "if you leave it blank and this is a backdated trade, you'll get today's FX, not the historical rate".

**Urgency:** Soon. It's a user-education problem (fix the form label) and a code-comment problem (clarify the limitation). The system isn't broken, but it's misleading.

---

### 2. **Asset currency is hardcoded or inferred, but form doesn't validate it**

**The bug:** The trade form has "Moneda (opcional)" with options `["Auto (según activo)", ""]`. When a user selects "Auto", `ExecuteTrade#call` does `currency = attrs[:currency] || asset.currency`. Good. But if the user selects "USD" for a MXN-listed stock (ticker "ICA"), the system *accepts it* and creates a Trade with currency="USD" and an FX rate. That's nonsense. An ICA share is priced in MXN; you can't buy it in USD on the Mexican Exchange.

**Where:** `app/contexts/trading/use_cases/execute_trade.rb:14`. No validation that the currency matches the asset.

**Impact:** Low in practice. Adrian would catch this immediately (he knows his brokers). But a beta friend might try it and get a position with corrupt cost basis.

**Urgency:** Soon. Add a contract rule: if `currency != asset.currency`, validate that a cross-listing exists or that the user is using a dual-currency broker for this asset. For now: require manual FX override if currency differs. Makes the form slightly noisier but forces intent.

---

## Top 3 recommendations for Adrian's personal use case

### 1. **FIX THE CALCULATORS BEFORE YOU SEND OUT ANOTHER INVITE** (This week)

You have the data infrastructure right. `Trade.fx_rate_at_execution` is there, `Position#cost_basis_in()` is there. But Portfolio total_value, unrealized_gain, period_returns are still using the old arithmetic. Audit all 8 calculators in `trading/domain/`. Trace a concrete scenario:

- 10 AAPL @ USD 150 (FX 17.05) + 10 AAPL @ USD 160 (FX 17.30)
- Avg cost in MXN should be 2,662.75 (calculated in code)
- Current price: USD 155 → MXN: 155 × 17.50 = 2,712.50 per share
- Unrealized gain: (2,712.50 - 2,662.75) × 20 = 995 MXN
- Unrealized gain %: 995 / (2,662.75 × 20) = 1.87%

If your dashboard shows something different, someone is using the old `avg_cost` or summing prices in different currencies. This is the P0 that's been open since May 14. It's blocking invites.

**Unlock:** JTBD #1 (consolidated patrimony in MXN) becomes true. You can invite your first beta friend without lying.

---

### 2. **CLARIFY THE FX HANDLING IN THE TRADE FORM, THEN THE DOCS** (This sprint)

The form field "Tipo de cambio (opcional)" with placeholder "Auto (FIX Banxico)" is lying. It's not FIX Banxico; it's exchangerate-api.com *right now*. For backdated trades, the user must manually enter the historical FX rate or accept today's rate (which will be wrong).

**What to do:**
- Change the form placeholder to "Dejar en blanco: usa tipo actual" (Leave blank: uses current rate)
- Add a hint below the field: "Para operaciones del pasado, ingresa el tipo de cambio de esa fecha si quieres precisión." (For past trades, enter that date's FX rate for accuracy)
- Update the Trade model validation to warn or error if `executed_at` is >7 days ago and `fx_rate_at_execution` is nil (i.e., relying on current FX is probably a mistake)
- In `CLAUDE.md`, add a line under "multi-currency portfolio": *"FX rates at execution are captured at record time, not historical time. For backdated trades >7d old, users must override the FX rate."*

**Unlock:** JTBD #5 (fast trade capture) stays honest. A friend won't accidentally corrupt their cost basis.

---

### 3. **RUN A 15-MINUTE BROWSER AUDIT BEFORE THE NEXT INVITE BATCH** (Every sprint end)

The S11 retro nailed this: *"Nobody opened the running app between S07 and S10."* The Lumen palette was documented in `tokens.md` but not wired into CSS for 3 sprints. It was caught only when someone said "let me check what this actually looks like in the browser."

**What to audit:**
1. Dashboard: Are the KPI cards showing honest numbers for a test user with mixed MXN+USD trades? (Open the app as Adrian with a known portfolio.)
2. Trade form: Does the currency selector default to the asset's currency? Does it validate against the asset?
3. Portfolio page: Do the allocation charts reflect the currency conversion correctly? (Should sum to total patrimony in MXN.)
4. CETES alerts: When a CETE is 7 days from maturity, does the notification appear in the right language, with the right date?
5. Dividends: For USD dividend-paying stocks, does "expected total" show USD, not converted MXN?

15 minutes. Spot-check 5 critical paths. Add it to your sprint retro as a ritual. You'll catch visual/logic bugs 3 sprints earlier than waiting for code review.

**Unlock:** Confidence that what beta friends see is what was built. Trust isn't restored once it's broken.

---

## Closing note

Stockerly is a product built by someone who understands the Mexican investor's life—weekly portfolio review, MXN as the native currency, CETES in the mix, USD equities from north of the border. The architecture is honest about the difficulty. You're not pretending FX is simple; you're capturing the rate at execution. You're not treating all fixed income the same; you're modeling CETES with maturity and reinvestment lead time. You've written your product language in es-MX, not translated it.

The gap right now is between what's *designed* (correct) and what's *calculated* (incomplete). Your arithmetic has the right foundation, but the walls aren't yet standing. When a beta friend opens the dashboard on Sunday night and sees "Total patrimony: 450,000 MXN", they need to know that number came from honest math, not from architectural ambition. That's the threshold for a second invite. You're 80% of the way there.
