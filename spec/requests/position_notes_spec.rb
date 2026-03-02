require "rails_helper"

RSpec.describe "Position notes and labels", type: :request do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }
  let(:asset) { create(:asset, :stock) }
  let!(:position) { create(:position, portfolio: portfolio, asset: asset, status: :open) }

  before { login_as(user) }

  describe "PATCH /positions/:id" do
    it "updates notes" do
      patch position_path(position), params: { position: { notes: "Buy more on dip" } }

      expect(response).to redirect_to(portfolio_path)
      expect(position.reload.notes).to eq("Buy more on dip")
    end

    it "updates labels from comma-separated string" do
      patch position_path(position), params: { position: { labels: "dividend, growth, long-term" } }

      expect(response).to redirect_to(portfolio_path)
      expect(position.reload.labels).to eq(%w[dividend growth long-term])
    end

    it "limits labels to 10" do
      many_labels = (1..15).map { |i| "label#{i}" }.join(",")
      patch position_path(position), params: { position: { labels: many_labels } }

      expect(position.reload.labels.size).to eq(10)
    end

    it "rejects access to other users' positions" do
      other_user = create(:user)
      other_portfolio = other_user.portfolio || create(:portfolio, user: other_user)
      other_position = create(:position, portfolio: other_portfolio, asset: asset, status: :open)

      patch position_path(other_position), params: { position: { notes: "hack" } }

      expect(response).to redirect_to(portfolio_path)
      expect(other_position.reload.notes).to be_nil
    end
  end
end
