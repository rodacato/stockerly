module InstrumentsHelper
  def asset_label(asset) = InstrumentLabel.short(asset.symbol)

  def asset_display_name(asset) = InstrumentLabel.name(asset.symbol, asset.name)
end
