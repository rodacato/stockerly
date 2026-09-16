module DiscoverHelper
  # "ya vía NVDA" when a referent of this basket is already held, "sin
  # exposición" otherwise. Both read neutrally on purpose: colouring the second
  # one would say *act here*, which is the advice ADR-0001 forbids (D31).
  def wave_exposure(wave, owned_symbols)
    held = wave.referents.find { |referent| owned_symbols.include?(referent) }

    held ? t("discover.show.olas_via", symbol: held) : t("discover.show.olas_sin_exposicion")
  end

  # A difference carries its sign, with the typographic minus signed_percent uses.
  def wave_vs_baseline(wave)
    value = wave.vs_baseline.to_f
    figure = "#{value.negative? ? "−" : "+"}#{number_with_precision(value.abs, precision: 1)}"

    t("discover.show.olas_vs", baseline: MarketData::Discover::BasketCatalogue.baseline, value: figure)
  end
end
