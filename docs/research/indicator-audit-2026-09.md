# The indicator layer, audited against ten years of one asset — 2026-09-04

Every claim here is a comparison run over NVDA's real series, 2,513 bars from
2016-09-06, mirrored from production. Nothing is a reading of the code alone.

```bash
DATABASE_PREFIX=prodmirror bin/rails runner script/research/indicator_audit.rb NVDA
```

Four findings. Two are defects, one is an incoherence, one is a design limit
that the ATR card already proposes fixing.

## 1 · The RSI that ships is not the RSI the thresholds belong to

`TechnicalIndicators.rsi` averages the last fourteen gains and losses with a
plain mean. Wilder's RSI — the one every broker's chart draws, and the one 70
and 30 were calibrated against — smooths those averages recursively across the
whole series, seeded once, exactly as `ATR` does.

They are not close:

| | |
|---|---|
| Mean absolute difference | **6.45 points** |
| p95 | 15.66 points |
| Worst day | 27.57 points |

The consequences land on the states the product draws:

| Days in 2,499 | Shipped | Wilder |
|---|---|---|
| RSI ≥ 70 (overbought) | **525** | 322 |
| RSI ≤ 30 (oversold) | **142** | 33 |

The app calls NVDA oversold on 142 days where a broker's chart says 33 — **four
times as often**. The two disagree about the overbought verdict on 11.4% of all
days.

This is not a tolerance question. `IndicatorSignals` documents its own reasoning
as *"70/30 is the canonical threshold this codebase already writes down"*: the
thresholds were taken from Wilder and the indicator underneath them was not.
`TrendScoreCalculator#rsi_14` carries the same plain mean, and so does
`Queries::RsiOnDates`, which is what tells an owner what RSI read on the days
they bought.

**It also invalidates a number this repo published five hours ago.** The
confluence measurement in
[`volatility-indicators-2026-09.md`](volatility-indicators-2026-09.md) counted
oversold episodes with the shipped RSI. On this evidence that count is inflated
several-fold, and the measurement has to be re-run once the definition is fixed.

## 2 · An alert names one indicator and evaluates another

`AlertEvaluator` for `rsi_overbought` and `rsi_oversold`:

```ruby
when "rsi_overbought"
  score = asset.latest_trend_score&.score || 0
  score >= rule.threshold_value
```

`latest_trend_score` is the blended five-factor score — RSI at weight 0.3, plus
momentum, MACD, volume trend and EMA crossover. It is not RSI.

`TriggerNotice` then tells the owner, in words:

> *"entró en zona de sobrecompra (RSI(14) ≥ 70)"*

Someone who sets 70 believing they set an RSI threshold gets a composite in
which RSI is under a third of the weight. Measured over the same ten years, at a
threshold of 70:

| | |
|---|---|
| Days RSI(14) ≥ 70 | 506 |
| Days TrendScore ≥ 70 | 406 |
| Rule fires while RSI is **not** overbought | **56** |
| RSI is overbought and the rule stays **silent** | **156** |
| Disagreement | 212 of 2,453 days (8.6%) |

Two ways to close it, and they are different products:

- **Evaluate what the copy says** — read the persisted RSI from
  `technical_readings`, which #306 built and which exists for exactly this.
- **Say what it evaluates** — rename the rule kind and rewrite the copy to name
  the trend score.

The first is the smaller change and the one that honours what the owner already
believes they configured. The second needs a name for a composite that ADR-001
would have to allow.

## 3 · The same number is drawn as a warning and as a score

On the 525 days the product calls NVDA overbought, its TrendScore averages
**73.58** (median 73, max 92) — which `label_for` renders `:moderate`,
`:high_score` or `:peak`.

So on the same day, in the same app: the asset detail shows a caution state, and
the panorama row shows a high score. RSI enters the blend **raw and with the
largest weight**, so a high RSI *raises* the score, while `IndicatorSignals`
treats a high RSI as a reason for care.

Neither surface is wrong on its own terms. Together they are incoherent, and the
D3 finding sharpens why: an extreme has no sign until something else supplies
it, so a screen that renders one as favourable and the other as a warning is
asserting a direction neither number carries.

## 4 · Three of the five factors use thresholds that are not the asset's

`TrendScoreCalculator` normalises with constants: momentum clamps at ±20% over
seven days, the EMA spread at ±5% of price, the volume ratio at 0.5–2.0. On NVDA:

| Factor | Saturated |
|---|---|
| EMA spread (±5%) | **312 of 2,453 bars — 12.7%** |
| Momentum (±20%) | 54 of 2,506 bars — 2.2% |

An eighth of the time the EMA factor is pinned at 0 or 100 and carries no
information. On SPY, which moves 0.77% a day against NVDA's 3.21%, the same
constants are never approached and the factor lives in a narrow band around 50.

**One codebase, one constant, opposite failures** — saturation on the volatile
asset, insensitivity on the calm one. This is the volatility-calibration thesis
restated from inside the code, and it is the strongest argument yet for the ATR
card: the primitive it adds is exactly what these three constants are missing.

A fourth thing follows from it. `volume_trend` inverts its ratio when momentum
is negative, so it is not a volume factor — it is volume conditioned on
direction, and direction is *already* a separate factor at weight 0.2. The blend
counts it twice.

## What is not broken

Worth saying, since an audit that only lists faults is not an audit:

- **Bollinger** uses the population standard deviation over the window, which is
  the published definition. Correct.
- **SMA** is a plain mean of the last *n* closes. Correct.
- **MACD's alignment** is right: `compute_ema_series` yields its first value at
  index `period - 1`, and the offset of 14 lines the 12-period series up with
  the 26-period one exactly.
- **Absence is preserved everywhere.** Every calculator returns `nil` rather
  than `0.0` when the series is too short, and `TrendScoreCalculator` publishes
  only the factors it could compute. A missing volume is dropped rather than
  coerced. This is the part of the design that most consistently holds.
- **ATR**, added this week, matches an independent implementation to six decimal
  places.

## Order of work

1. **The alert** (finding 2). It is a live defect with user-visible copy that is
   untrue, and the persisted reading it should read already exists.
2. **The RSI definition** (finding 1). One method, mirrored in three call sites;
   the specs pinning current values will need new expectations, which is the
   work rather than the risk.
3. **Re-run the confluence measurement**, since finding 1 moves its inputs.
4. **ATR into `TechnicalIndicators`** (finding 4), then the three constants.
5. **The two surfaces** (finding 3) — a product decision, not a fix, and one
   that should wait for the re-run in step 3.
