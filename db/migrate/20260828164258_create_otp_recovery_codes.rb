class CreateOtpRecoveryCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_recovery_codes do |t|
      t.references :user, null: false, foreign_key: true
      # BCrypt digest, never the code. A recovery code is a password that is
      # shown once, so it is stored the way a password is.
      t.string :code_digest, null: false
      t.datetime :consumed_at

      t.timestamps
    end

    # Verification walks the user's unconsumed codes; nothing looks a code up
    # by digest, because BCrypt salts make that impossible by design.
    add_index :otp_recovery_codes, [ :user_id, :consumed_at ]
  end
end
