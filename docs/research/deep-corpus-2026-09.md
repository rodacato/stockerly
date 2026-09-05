# The same questions on ten years — 2026-09-05

Yesterday's measurements ran on one year, and their own limits section said no
conclusion in them survived being called regime-independent. `data:deepen_all`
took the corpus to **86,215 bars over 47 assets, back to 2014**, so they were
run again.

Two of the three headline conclusions did not survive. This page states what
changed before it states anything else.

```bash
DATABASE_PREFIX=prodmirror bin/rails runner script/research/confluence.rb
DATABASE_PREFIX=prodmirror bin/rails runner script/research/deep_corpus.rb
```

## What is withdrawn

**"The mean-reversion light loses to doing nothing at five and ten days."**
Wrong — that was one year of sample. On ten:

| Horizon | Base rate | Oversold, 1 year (n≈70) | Oversold, 10 years (n≈450) |
|---|---|---|---|
| +5 days | +0.55% | −0.33% | **+1.11%** (win 64%) |
| +10 days | +1.10% | −0.07% | **+2.21%** (win 65%) |
| +20 days | +2.11% | +2.76% | **+4.04%** (win 67%) |

It beats the base rate at every horizon, consistently, on 423–497 episodes.

**"The light has no sign of its own — it needs the trend to supply one."** This
was the finding, and it was the argument for building a confluence vote. It does
not survive the sample:

| +20 days, oversold and… | 1 year | 10 years |
|---|---|---|
| above the SMA(200) | +10.76% (**n=8**) | +2.08% (n=96) |
| below the SMA(200) | +1.71% (n=13) | **+4.78%** (n=296) |

At n=8 the filter looked decisive and pointed one way. At n=96 it points the
other, and weakly. **A trend filter does not improve the mean-reversion light on
this data** — which is precisely the thing a confluence engine would exist to do.

I flagged n=8 at the time as "a direction, not a result". It was not even that.

## What survives, and is now definitive rather than suggestive

**Light 1 implies "below the 50-day average."** Over ten years and **483
episodes, not one** fired above it. A bar that is oversold on RSI and below its
lower Bollinger band is, mechanically, a bar below its 50-day mean. Any vote
pairing those two is a fact consulting itself.

**ATR's spread is a property of the assets and needs no window to establish it.**
ALAB moves 7.20% of its price on an ordinary day, SPY 0.76%.

## The problem with every return figure on this page

The window is not a market. It is **the assets held in 2026, measured over the
decade that made them worth holding**:

| | |
|---|---|
| 42 assets, mean total move | **+1202.6%** |
| median | +379.7% |
| assets that fell | **4 of 42** |
| SPY over the same window | +310.8% (15.2% CAGR) |
| NVDA | +14,785% (65.1% CAGR) |

The basket's own base rate — hold everything, rebalance monthly — is **+2.29% a
month, about 31% a year**, roughly twice what the index did. That is not a base
rate. It is a winners' list, and every edge on this page is measured against it
and inside it.

Going from one year to ten did not only add regimes. It also deepened the
selection: ten years of survivorship on a list chosen in 2026 is a far stronger
bias than one year of it. **Every number improving at once is the symptom, not
the reassurance.**

## Thesis 4 — dual momentum, and why its result cannot be believed

147 monthly rebalances, twelve-month lookback, top five held:

| | mean per month | win |
|---|---|---|
| hold everything (base rate) | +2.29% | 62% |
| top 5 by 12-month momentum | **+4.26%** | 61% |
| top 5, with the absolute-momentum filter | **+4.59%** | 62% |

Twice the base rate, over 147 rebalances, on the one family with peer-reviewed
support. It is the best-looking result in the whole set.

**And it is exactly what survivorship manufactures.** Ranking by trailing
momentum inside a universe pre-selected for having risen enormously picks, by
construction, the assets that rose most — and this universe was selected in 2026
by knowing which ones those were. A real dual-momentum test needs a universe
defined *at each rebalance date* — index constituents as they stood — which is a
different data problem from a backfill and is not one this corpus can be made to
answer.

## The Mayer Multiple — one honest asymmetry, at the wrong end

Price over its 200-day average, against the following month:

| Multiple | n | mean | median | win |
|---|---|---|---|---|
| below 0.8 | 4,642 | +3.87% | +3.17% | 59% |
| 0.8 – 1.0 | 16,563 | +1.45% | +1.36% | 55% |
| 1.0 – 1.2 | 40,755 | +2.12% | +2.04% | 66% |
| 1.2 – 2.4 | 14,604 | +3.74% | +2.08% | 58% |
| **above 2.4** | 224 | **−2.38%** | **−7.22%** | **35%** |

The thesis is *accumulate below the multiple, avoid above it*, and the lower half
does not show it: 1.2–2.4 (+3.74%) is as good as below-0.8 (+3.87%), and the
0.8–1.0 band is the worst of the four. There is no monotonic "cheaper is better".

The one clean result is the top: **above 2.4 the following month is negative,
with a 35% win rate and a −7.22% median.** That is the only figure here that
survivorship works *against* rather than for — the sample is assets that went on
to do well, and even inside it this band lost. Small (n=224) and probably
concentrated in a few episodes, but it is the only bucket pointing somewhere the
bias does not.

## What this settles

**Close D3. Do not build the confluence engine.**

Not because the light is worthless — on this data it beats the base rate. Because
the specific thing the engine would add is *combining* lights, and combination is
the one thing that measured no better once there was sample to measure it with.
Light 1 alone performs as well as light 1 filtered by light 3, and light 1
already implies the 50-day test outright. The vote has nothing to vote on.

**Keep the lights as they are drawn** — three states side by side, each a fact
about today, none claiming to confirm another. That is what the data supports and
it is what already ships.

**Thesis 4 stays open and unproven.** Its result is too good and too explainable
by the sample. It needs a point-in-time universe, and that is a bigger piece of
work than any card in the family currently describes.

**Thesis 2 (ATR layers) needed none of this.** It does not claim an edge — it
claims a unit, and the unit is a measured property of the assets. It shipped on
that basis and this page does not move it.

## Honest limits, again and worse

- **Survivorship dominates.** Stated four times above because it applies to every
  return figure and cannot be corrected within this corpus.
- **In-sample.** Thresholds (30/70, 20×2σ, 2.4) were published before the test
  and not fitted to it, which helps. Nothing was held out, which does not.
- **Episodes are not independent across assets.** Forty-two correlated holdings
  in one decade are far fewer than forty-two experiments.
- **ADR-001's Support 3 stands**, and this page strengthens it: the best-looking
  result turned out to be the sample talking, and the finding that argued for
  building something reversed the moment it had enough data to be tested.
