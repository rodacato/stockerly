class CreateErrorEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :error_events do |t|
      t.string   :fingerprint,     null: false
      t.string   :exception_class, null: false
      t.text     :message
      t.string   :app_line
      t.jsonb    :backtrace,       null: false, default: []
      t.string   :source,          null: false, default: "other"
      t.string   :reference
      t.string   :request_method
      t.string   :request_path
      t.string   :job_class
      t.jsonb    :request_params,  null: false, default: {}
      t.integer  :occurrences,     null: false, default: 1
      t.datetime :first_seen_at,   null: false
      t.datetime :last_seen_at,    null: false

      t.timestamps
    end

    add_index :error_events, :fingerprint, unique: true
    add_index :error_events, :last_seen_at
    add_index :error_events, :reference
  end
end
