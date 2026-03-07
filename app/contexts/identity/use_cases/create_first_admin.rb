module Identity
  module UseCases
    class CreateFirstAdmin < ApplicationUseCase
      def call(params:)
        return Failure([ :setup_complete, "Setup already completed" ]) if User.exists?

        attrs = yield validate(Contracts::CreateFirstAdminContract, params)
        user = yield persist(attrs)
        bootstrap_platform!
        _ = yield publish(Events::FirstAdminCreated.new(user_id: user.id, email: user.email))

        Success(user)
      end

      private

      def persist(attrs)
        user = User.new(
          full_name: attrs[:full_name],
          email: attrs[:email],
          password: attrs[:password],
          password_confirmation: attrs[:password_confirmation],
          role: :admin,
          is_verified: true,
          email_verified_at: Time.current
        )
        user.save ? Success(user) : Failure([ :validation, user.errors.to_hash ])
      end

      def bootstrap_platform!
        create_site_defaults!
        create_integrations!
        create_market_indices!
        create_fx_rates!
      end

      def create_site_defaults!
        { "registration_open" => "false", "maintenance_mode" => "false" }.each do |key, default|
          SiteConfig.find_or_create_by!(key: key) do |c|
            c.value = default
          end
        end
      end

      def create_integrations!
        integrations = [
          { provider_name: "Polygon.io", provider_type: "Stocks & Forex", max_requests_per_minute: 5, daily_call_limit: 500 },
          { provider_name: "CoinGecko", provider_type: "Cryptocurrency", max_requests_per_minute: 30, daily_call_limit: 10_000, settings: { "pro_tier" => false } },
          { provider_name: "Yahoo Finance", provider_type: "Mexican Stocks & ETFs", daily_call_limit: 2_000 },
          { provider_name: "Alternative.me", provider_type: "Sentiment", daily_call_limit: 100 },
          { provider_name: "CNN", provider_type: "Sentiment", daily_call_limit: 100 },
          { provider_name: "Alpha Vantage", provider_type: "Fundamentals", max_requests_per_minute: 5, daily_call_limit: 25 },
          { provider_name: "FMP", provider_type: "Dividends & Splits", max_requests_per_minute: 10, daily_call_limit: 250 },
          { provider_name: "ExchangeRate", provider_type: "FX Rates", max_requests_per_minute: 10, daily_call_limit: 1_500 },
          { provider_name: "Banxico", provider_type: "CETES & Fixed Income", daily_call_limit: 1_000 }
        ]

        integrations.each do |attrs|
          Integration.find_or_create_by!(provider_name: attrs[:provider_name]) do |i|
            i.provider_type = attrs[:provider_type]
            i.requires_api_key = false
            i.connection_status = :disconnected
            i.max_requests_per_minute = attrs[:max_requests_per_minute]
            i.daily_call_limit = attrs[:daily_call_limit] || 1_000
            i.settings = attrs[:settings] || {}
          end
        end
      end

      def create_market_indices!
        indices = [
          { symbol: "SPX", name: "S&P 500", exchange: "NYSE" },
          { symbol: "NDX", name: "NASDAQ 100", exchange: "NASDAQ" },
          { symbol: "DJI", name: "DOW JONES", exchange: "NYSE" },
          { symbol: "UKX", name: "FTSE 100", exchange: "LSE" },
          { symbol: "IPC", name: "IPC Mexico", exchange: "BMV" },
          { symbol: "VIX", name: "CBOE Volatility", exchange: "CBOE" }
        ]

        indices.each do |attrs|
          MarketIndex.find_or_create_by!(symbol: attrs[:symbol]) do |i|
            i.name = attrs[:name]
            i.exchange = attrs[:exchange]
            i.value = 0
            i.change_percent = 0
          end
        end
      end

      def create_fx_rates!
        pairs = [
          { base_currency: "USD", quote_currency: "EUR", rate: 0.92 },
          { base_currency: "USD", quote_currency: "MXN", rate: 17.25 },
          { base_currency: "USD", quote_currency: "GBP", rate: 0.79 }
        ]

        pairs.each do |attrs|
          FxRate.find_or_create_by!(base_currency: attrs[:base_currency], quote_currency: attrs[:quote_currency]) do |r|
            r.rate = attrs[:rate]
            r.fetched_at = Time.current
          end
        end
      end
    end
  end
end
