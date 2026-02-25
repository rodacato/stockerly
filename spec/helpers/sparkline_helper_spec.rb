require "rails_helper"

RSpec.describe SparklineHelper do
  let(:asset) { create(:asset) }

  describe "#sparkline_heights" do
    context "with price history data" do
      before do
        7.times do |i|
          create(:asset_price_history, asset: asset, date: (7 - i).days.ago.to_date, close: 100 + (i * 10))
        end
      end

      it "returns normalized heights between 0 and 100" do
        heights = helper.sparkline_heights(asset)

        expect(heights).to be_an(Array)
        expect(heights.size).to eq(7)
        expect(heights.first).to eq(0)
        expect(heights.last).to eq(100)
        heights.each { |h| expect(h).to be_between(0, 100) }
      end
    end

    context "with flat prices" do
      before do
        3.times do |i|
          create(:asset_price_history, asset: asset, date: (3 - i).days.ago.to_date, close: 50.0)
        end
      end

      it "returns constant heights of 50" do
        heights = helper.sparkline_heights(asset)

        expect(heights).to all(eq(50))
      end
    end

    context "with fewer than 2 data points" do
      it "returns nil when no history" do
        expect(helper.sparkline_heights(asset)).to be_nil
      end

      it "returns nil with only 1 data point" do
        create(:asset_price_history, asset: asset, date: Date.current, close: 100)
        expect(helper.sparkline_heights(asset)).to be_nil
      end
    end

    context "with custom days parameter" do
      before do
        14.times do |i|
          create(:asset_price_history, asset: asset, date: (14 - i).days.ago.to_date, close: 100 + i)
        end
      end

      it "limits to specified number of days" do
        heights = helper.sparkline_heights(asset, days: 5)

        expect(heights.size).to eq(5)
      end
    end

    context "with preloaded association" do
      before do
        7.times do |i|
          create(:asset_price_history, asset: asset, date: (7 - i).days.ago.to_date, close: 100 + (i * 10))
        end
      end

      it "uses preloaded data without extra queries" do
        preloaded_asset = Asset.includes(:asset_price_histories).find(asset.id)

        queries = []
        callback = lambda { |_name, _start, _finish, _id, payload| queries << payload[:sql] }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          helper.sparkline_heights(preloaded_asset)
        end

        expect(queries.none? { |q| q.include?("asset_price_histories") }).to be true
      end

      it "returns correct heights from preloaded data" do
        preloaded_asset = Asset.includes(:asset_price_histories).find(asset.id)
        heights = helper.sparkline_heights(preloaded_asset)

        expect(heights).to be_an(Array)
        expect(heights.size).to eq(7)
        expect(heights.first).to eq(0)
        expect(heights.last).to eq(100)
      end
    end
  end
end
