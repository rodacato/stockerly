class AddExpiresAtToInviteCodes < ActiveRecord::Migration[8.1]
  def up
    add_column :invite_codes, :expires_at, :datetime

    execute <<-SQL.squish
      UPDATE invite_codes
      SET expires_at = created_at + INTERVAL '7 days'
      WHERE expires_at IS NULL
    SQL

    change_column_null :invite_codes, :expires_at, false
    add_index :invite_codes, :expires_at
  end

  def down
    remove_index :invite_codes, :expires_at
    remove_column :invite_codes, :expires_at
  end
end
