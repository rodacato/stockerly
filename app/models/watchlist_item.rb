class WatchlistItem < ApplicationRecord
  belongs_to :user
  belongs_to :asset

  validates :asset_id, uniqueness: { scope: :user_id, message: "already in watchlist" }

  before_create :capture_entry_price

  private

  def capture_entry_price
    self.entry_price ||= asset.current_price
  end
end
