module MarketHelper
  # Returns the visual configuration for the VIX volatility indicator
  # based on the current value. Static class triplets so Tailwind's JIT
  # compiler can see the full class names at build time (no dynamic
  # `text-<color>-600` interpolation).
  def vix_tier(value)
    case value.to_f
    when 0...20
      { icon: "text-emerald-500",
        value: "text-emerald-600 dark:text-emerald-400",
        pill:  "text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/30",
        label: "Volatilidad baja" }
    when 20...30
      { icon: "text-amber-500",
        value: "text-amber-600 dark:text-amber-400",
        pill:  "text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/30",
        label: "Volatilidad moderada" }
    else
      { icon: "text-rose-500",
        value: "text-rose-600 dark:text-rose-400",
        pill:  "text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-900/30",
        label: "Volatilidad alta" }
    end
  end

  # es-MX label for a trend score (0–100). Buckets match the visual
  # strength bar tiers in _listings_table (Fuerte → success bar,
  # Moderada → warning, Débil/Muy débil → error).
  def trend_strength_label(score)
    case score.to_i
    when 80..100 then "Fuerte"
    when 50..79  then "Moderada"
    when 25..49  then "Débil"
    else              "Muy débil"
    end
  end
end
