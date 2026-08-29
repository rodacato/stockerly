"""Yahoo Finance access for the Ruby side, through yfinance.

Yahoo blocks plain HTTP clients by TLS fingerprint, which is why this exists:
yfinance impersonates a browser and the Ruby gateway cannot. One subcommand per
call, JSON on stdout, a non-zero exit and a JSON error on stderr on failure.
"""

import json
import sys
import warnings
import logging

warnings.filterwarnings("ignore")
logging.disable(logging.CRITICAL)


def fail(message, code="gateway_error"):
    sys.stderr.write(json.dumps({"error": code, "message": str(message)[:300]}))
    sys.exit(1)


def history(ticker, period):
    frame = ticker.history(period=period, auto_adjust=False)
    return [
        {
            "date": index.date().isoformat(),
            "open": round(float(row["Open"]), 6),
            "high": round(float(row["High"]), 6),
            "low": round(float(row["Low"]), 6),
            "close": round(float(row["Close"]), 6),
            "volume": int(row["Volume"]),
        }
        for index, row in frame.iterrows()
    ]


def quote(ticker):
    frame = ticker.history(period="5d", auto_adjust=False)
    if frame.empty:
        return None

    last = frame.iloc[-1]
    previous = frame.iloc[-2]["Close"] if len(frame) > 1 else last["Open"]
    change = 0.0 if not previous else (float(last["Close"]) - float(previous)) / float(previous) * 100

    return {
        "price": round(float(last["Close"]), 6),
        "change_percent": round(change, 4),
        "volume": int(last["Volume"]),
        "as_of": frame.index[-1].isoformat(),
    }


def actions(series, value_key):
    return [
        {"date": index.date().isoformat(), value_key: round(float(value), 8)}
        for index, value in series.items()
    ]


def earnings(ticker):
    frame = ticker.get_earnings_dates(limit=24)
    if frame is None or frame.empty:
        return []

    def number(value):
        return None if value is None or value != value else round(float(value), 6)

    return [
        {
            "date": index.date().isoformat(),
            "hour": int(index.hour),
            "estimated_eps": number(row.get("EPS Estimate")),
            "actual_eps": number(row.get("Reported EPS")),
        }
        for index, row in frame.iterrows()
    ]


def search(yfinance, query, limit=8):
    return [
        {
            "symbol": match.get("symbol"),
            "name": match.get("longname") or match.get("shortname"),
            "quote_type": match.get("quoteType"),
            "exchange": match.get("exchDisp") or match.get("exchange"),
            "sector": match.get("sectorDisp") or match.get("sector"),
        }
        for match in yfinance.Search(query, max_results=limit).quotes
        if match.get("symbol")
    ]


def main():
    if len(sys.argv) < 3:
        fail("usage: yahoo.py <quote|history|dividends|splits|earnings|search> <symbol|query> [period]", "invalid_request")

    command, argument = sys.argv[1], sys.argv[2]
    period = sys.argv[3] if len(sys.argv) > 3 else "1mo"

    try:
        import yfinance
    except ImportError:
        fail("yfinance is not installed in this image", "not_supported")

    try:
        # Matching nothing is an answer, so search returns before the
        # empty-payload guard that turns a blank result into not_found.
        if command == "search":
            sys.stdout.write(json.dumps(search(yfinance, argument)))
            return

        ticker = yfinance.Ticker(argument)

        if command == "quote":
            payload = quote(ticker)
        elif command == "history":
            payload = history(ticker, period)
        elif command == "dividends":
            payload = actions(ticker.dividends, "amount")
        elif command == "splits":
            payload = actions(ticker.splits, "ratio")
        elif command == "earnings":
            payload = earnings(ticker)
        else:
            fail(f"unknown command: {command}", "invalid_request")

        if payload is None or (isinstance(payload, list) and not payload):
            fail(f"no data for {argument}", "not_found")

        sys.stdout.write(json.dumps(payload))
    except SystemExit:
        raise
    except Exception as error:  # noqa: BLE001 - the Ruby side maps this to a typed failure
        fail(f"{type(error).__name__}: {error}")


if __name__ == "__main__":
    main()
