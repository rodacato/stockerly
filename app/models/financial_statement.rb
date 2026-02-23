class FinancialStatement < ApplicationRecord
  belongs_to :asset

  enum :statement_type, {
    income_statement: "income_statement",
    balance_sheet: "balance_sheet",
    cash_flow: "cash_flow"
  }

  enum :period_type, {
    annual: "annual",
    quarterly: "quarterly"
  }

  validates :statement_type, presence: true
  validates :period_type, presence: true
  validates :fiscal_date_ending, presence: true
  validates :data, presence: true

  scope :for_asset, ->(asset_id) { where(asset_id: asset_id) }
  scope :recent, -> { order(fiscal_date_ending: :desc) }
  scope :income_statements, -> { where(statement_type: :income_statement) }
  scope :balance_sheets, -> { where(statement_type: :balance_sheet) }
  scope :cash_flows, -> { where(statement_type: :cash_flow) }
end
