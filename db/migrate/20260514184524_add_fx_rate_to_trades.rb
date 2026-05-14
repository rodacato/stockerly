class AddFxRateToTrades < ActiveRecord::Migration[8.1]
  def change
    # Nullable on purpose: historical trades will be backfilled by the #44 rake task.
    # Once S2-D lands and backfill is complete, a follow-up migration adds `null: false`.
    #
    # Semantics: `fx_rate_at_execution` is the rate captured WHEN the trade was recorded,
    # not necessarily the rate on `executed_at` (we don't store historical FX in this
    # sprint — pragmatic call documented in PR for #42). For backdated trades the user
    # can pass an explicit override via the contract.
    add_column :trades, :fx_rate_at_execution, :decimal, precision: 15, scale: 8
  end
end
