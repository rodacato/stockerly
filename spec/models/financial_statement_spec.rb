require "rails_helper"

RSpec.describe FinancialStatement, type: :model do
  subject(:statement) { build(:financial_statement) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires statement_type" do
      statement.statement_type = nil
      expect(statement).not_to be_valid
    end

    it "requires period_type" do
      statement.period_type = nil
      expect(statement).not_to be_valid
    end

    it "requires fiscal_date_ending" do
      statement.fiscal_date_ending = nil
      expect(statement).not_to be_valid
    end

    it "requires data" do
      statement.data = nil
      expect(statement).not_to be_valid
    end

    it "belongs to asset" do
      statement.asset = nil
      expect(statement).not_to be_valid
    end
  end

  describe "enums" do
    it "defines statement_type enum with string values" do
      expect(described_class.statement_types).to eq(
        "income_statement" => "income_statement",
        "balance_sheet" => "balance_sheet",
        "cash_flow" => "cash_flow"
      )
    end

    it "defines period_type enum with string values" do
      expect(described_class.period_types).to eq(
        "annual" => "annual",
        "quarterly" => "quarterly"
      )
    end
  end

  describe "scopes" do
    let(:asset) { create(:asset) }
    let!(:annual_income) do
      create(:financial_statement, asset: asset, statement_type: "income_statement",
             period_type: "annual", fiscal_date_ending: Date.new(2024, 9, 30))
    end
    let!(:quarterly_bs) do
      create(:financial_statement, :balance_sheet, :quarterly, asset: asset,
             fiscal_date_ending: Date.new(2024, 12, 31))
    end
    let!(:cash_flow) do
      create(:financial_statement, :cash_flow, asset: asset,
             fiscal_date_ending: Date.new(2023, 9, 30))
    end

    it ".income_statements returns only income statements" do
      expect(described_class.income_statements).to contain_exactly(annual_income)
    end

    it ".balance_sheets returns only balance sheets" do
      expect(described_class.balance_sheets).to contain_exactly(quarterly_bs)
    end

    it ".cash_flows returns only cash flows" do
      expect(described_class.cash_flows).to contain_exactly(cash_flow)
    end

    it ".annual returns only annual statements" do
      expect(described_class.annual).to contain_exactly(annual_income, cash_flow)
    end

    it ".quarterly returns only quarterly statements" do
      expect(described_class.quarterly).to contain_exactly(quarterly_bs)
    end

    it ".for_asset filters by asset_id" do
      other = create(:financial_statement, asset: create(:asset, symbol: "MSFT"))
      expect(described_class.for_asset(asset.id)).to contain_exactly(annual_income, quarterly_bs, cash_flow)
      expect(described_class.for_asset(asset.id)).not_to include(other)
    end

    it ".recent orders by fiscal_date_ending desc" do
      expect(described_class.recent.to_a).to eq([ quarterly_bs, annual_income, cash_flow ])
    end
  end

  describe "uniqueness constraint" do
    let(:asset) { create(:asset) }

    it "enforces unique [asset_id, statement_type, period_type, fiscal_date_ending]" do
      create(:financial_statement, asset: asset, statement_type: "income_statement",
             period_type: "annual", fiscal_date_ending: Date.new(2024, 9, 30))

      duplicate = build(:financial_statement, asset: asset, statement_type: "income_statement",
                        period_type: "annual", fiscal_date_ending: Date.new(2024, 9, 30))

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
