require "rails_helper"

# D136: the `info` family was annotated in the stylesheet as an alias of
# `primary` and carried its exact values in both themes — three token pairs,
# zero distinct values, one consumer. Duplication is the expensive half; the
# name is retired and the import notice reads in the brand accent.
RSpec.describe "The retired info token family", type: :request do
  let(:user) { create(:user, preferred_currency: "USD", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:vt) { create(:asset, :etf, symbol: "VT", currency: "USD") }
  let(:csv) do
    "asset_symbol,side,shares,price_per_share,executed_at,external_id,currency\n" \
      "VT,buy,2.0,100.0,2025-12-08,order-1,USD"
  end

  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico")
    login_as(user)
  end

  it "defines no info token in either theme" do
    css = Rails.root.join("app/assets/tailwind/application.css").read

    expect(css).not_to include("--color-info")
  end

  it "leaves its one consumer reading in the brand accent" do
    post preview_trade_import_path, params: { contenido: csv }

    notice = Capybara.string(response.body).find("p[role='status']")
    expect(notice[:class]).to include("bg-primary-muted", "text-primary-fg")
    expect(notice[:class]).not_to include("info")
  end
end
