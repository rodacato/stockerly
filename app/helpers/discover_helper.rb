module DiscoverHelper
  # "ya vía NVDA" when a referent of this basket is already held, "sin
  # exposición" otherwise. Both read neutrally on purpose: colouring the second
  # one would say *act here*, which is the advice ADR-0001 forbids (D31).
  def wave_exposure(wave, owned_symbols)
    held = wave.referents.find { |referent| owned_symbols.include?(referent) }

    held ? t("discover.show.olas_via", symbol: held) : t("discover.show.olas_sin_exposicion")
  end

  # The sparkline takes 0-100 heights. SparklineHelper derives them from an
  # Asset; a basket has no Asset by contract (D31 clause 5), so it normalises
  # the closes the wave already carries.
  def wave_sparkline_heights(closes)
    return nil if closes.size < 2

    min, max = closes.minmax
    range = max - min
    return closes.map { 50 } if range.zero?

    closes.map { |close| ((close - min) / range * 100).round.to_i }
  end
end
