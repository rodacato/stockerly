require "rails_helper"

RSpec.describe PortfoliosHelper, type: :helper do
  describe "#sector_segments" do
    it "translates Yahoo's sector names, largest first" do
      segments = helper.sector_segments({ "Technology" => 300.to_d, "Financial Services" => 700.to_d })

      expect(segments.pluck(:label)).to eq([ "Servicios financieros", "Tecnología" ])
      expect(segments.pluck(:pct)).to eq([ 70, 30 ])
    end

    it "groups holdings with no sector (CETES, crypto) under one label" do
      segments = helper.sector_segments({ nil => 100.to_d, "" => 100.to_d, "Energy" => 200.to_d })

      expect(segments.map { |s| [ s[:label], s[:pct] ] }).to contain_exactly([ "Sin sector", 50 ], [ "Energía", 50 ])
    end

    it "names what has no sector by what it is, not as missing data" do
      segments = helper.sector_segments({ :etf => 300.to_d, :crypto => 100.to_d, "Energy" => 600.to_d })

      expect(segments.pluck(:label)).to eq([ "Energía", "ETF", "Cripto" ])
    end

    it "shows a sector the table does not know as Yahoo gives it" do
      expect(helper.sector_segments({ "Space Mining" => 100.to_d }).first[:label]).to eq("Space Mining")
    end

    it "folds what does not fit the palette into Otros, so no two segments share a colour" do
      allocation = (1..10).to_h { |n| [ "Sector #{n}", (100 - n).to_d ] }

      segments = helper.sector_segments(allocation)

      expect(segments.size).to eq(PortfoliosHelper::CHART_COLORS.size)
      expect(segments.last[:label]).to eq("Otros")
      expect(segments.pluck(:color).uniq.size).to eq(segments.size)
    end
  end
end
