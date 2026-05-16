class CreateInviteCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :invite_codes do |t|
      t.string :code, null: false
      t.string :note
      t.datetime :used_at
      t.references :used_by_user, foreign_key: { to_table: :users }
      t.references :created_by_user, foreign_key: { to_table: :users }, null: false
      t.timestamps
    end

    add_index :invite_codes, :code, unique: true
  end
end
