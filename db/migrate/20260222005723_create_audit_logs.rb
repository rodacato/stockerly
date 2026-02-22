class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user,       null: false, foreign_key: true, index: false
      t.string     :action,     null: false
      t.references :auditable,  polymorphic: true, index: true
      t.jsonb      :changes_data, null: false, default: {}
      t.string     :ip_address

      t.timestamps
    end

    add_index :audit_logs, [:user_id, :created_at]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
