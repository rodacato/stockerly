# How an instrument is named to a person. A CETE's symbol (CETES_28D) is an
# internal key; on screen it is "CETES 28d", and its name follows the glossary,
# "CETES a 28 días", not the English the sync stores. Everything else keeps its
# own symbol and name. Routes and stored values never change.
module InstrumentLabel
  CETES = /\ACETES_(\d+)D\z/i

  def self.short(symbol)
    term = term(symbol)
    term ? "CETES #{term}d" : symbol
  end

  def self.name(symbol, name)
    term = term(symbol)
    term ? I18n.t("instrumentos.cetes", dias: term) : name
  end

  def self.term(symbol) = symbol.to_s[CETES, 1]&.to_i
end
