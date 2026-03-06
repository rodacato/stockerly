# Stockerly

Open-source fintech platform for market trends, portfolios, alerts, and earnings. Built with Rails 8, PostgreSQL, Hotwire, and Tailwind CSS 4.

## Getting Started

### Prerequisites

- Ruby 3.3+
- PostgreSQL 16
- Node.js (for Tailwind CSS)

### First-Time Setup

1. Clone the repo and install dependencies:
   ```bash
   git clone https://github.com/your-org/stockerly.git
   cd stockerly
   bundle install
   ```

2. Create and migrate the database:
   ```bash
   bin/rails db:create db:migrate
   ```

3. Start the server:
   ```bash
   bin/dev
   ```

4. Visit `http://localhost:3000` — you'll be redirected to the **Setup Wizard**
5. Create your admin account
6. Follow the 3-step onboarding:
   - **Step 1:** Configure API keys for market data providers (Polygon.io, CoinGecko, Alpha Vantage, etc.)
   - **Step 2:** Select which assets to track (stocks, crypto, ETFs, CETES)
   - **Step 3:** Review and launch your first data sync

### Development with Demo Data

For development, seed the database with sample data:

```bash
bin/rails db:seed
```

This creates an admin user (`admin@stockerly.com` / `password123`), sample assets, trades, alerts, and more.

## Running Tests

```bash
bundle exec rspec
```

## Security Checks

```bash
bin/brakeman
bin/bundler-audit
```

Install local git hooks to reduce accidental secret leaks:

```bash
bin/setup-hooks
```

Pre-release hardening checklist:

- `docs/OPEN_SOURCE_SECURITY_CHECKLIST.md`

## Architecture

Pragmatic DDD + Hexagonal Architecture with 6 Bounded Contexts: Identity, Trading, Alerts, Market Data, Administration, Notifications.

See `CLAUDE.md` for detailed architecture documentation.

## License

100% free & open source.
