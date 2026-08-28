class AddOtpLastUsedAtToUsers < ActiveRecord::Migration[8.1]
  # ROTP accepts the same code twice inside its 30-second window. Recording
  # when a code was accepted lets `verify(after:)` refuse a replay, which is
  # the difference between using the library and using it naively.
  def change
    add_column :users, :otp_last_used_at, :datetime
  end
end
