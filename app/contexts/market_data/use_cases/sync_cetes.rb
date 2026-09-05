module MarketData
  module UseCases
    class SyncCetes < ApplicationUseCase
      # One list of terms, held where the series ids are: a second copy here
      # would have to agree with that map and nothing would check that it did.
      TERMS = Gateways::BanxicoGateway.cetes_terms

      def call
        synced = 0
        unreachable = []
        gateway = Gateways::BanxicoGateway.new

        TERMS.each do |term|
          result = banxico_breaker.call { gateway.fetch_auctions(term: term) }
          if result.failure?
            unreachable << term
            next
          end

          result.value!.each do |data|
            upsert_cetes_asset(term, data)
            synced += 1
          end
        end

        publish(Events::CetesSynced.new(count: synced))

        # "CETES Sync" is monitored, and the monitor treats a success as curing
        # prior errors — so a run that reached nothing must not report one.
        return Failure([ :all_terms_unreachable, "Banxico refused every term: #{unreachable.join(', ')}" ]) if unreachable.size == TERMS.size

        Success(synced: synced, unreachable: unreachable)
      end

      private

      # Banxico blocks an abusing token for a full calendar day, and that token
      # serves FX and CETES alike, so the direct call runs under its breaker too.
      def banxico_breaker
        GatewayChain.breaker_for("banxico")
      end

      # CETES_28D / CETES_91D / etc. are abstract instrument symbols that roll —
      # each weekly auction is a new lot with a new maturity. Previously this
      # sync wrote `Asset.maturity_date = Date.current + days`, which silently
      # overwrote each user's lot maturity (the wrong granularity). Per #29 the
      # per-position maturity is captured at trade execution and frozen for the
      # life of the position; the abstract asset no longer carries one.
      def upsert_cetes_asset(term, data)
        days = term.to_i
        discount_price = Domain::YieldCalculator.discount_price(
          face_value: 10.0,
          annual_yield: data[:yield_rate],
          days: days
        )

        listing(term).update!(
          yield_rate: data[:yield_rate],
          face_value: 10.0,
          current_price: discount_price,
          price_updated_at: Time.current
        )
      rescue ActiveRecord::RecordInvalid
        nil
      end

      # ADR-024: the catalogue is Administration's, so the row is created by
      # its owner and this sync writes only the columns Banxico serves.
      def listing(term)
        Administration::UseCases::Assets::EnsureListed.call(
          symbol: "CETES_#{term}D",
          attributes: {
            name: "CETES #{term} Days",
            asset_type: :fixed_income,
            exchange: "Banxico",
            country: "MX",
            currency: "MXN"
          }
        )
      end
    end
  end
end
