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


# Alpha Vantage's key names are the shape the Ruby side already parses, so the
# rows it needs are aliased to those rather than left as Yahoo's labels. Every
# other row still travels under its own snake_cased name: the report is stored
# whole, and a field nobody maps today is worth keeping for the one who does.
STATEMENT_ALIASES = {
    "balance_sheet": {
        "Current Debt": "short_term_debt",
        "Long Term Debt": "long_term_debt",
        "Stockholders Equity": "total_shareholder_equity",
        "Current Assets": "total_current_assets",
        "Current Liabilities": "total_current_liabilities",
        "Inventory": "inventory",
        "Total Assets": "total_assets",
    },
    "income_statement": {
        "Total Revenue": "total_revenue",
        "Gross Profit": "gross_profit",
        "Operating Income": "operating_income",
        "Net Income": "net_income",
        "EBITDA": "ebitda",
        "Interest Expense": "interest_expense",
        "Research And Development": "research_and_development",
    },
    "cash_flow": {
        "Operating Cash Flow": "operating_cashflow",
        "Capital Expenditure": "capital_expenditures",
        "Common Stock Dividend Paid": "dividend_payout",
    },
}

STATEMENT_FRAMES = {
    "balance_sheet": ("balance_sheet", "quarterly_balance_sheet"),
    "income_statement": ("income_stmt", "quarterly_income_stmt"),
    "cash_flow": ("cashflow", "quarterly_cashflow"),
}


def snake(label):
    return "_".join(str(label).split()).lower()


def reports(frame, currency, aliases):
    if frame is None or frame.empty:
        return []

    out = []
    for column in frame.columns:
        report = {"fiscal_date_ending": column.date().isoformat(),
                  "reported_currency": currency}
        for label, value in frame[column].items():
            # NaN is how a pandas frame spells "this issuer does not report it",
            # and it is not JSON. Absence says the same thing and survives.
            if value != value or value is None:
                continue
            number = str(int(value)) if float(value).is_integer() else str(float(value))
            report[snake(label)] = number
            if label in aliases:
                report[aliases[label]] = number
        out.append(report)
    return out


def statements(ticker, kind):
    annual_attr, quarterly_attr = STATEMENT_FRAMES[kind]
    aliases = STATEMENT_ALIASES[kind]
    currency = (ticker.info or {}).get("financialCurrency") or "USD"

    return {
        "annual_reports": reports(getattr(ticker, annual_attr), currency, aliases),
        "quarterly_reports": reports(getattr(ticker, quarterly_attr), currency, aliases),
    }


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
        elif command in STATEMENT_FRAMES:
            payload = statements(ticker, command)
        else:
            fail(f"unknown command: {command}", "invalid_request")

        if payload is None or (isinstance(payload, list) and not payload):
            fail(f"no data for {argument}", "not_found")

        if command in STATEMENT_FRAMES and not (
            payload["annual_reports"] or payload["quarterly_reports"]
        ):
            fail(f"no data for {argument}", "not_found")

        sys.stdout.write(json.dumps(payload))
    except SystemExit:
        raise
    except Exception as error:  # noqa: BLE001 - the Ruby side maps this to a typed failure
        fail(f"{type(error).__name__}: {error}")


if __name__ == "__main__":
    main()
