class AddTotpToUsers < ActiveRecord::Migration[8.1]
  def change
    # The secret is encrypted at rest by `encrypts :otp_secret`, so the column
    # holds ciphertext and is sized for it rather than for a 32-char base32.
    add_column :users, :otp_secret, :text
    add_column :users, :otp_enrolled_at, :datetime
  end
end
