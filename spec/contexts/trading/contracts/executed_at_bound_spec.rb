require "rails_helper"

# JTBD #5 specifies `max: today`. Nothing enforced it until now.
RSpec.describe Trading::Contracts::ExecuteTradeContract, "executed_at bound" do
  before { create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100) }

  def validate(executed_at)
    described_class.new.call(
      asset_symbol: "AAPL", side: "buy", shares: 1.0,
      price_per_share: 100.0, executed_at: executed_at
    )
  end

  it "rejects a date in the future, in es-MX" do
    result = validate(1.day.from_now.to_date.to_s)

    expect(result.errors[:executed_at]).to include(I18n.t("trades.errores.fecha_futura"))
  end

  it "rejects a date that is not a date" do
    expect(validate("no-es-fecha").errors[:executed_at])
      .to include(I18n.t("trades.errores.fecha_invalida"))
  end

  it "accepts today" do
    expect(validate(Date.current.to_s).errors[:executed_at]).to be_blank
  end

  it "accepts a past date — recording late is the whole point of the field" do
    expect(validate(90.days.ago.to_date.to_s).errors[:executed_at]).to be_blank
  end

  it "accepts a blank date, which defaults to now downstream" do
    expect(validate(nil).errors[:executed_at]).to be_blank
  end
end
