# ADR-017 — A Python bridge for Yahoo Finance, run as a subprocess

- **Status:** Accepted
- **Date:** 2026-08-26
- **Author:** Adrian Castillo
- **Related:** [ADR-016](./0016-canonical-market-data-observations.md), [market-data-providers-2026-08.md](../../research/market-data-providers-2026-08.md)

---

## Context

Yahoo Finance is the only source for three capabilities: index levels (IPC, S&P, Dow),
BMV dividends and BMV splits. Alpaca serves no indices and no dividends outside the US,
Massive charges for indices, and DataBursatil's index feed has been **frozen at
2026-06-26** while its dividends endpoint 404s on both API versions.

`YahooFinanceGateway` can no longer reach it. Measured on 2026-08-26, every request a
Ruby HTTP client can construct returns **429**:

| From | With | Result |
|---|---|---|
| Production host (Hetzner) | plain curl, `query1` and `query2` | 429 |
| Production host | browser User-Agent | 429 |
| A residential connection | plain curl | 429 |
| Devcontainer | the gateway's own headers, MX and US symbols | 429 |
| Devcontainer | the cookie-and-crumb bootstrap yfinance performs | 429 **on the crumb endpoint itself** |

The first reading of this evidence — that Hetzner's address range was blocked — was
**wrong**, and the residential 429 disproved it. The block is on the **TLS fingerprint**:
the same URL returns JSON in a browser, and returns JSON through Python's `yfinance`,
which uses `curl_cffi` to present a browser's TLS handshake. No Ruby HTTP client can do
that today.

So the choice is not between two ways of fetching. It is between having index levels and
BMV corporate actions, or not having them.

## Decision

**Ship a Python bridge, invoked as a subprocess, for those three capabilities only.**

- `lib/python/yahoo.py` takes a subcommand and a symbol, prints JSON, and reports its own
  failure kind on stderr so `:not_found` stays distinct from a broken interpreter.
- `PythonRunner` runs it with an argv array — never a shell — refuses arguments that are
  not ticker-shaped, and kills a script that outruns its timeout instead of holding a worker.
- `MarketData::Gateways::YfinanceGateway` is an ordinary driven adapter over that runner
  and goes through `RateLimiter` like every other gateway.
- The interpreter and its dependencies are baked into the image. **The host needs no
  changes**, which is what keeps a self-hosted deployment a single container.

**Yahoo is capped well below anything it publishes** — 6 requests a minute, 200 a day.
That ceiling is our own restraint, not its policy: this is an unsanctioned surface reached
through a browser-impersonating client, and the volume the three capabilities need is a
few dozen calls a day.

### Why a subprocess and not a service

A separate Python service behind an HTTP API is the cleaner separation, and it was
measured rather than argued:

| | Subprocess | Sidecar service |
|---|---|---|
| Per call | **0.69 s** (0.30 s of it importing yfinance) | warm, no import cost |
| Yahoo session | re-bootstrapped per call | reused across calls |
| Infrastructure | none | a second container, accessory and deploy step |
| Rails image | **+222 MB** | unchanged |

At the volume these three capabilities need — roughly 35 calls a day — 0.69 s each is 24
seconds of CPU a day, and the latency argument does not survive contact with that number.
The 222 MB is real and is the cost being accepted.

**Revisit when any of these becomes true**, and the answer flips to the service:

- yfinance calls exceed roughly one a minute sustained, where session reuse starts to
  matter for staying uninteresting to Yahoo;
- the provisional intraday series lands, which is high frequency by nature;
- the image size becomes a deploy problem.

## Consequences

- **Python is now a runtime dependency of the app.** A self-hoster building the image
  gets it; anyone running Rails outside the image needs `PYTHON_BIN` pointed at an
  interpreter with `lib/python/requirements.txt` installed. `lib/python/probe.py` reports
  whether the bridge is usable without touching the network.
- **Specs must never let the bridge run for real.** A subprocess bypasses WebMock, so a
  careless spec would reach Yahoo from CI. Gateway specs stub `PythonRunner`; the runner's
  own specs use `probe.py`, which has no dependency and no network.
- **This is an unsanctioned surface and stays quarantined.** Nothing that a sanctioned
  provider serves is routed here: US prices go to Alpaca, US quotes to Finnhub, BMV to
  DataBursatil. If Yahoo closes this door too, three capabilities degrade and nothing else
  moves.
- The redistribution finding is unchanged: no data from this source ships in the repo.

---

## Amendment — 2026-08-29: the search moved here, and the ceiling moved with it

Two statements above became false and are corrected here rather than edited away.

**"For those three capabilities only" — no longer true.** Ticker search now runs through this
bridge. It had been served by Alpha Vantage, which is what the Consequences section meant by *"nothing
that a sanctioned provider serves is routed here"* — so this is a deliberate departure from that
line, not an oversight against it.

The reason is that Alpha Vantage was not, in practice, serving it. Its free tier is 25 calls a day
and 5 a minute, a search spends one, and it refuses entirely without an API key. Adding five assets
in a row exhausted the minute ceiling; the provider answered with its `Note`, and the typeahead could
only render that as a generic error. For a product whose packaging goal is *"a technical
self-hoster runs it with one command"*, a search that needs a registered key to work at all is a
worse trade than one more capability on an unsanctioned surface.

**"6 requests a minute, 200 a day" — raised to 30 and 2,000.** The old figure was sized for *"roughly
35 calls a day"*, which was honest for three capabilities and is not for four: resolving a
seventeen-symbol CSV batch alone exceeds six calls a minute. Both numbers remain our own restraint
rather than Yahoo's policy, and both remain far below what it would notice.

**The defaults were also not what this ADR said.** `ProviderDefaults` stated 6/min and 200/day; the
row in this repo's own database held 5/min and no daily cap at all. Since defaults apply on create
only, the migration that ships with this amendment **raises** rather than replaces — it leaves a
ceiling already higher alone, and treats `NULL` as the unlimited it means everywhere else here.

**Still quarantined, with one fewer wall.** US prices still go to Alpaca, US quotes to Finnhub, BMV
to DataBursatil. If Yahoo closes this door, four capabilities degrade now instead of three, and the
search degrades to nothing rather than to Alpha Vantage — `MarketData::UseCases::SearchTickers` names
one gateway, with no chain behind it. That is a real cost of this amendment and is left open
deliberately: a fallback nobody exercises is how a provider quietly stops working.
