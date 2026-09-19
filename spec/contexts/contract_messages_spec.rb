require "rails_helper"

# ADR-011: a contract's failures reach the reader through the flash, so they are
# es-MX copy and live in the locale file, named by the rule (`:asset_not_found`)
# rather than written in it. Two things can break that silently — a new
# `key.failure(:sym)` with no copy, and a predicate whose built-in message
# nobody translated — and neither shows up in a screen anybody looks at. This is
# what earns `dry_validation.errors.*` its `ignore_unused` row: i18n-tasks
# cannot see keys dry-validation builds, and this asserts every one resolves.
RSpec.describe "Contract messages" do
  CONTRACTS = Rails.root.glob("app/contexts/*/contracts/**/*.rb").filter_map do |file|
    klass = file.relative_path_from(Rails.root.join("app/contexts")).to_s.delete_suffix(".rb").camelize.safe_constantize
    klass if klass.is_a?(Class) && klass < ApplicationContract
  end

  # Every message the catalogue holds, as a matcher: `%{num}` stands for a value
  # dry-validation interpolates, so the comparison is against the shape.
  def self.catalogue
    I18n.t("dry_validation.errors", locale: :"es-MX")
        .then { |tree| flatten_values(tree) }
        .map { |template| /\A#{Regexp.escape(template).gsub(/%\\\{\w+\\\}/, ".+")}\z/ }
  end

  def self.flatten_values(node)
    case node
    when Hash then node.values.flat_map { |child| flatten_values(child) }
    when String then [ node ]
    else []
    end
  end

  CATALOGUE = catalogue

  it "finds the contracts to check" do
    expect(CONTRACTS.size).to be >= 12
  end

  # Two inputs, because they fail differently: an empty hash trips `key?`, and
  # blank values trip `filled?`, the type checks and the rules themselves.
  def inputs_for(contract)
    keys = contract.schema.key_map.map(&:name)
    [ {}, keys.index_with { "" }, keys.index_with { nil } ]
  end

  CONTRACTS.each do |contract|
    it "states #{contract}'s failures in es-MX" do
      messages = inputs_for(contract).flat_map { |input| contract.new.call(input).errors.to_h.values.flatten }

      expect(messages).not_to be_empty
      messages.each do |message|
        expect(CATALOGUE.any? { |shape| shape.match?(message) })
          .to be(true), "#{contract} said #{message.inspect}, which no dry_validation.errors key in es-MX.yml holds"
      end
    end
  end

  it "has copy for every failure a rule names" do
    symbols = Rails.root.glob("app/contexts/**/*.rb")
              .flat_map { |file| file.read.scan(/key\.failure\(:(\w+)\)/).flatten }
              .uniq

    expect(symbols).not_to be_empty
    symbols.each do |symbol|
      expect { I18n.t("dry_validation.errors.#{symbol}", locale: :"es-MX", raise: true) }
        .not_to raise_error, "key.failure(:#{symbol}) has no dry_validation.errors.#{symbol} in es-MX.yml"
    end
  end
end
