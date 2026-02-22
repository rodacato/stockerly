class CreateSystemLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_logs do |t|
      t.string  :task_name,        null: false
      t.string  :module_name,      null: false
      t.integer :severity,         null: false, default: 0
      t.decimal :duration_seconds, precision: 10, scale: 3
      t.text    :error_message
      t.string  :log_uid

      t.timestamps
    end

    add_index :system_logs, :severity
    add_index :system_logs, :module_name
    add_index :system_logs, :created_at
    add_index :system_logs, [:severity, :created_at]
  end
end
