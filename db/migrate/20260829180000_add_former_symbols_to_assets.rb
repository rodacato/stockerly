class AddFormerSymbolsToAssets < ActiveRecord::Migration[8.1]
  # A ticker a security used to trade under. EchoStar was SATS until December
  # and is ECHO now; a statement printed then carries the old one forever.
  #
  # Lookup only -- nothing here is ever sent to a provider. The live ticker
  # stays in `symbol` because that is what syncs, and putting a retired one
  # there would freeze the asset for good.
  def change
    add_column :assets, :former_symbols, :string, array: true, default: [], null: false
    add_index :assets, :former_symbols, using: :gin
  end
end
