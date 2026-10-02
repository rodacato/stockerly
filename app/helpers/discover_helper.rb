module DiscoverHelper
  WAVES_STALE_AFTER = 6.hours

  # "ya vía NVDA" when a referent of this basket is already held, "sin
  # exposición" otherwise. Both read neutrally on purpose: colouring the second
  # one would say *act here*, which is the advice ADR-0001 forbids (D31).
  def wave_exposure(wave, owned_symbols)
    held = wave.referents.find { |referent| owned_symbols.include?(referent) }

    held ? t("discover.show.olas_via", symbol: held) : t("discover.show.olas_sin_exposicion")
  end

  def wave_vs_baseline(wave)
    t("discover.show.olas_vs", baseline: MarketData::Discover::BasketCatalogue.baseline,
                               value: signed_points(wave.vs_baseline))
  end

  def wave_baseline_note(wave)
    return unless MarketData::Discover::BasketCatalogue.baseline_noted?(wave.symbol)

    t("discover.show.olas_baseline_nota", baseline: MarketData::Discover::BasketCatalogue.baseline)
  end

  def waves_age(generated_at)
    return unless generated_at

    age = Time.current - generated_at
    t("discover.show.olas_antiguedad", count: (age / 1.hour).floor) if age > WAVES_STALE_AFTER
  end
end
