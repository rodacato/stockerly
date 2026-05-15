class CreateTechnicalObservations < ActiveRecord::Migration[8.1]
  # Persistent technical-zone transitions per asset (#40 JTBD #6).
  # One row per (asset, observation_type, observed_at). Detected daily by
  # DetectTechnicalObservationsJob from asset_price_histories; surfaced
  # filtered by user watchlist + positions on the dashboard.
  #
  # `indicator_snapshot` stores the raw indicator values at detection time
  # (rsi, prev_rsi, close, ma50, ma200, bb_upper, bb_lower, etc.) so the
  # UI can render context without recomputing.
  def change
    create_table :technical_observations do |t|
      t.references :asset, null: false, foreign_key: true
      t.string :observation_type, null: false
      t.datetime :observed_at, null: false
      t.jsonb :indicator_snapshot, default: {}, null: false

      t.timestamps
    end

    # Lookup by asset for the asset detail page; (asset, type) for dedup window.
    add_index :technical_observations, [ :asset_id, :observation_type, :observed_at ],
              name: "index_obs_on_asset_type_date"
    add_index :technical_observations, :observed_at
  end
end
