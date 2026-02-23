# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_23_150040) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alert_events", force: :cascade do |t|
    t.bigint "alert_rule_id"
    t.string "asset_symbol", null: false
    t.datetime "created_at", null: false
    t.integer "event_status", default: 0, null: false
    t.string "message", null: false
    t.datetime "triggered_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["alert_rule_id"], name: "index_alert_events_on_alert_rule_id"
    t.index ["event_status"], name: "index_alert_events_on_event_status"
    t.index ["user_id", "triggered_at"], name: "index_alert_events_on_user_id_and_triggered_at"
    t.index ["user_id"], name: "index_alert_events_on_user_id"
  end

  create_table "alert_preferences", force: :cascade do |t|
    t.boolean "browser_push", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "email_digest", default: true, null: false
    t.boolean "sms_notifications", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_alert_preferences_on_user_id", unique: true
  end

  create_table "alert_rules", force: :cascade do |t|
    t.string "asset_symbol", null: false
    t.integer "condition", null: false
    t.datetime "created_at", null: false
    t.integer "status", default: 0, null: false
    t.decimal "threshold_value", precision: 15, scale: 4, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["asset_symbol"], name: "index_alert_rules_on_asset_symbol"
    t.index ["user_id", "status"], name: "index_alert_rules_on_user_id_and_status"
    t.index ["user_id"], name: "index_alert_rules_on_user_id"
  end

  create_table "asset_price_histories", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.decimal "close", precision: 15, scale: 4, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "high", precision: 15, scale: 4
    t.decimal "low", precision: 15, scale: 4
    t.decimal "open", precision: 15, scale: 4
    t.datetime "updated_at", null: false
    t.bigint "volume"
    t.index ["asset_id", "date"], name: "index_asset_price_histories_on_asset_id_and_date", unique: true
    t.index ["asset_id"], name: "index_asset_price_histories_on_asset_id"
    t.index ["date"], name: "index_asset_price_histories_on_date"
  end

  create_table "assets", force: :cascade do |t|
    t.integer "asset_type", default: 0, null: false
    t.decimal "change_percent_24h", precision: 8, scale: 4
    t.string "country", limit: 2
    t.datetime "created_at", null: false
    t.decimal "current_price", precision: 15, scale: 4
    t.string "data_source"
    t.decimal "div_yield", precision: 8, scale: 4
    t.string "exchange"
    t.string "logo_url"
    t.decimal "market_cap", precision: 20, scale: 2
    t.string "name", null: false
    t.decimal "pe_ratio", precision: 10, scale: 4
    t.datetime "price_updated_at"
    t.string "sector"
    t.bigint "shares_outstanding"
    t.string "symbol", null: false
    t.integer "sync_status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "volume"
    t.index ["asset_type", "sector"], name: "index_assets_on_asset_type_and_sector"
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["country", "asset_type"], name: "index_assets_on_country_and_asset_type"
    t.index ["country"], name: "index_assets_on_country"
    t.index ["exchange"], name: "index_assets_on_exchange"
    t.index ["sector"], name: "index_assets_on_sector"
    t.index ["symbol"], name: "index_assets_on_symbol", unique: true
    t.index ["sync_status"], name: "index_assets_on_sync_status"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.jsonb "changes_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
  end

  create_table "dividend_payments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dividend_id", null: false
    t.bigint "portfolio_id", null: false
    t.datetime "received_at"
    t.decimal "shares_held", precision: 15, scale: 6, null: false
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "dividend_id"], name: "index_dividend_payments_on_portfolio_id_and_dividend_id", unique: true
  end

  create_table "dividends", force: :cascade do |t|
    t.decimal "amount_per_share", precision: 10, scale: 4, null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.date "ex_date", null: false
    t.date "pay_date"
    t.datetime "updated_at", null: false
    t.index ["asset_id", "ex_date"], name: "index_dividends_on_asset_id_and_ex_date", unique: true
    t.index ["asset_id"], name: "index_dividends_on_asset_id"
    t.index ["ex_date"], name: "index_dividends_on_ex_date"
  end

  create_table "earnings_events", force: :cascade do |t|
    t.decimal "actual_eps", precision: 10, scale: 4
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.decimal "estimated_eps", precision: 10, scale: 4
    t.date "report_date", null: false
    t.integer "timing", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "report_date"], name: "index_earnings_events_on_asset_id_and_report_date", unique: true
    t.index ["asset_id"], name: "index_earnings_events_on_asset_id"
    t.index ["report_date"], name: "index_earnings_events_on_report_date"
  end

  create_table "fear_greed_readings", force: :cascade do |t|
    t.string "classification", null: false
    t.jsonb "component_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "fetched_at", null: false
    t.string "index_type", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.integer "value", null: false
    t.index ["index_type", "fetched_at"], name: "index_fear_greed_readings_on_index_type_and_fetched_at"
  end

  create_table "fx_rates", force: :cascade do |t|
    t.string "base_currency", null: false
    t.datetime "created_at", null: false
    t.datetime "fetched_at", null: false
    t.string "quote_currency", null: false
    t.decimal "rate", precision: 15, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.index ["base_currency", "quote_currency"], name: "index_fx_rates_on_base_currency_and_quote_currency", unique: true
    t.index ["fetched_at"], name: "index_fx_rates_on_fetched_at"
  end

  create_table "integrations", force: :cascade do |t|
    t.string "api_key_encrypted"
    t.integer "connection_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "last_sync_at"
    t.string "provider_name", null: false
    t.string "provider_type", null: false
    t.boolean "requires_api_key", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["connection_status"], name: "index_integrations_on_connection_status"
    t.index ["provider_name"], name: "index_integrations_on_provider_name", unique: true
  end

  create_table "market_indices", force: :cascade do |t|
    t.decimal "change_percent", precision: 8, scale: 4
    t.datetime "created_at", null: false
    t.string "exchange"
    t.boolean "is_open", default: false, null: false
    t.string "name", null: false
    t.string "symbol", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 15, scale: 4
    t.index ["symbol"], name: "index_market_indices_on_symbol", unique: true
  end

  create_table "news_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "image_url"
    t.datetime "published_at", null: false
    t.string "related_ticker"
    t.string "source", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["published_at"], name: "index_news_articles_on_published_at"
    t.index ["related_ticker"], name: "index_news_articles_on_related_ticker"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.integer "notification_type", default: 0, null: false
    t.boolean "read", default: false, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
  end

  create_table "portfolio_snapshots", force: :cascade do |t|
    t.decimal "cash_value", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "invested_value", precision: 15, scale: 2, null: false
    t.bigint "portfolio_id", null: false
    t.decimal "total_value", precision: 15, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_portfolio_snapshots_on_date"
    t.index ["portfolio_id", "date"], name: "index_portfolio_snapshots_on_portfolio_id_and_date", unique: true
  end

  create_table "portfolios", force: :cascade do |t|
    t.decimal "buying_power", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.date "inception_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id", unique: true
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.decimal "avg_cost", precision: 15, scale: 4, null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "opened_at"
    t.bigint "portfolio_id", null: false
    t.decimal "shares", precision: 15, scale: 6, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_positions_on_asset_id"
    t.index ["portfolio_id", "asset_id", "status"], name: "index_positions_on_portfolio_id_and_asset_id_and_status"
    t.index ["portfolio_id"], name: "index_positions_on_portfolio_id"
    t.index ["status"], name: "index_positions_on_status"
  end

  create_table "remember_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_used_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_remember_tokens_on_token_digest", unique: true
    t.index ["user_id", "expires_at"], name: "index_remember_tokens_on_user_id_and_expires_at"
    t.index ["user_id"], name: "index_remember_tokens_on_user_id"
  end

  create_table "system_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "duration_seconds", precision: 10, scale: 3
    t.text "error_message"
    t.string "log_uid"
    t.string "module_name", null: false
    t.integer "severity", default: 0, null: false
    t.string "task_name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_system_logs_on_created_at"
    t.index ["module_name"], name: "index_system_logs_on_module_name"
    t.index ["severity", "created_at"], name: "index_system_logs_on_severity_and_created_at"
    t.index ["severity"], name: "index_system_logs_on_severity"
  end

  create_table "trades", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "executed_at", null: false
    t.decimal "fee", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "portfolio_id", null: false
    t.bigint "position_id"
    t.decimal "price_per_share", precision: 15, scale: 4, null: false
    t.decimal "shares", precision: 15, scale: 6, null: false
    t.integer "side", null: false
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_trades_on_asset_id"
    t.index ["executed_at"], name: "index_trades_on_executed_at"
    t.index ["portfolio_id", "asset_id"], name: "index_trades_on_portfolio_id_and_asset_id"
    t.index ["portfolio_id"], name: "index_trades_on_portfolio_id"
    t.index ["position_id"], name: "index_trades_on_position_id"
    t.index ["side"], name: "index_trades_on_side"
  end

  create_table "trend_scores", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.datetime "calculated_at", null: false
    t.datetime "created_at", null: false
    t.integer "direction", default: 0, null: false
    t.integer "label", default: 0, null: false
    t.integer "score", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "calculated_at"], name: "index_trend_scores_on_asset_id_and_calculated_at"
    t.index ["asset_id"], name: "index_trend_scores_on_asset_id"
    t.index ["score"], name: "index_trend_scores_on_score"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.boolean "is_verified", default: false, null: false
    t.datetime "onboarded_at"
    t.string "password_digest", null: false
    t.string "preferred_currency", default: "USD", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "watchlist_items", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.decimal "entry_price", precision: 15, scale: 4
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "asset_id"], name: "index_watchlist_items_on_user_id_and_asset_id", unique: true
  end

  add_foreign_key "alert_events", "alert_rules"
  add_foreign_key "alert_events", "users"
  add_foreign_key "alert_preferences", "users"
  add_foreign_key "alert_rules", "users"
  add_foreign_key "asset_price_histories", "assets"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "dividend_payments", "dividends"
  add_foreign_key "dividend_payments", "portfolios"
  add_foreign_key "dividends", "assets"
  add_foreign_key "earnings_events", "assets"
  add_foreign_key "notifications", "users"
  add_foreign_key "portfolio_snapshots", "portfolios"
  add_foreign_key "portfolios", "users"
  add_foreign_key "positions", "assets"
  add_foreign_key "positions", "portfolios"
  add_foreign_key "remember_tokens", "users"
  add_foreign_key "trades", "assets"
  add_foreign_key "trades", "portfolios"
  add_foreign_key "trades", "positions"
  add_foreign_key "trend_scores", "assets"
  add_foreign_key "watchlist_items", "assets"
  add_foreign_key "watchlist_items", "users"
end
