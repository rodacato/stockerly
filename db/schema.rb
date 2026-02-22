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

ActiveRecord::Schema[8.1].define(version: 2026_02_22_005507) do
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

  create_table "assets", force: :cascade do |t|
    t.integer "asset_type", default: 0, null: false
    t.decimal "change_percent_24h", precision: 8, scale: 4
    t.datetime "created_at", null: false
    t.decimal "current_price", precision: 15, scale: 4
    t.string "data_source"
    t.decimal "div_yield", precision: 8, scale: 4
    t.string "exchange"
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
    t.index ["exchange"], name: "index_assets_on_exchange"
    t.index ["sector"], name: "index_assets_on_sector"
    t.index ["symbol"], name: "index_assets_on_symbol", unique: true
    t.index ["sync_status"], name: "index_assets_on_sync_status"
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

  create_table "portfolios", force: :cascade do |t|
    t.decimal "buying_power", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.date "inception_date"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id", unique: true
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

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "full_name", null: false
    t.boolean "is_verified", default: false, null: false
    t.string "password_digest", null: false
    t.string "preferred_currency", default: "USD", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "alert_events", "alert_rules"
  add_foreign_key "alert_events", "users"
  add_foreign_key "alert_preferences", "users"
  add_foreign_key "alert_rules", "users"
  add_foreign_key "portfolios", "users"
  add_foreign_key "remember_tokens", "users"
end
