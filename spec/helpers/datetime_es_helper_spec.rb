require "rails_helper"

RSpec.describe DatetimeEsHelper do
  describe "#relative_age" do
    it "reads the first minute as an instant rather than a count of seconds" do
      expect(helper.relative_age(20.seconds.ago)).to eq("hace un instante")
    end

    it "counts minutes under the hour" do
      expect(helper.relative_age(20.minutes.ago)).to eq("hace 20 min")
    end

    it "counts hours under the day" do
      expect(helper.relative_age(3.hours.ago)).to eq("hace 3 h")
    end

    it "counts days, spelled out rather than abbreviated" do
      expect(helper.relative_age(5.days.ago)).to eq("hace 5 días")
    end

    it "names yesterday instead of counting one day" do
      expect(helper.relative_age(30.hours.ago)).to eq("ayer")
    end

    it "does not count backwards when a timestamp is slightly in the future" do
      expect(helper.relative_age(10.seconds.from_now)).to eq("hace un instante")
    end

    it "lets each surface name its own empty state" do
      expect(helper.relative_age(nil)).to eq("—")
      expect(helper.relative_age(nil, blank: "nunca")).to eq("nunca")
    end
  end

  describe "#absolute_stamp" do
    it "writes the date in es-MX with a padded day" do
      time = Time.utc(2026, 8, 3, 20, 32)

      expect(helper.absolute_stamp(time)).to eq("03 AGO 2026 · 14:32")
    end

    it "takes the date and the time from the same CDMX conversion" do
      # 00:30 UTC is still the previous evening in CDMX. Reading the date off
      # the raw timestamp dated this row tomorrow.
      time = Time.utc(2026, 8, 31, 0, 30)

      expect(helper.absolute_stamp(time)).to eq("30 AGO 2026 · 18:30")
    end

    it "adds seconds only where a surface asks for them" do
      time = Time.utc(2026, 8, 3, 20, 32, 45)

      expect(helper.absolute_stamp(time)).to eq("03 AGO 2026 · 14:32")
      expect(helper.absolute_stamp(time, seconds: true)).to eq("03 AGO 2026 · 14:32:45")
    end

    it "lets each surface name its own empty state" do
      expect(helper.absolute_stamp(nil)).to eq("—")
      expect(helper.absolute_stamp(nil, blank: "sin registro")).to eq("sin registro")
    end
  end
end
