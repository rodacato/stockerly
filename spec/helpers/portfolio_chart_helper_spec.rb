require "rails_helper"

RSpec.describe PortfolioChartHelper, type: :helper do
  describe "#portfolio_chart_data" do
    let(:data_points) do
      [
        { date: 3.days.ago.to_date, value: 1800.0 },
        { date: 2.days.ago.to_date, value: 1850.0 },
        { date: 1.day.ago.to_date, value: 1900.0 },
        { date: Date.current, value: 2000.0 }
      ]
    end

    it "generates SVG chart data from data points" do
      result = helper.portfolio_chart_data(data_points)

      expect(result).to be_a(Hash)
      expect(result[:points]).to be_present
      expect(result[:area]).to be_present
      expect(result[:color]).to eq("#10b981") # green for uptrend
      expect(result[:min_value]).to eq(1800.0)
      expect(result[:max_value]).to eq(2000.0)
    end

    it "returns nil with fewer than 2 data points" do
      result = helper.portfolio_chart_data([ { date: Date.current, value: 100.0 } ])

      expect(result).to be_nil
    end

    it "uses red color for downtrend" do
      declining = [
        { date: 2.days.ago.to_date, value: 2000.0 },
        { date: Date.current, value: 1800.0 }
      ]

      result = helper.portfolio_chart_data(declining)

      expect(result[:color]).to eq("#ef4444")
    end

    it "includes first and last dates" do
      result = helper.portfolio_chart_data(data_points)

      expect(result[:first_date]).to eq(3.days.ago.to_date)
      expect(result[:last_date]).to eq(Date.current)
    end
  end
end
