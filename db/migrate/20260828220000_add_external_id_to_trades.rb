class AddExternalIdToTrades < ActiveRecord::Migration[8.1]
  def change
    # The broker's own order id, carried through the import CSV. It is what
    # makes re-running an import safe: the same confirmation downloaded twice
    # is the normal case, not the edge case.
    add_column :trades, :external_id, :string

    # Partial, so manually entered trades — which have no broker id — do not
    # all collide on NULL.
    add_index :trades, [ :portfolio_id, :external_id ],
              unique: true,
              where: "external_id IS NOT NULL",
              name: "index_trades_on_portfolio_and_external_id"
  end
end
