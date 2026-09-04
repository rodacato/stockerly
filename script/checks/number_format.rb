# frozen_string_literal: true

require_relative "support"

module Checks
  # #500 and #511 consolidated money and share formatting into MoneyHelper,
  # killing 20 hand-written sites, a literal MXN and an ambiguous $. #541
  # records that two percent conventions still coexist — signed_percent across
  # 8 files, number_to_percentage across 5 — putting two different minus glyphs
  # on screen.
  #
  # This does not pick the percent convention; #541 does. It enforces the part
  # that is already decided: money and percent are formatted by a helper, so
  # whichever convention #541 lands has one place to land in.
  class NumberFormat < Check
    ID = "number-format"
    TITLE = "Money and percent are formatted by a helper, not inline"

    MONEY_HELPER = "app/helpers/money_helper.rb"
    NUMBER_HELPER = /\bnumber_(?:to_currency|to_percentage|to_human|with_precision|with_delimiter)\(/
    CURRENCY_LITERAL = /["']\s*(?:MXN|USD|\$)|\$\s*["']|\$<%/

    def run
      currency_helper + view_formatting
    end

    private

    def currency_helper
      scan(Checks.files("app/**/*.rb", "app/**/*.erb")) do |line|
        "number_to_currency is not the money formatter — MoneyHelper#format_currency_mx is" if line.include?("number_to_currency(")
      end
    end

    # A hand-rolled `<%= n %>%` is deliberately not matched: a CSS width reads
    # identically, and the check would spend its credibility on `width: 40%`.
    def view_formatting
      scan(Checks.files("app/views/**/*.erb")) do |line|
        if line.include?("number_to_percentage(")
          "percent formatted in the view — put it behind a helper so #541 has one place to decide"
        elsif line.match?(NUMBER_HELPER) && line.match?(CURRENCY_LITERAL)
          "a currency literal next to a number helper — MoneyHelper#format_currency_mx carries the currency"
        end
      end
    end
  end
end
