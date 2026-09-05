# Weekly top-up of the auction curve. Every term, because the product tracks
# four instruments and used to record history for one of them.
class SyncCetesHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform(term: nil, from: nil, to: Date.current)
    terms = term ? [ term.to_s ] : MarketData::Gateways::BanxicoGateway.cetes_terms
    stored = 0
    unreachable = []

    terms.each do |current|
      case MarketData::UseCases::SyncCetesHistory.call(term: current, from: from, to: to)
      in Dry::Monads::Success(stored: count, **)
        stored += count
      in Dry::Monads::Failure
        unreachable << current
      end
    end

    report("CETES History Sync", "#{stored} auctions stored across #{terms.size - unreachable.size} terms",
           unreachable: unreachable, total: terms.size)
  end
end
