module Trading
  module Domain
    # Raised where a figure cannot honestly be expressed in the target
    # currency: no row for the pair, or a buy trade with no rate captured at
    # execution. Narrow on purpose — the screens degrade on this one, and a
    # bare RuntimeError let them swallow ordinary bugs as "Sin consolidar".
    class MissingFxRate < StandardError; end
  end
end
