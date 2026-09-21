module AssetsHelper
  # D10: a list declares its currency once in the header and rows drop the
  # symbol; anything NOT in the declared currency keeps its ISO prefix, because
  # a bare figure across a mixed MXN+USD portfolio is the exact ambiguity the
  # multi-currency work exists to kill.
  def money_cell(amount, currency:, declared:, precision: 2)
    return format_currency_mx(amount, currency: currency, precision: precision) if currency.to_s != declared.to_s

    number_with_precision(amount || 0, precision: precision, delimiter: ",")
  end

  # Returns [amount, currency]. Portfolio#convert fails loud on a missing rate,
  # which is right for a calculation and wrong for a screen — a 500 instead of
  # your holdings. D10 already allows the honest fallback: show the figure in
  # its own currency with its ISO prefix rather than invent a conversion.
  def position_amount(position, declared)
    native = position.market_value
    from = position.asset.currency
    return [ native, declared ] if from == declared

    [ position.portfolio.convert(native, from: from, to: declared), declared ]
  rescue Trading::Domain::MissingFxRate
    [ native, from ]
  end

  # One percent format, two readings. A change that moved carries its sign, and
  # the sign is the typographic minus — a hyphen is a separator, not a sign. A
  # flat change has no direction to sign, and a distance ("falta 3.2%",
  # "necesita subir 1.4%") is a magnitude the copy gives a direction to, so
  # neither carries one.
  def signed_percent(percent)
    value = percent.to_f
    return unsigned_percent(value) if value.zero?

    "#{value.negative? ? "−" : "+"}#{unsigned_percent(value)}"
  end

  def unsigned_percent(percent)
    "#{number_with_precision(percent.to_f.abs, precision: 1)}%"
  end

  # An unknown day change is drawn as a dash, never as 0%: an asset without a
  # previous close has not been flat, it has nothing to compare against.
  def day_change_slot(percent)
    return { text: "—", color: "text-fg-subtle" } if percent.nil?

    { text: signed_percent(percent), color: gain_color(percent) }
  end

  def day_change_direction(percent)
    return :flat if percent.nil? || percent.zero?

    percent.negative? ? :down : :up
  end

  # D69's first emphasis slot: a fixed-income lot near its maturity reports the
  # days left instead of a day change it does not have.
  def maturity_days(position)
    Trading::Domain::MaturityWindow.days_until(position)
  end

  # D9's ladder, cheapest first: owning implies following implies tracked.
  def tracked_tier(asset, held_ids:, followed_ids:)
    return :held if held_ids.include?(asset.id)
    return :followed if followed_ids.include?(asset.id)

    :tracked
  end

  def gain_color(value)
    amount = value.to_f
    return "text-fg-subtle" if amount.zero?

    amount.negative? ? "text-negative" : "text-positive"
  end

  # watchlist_items.entry_price is captured on add and nothing has ever
  # rendered it. This is the "sigues +X%" the design asks for.
  def followed_since_percent(item)
    entry = item.entry_price
    current = item.asset.current_price
    return nil if entry.blank? || entry.zero? || current.blank?

    (current - entry) / entry * 100
  end
end
