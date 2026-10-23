require "rails_helper"

# ADR-032: the one door. It writes only with the switch on, only what the
# catalogue declares, and never lets recording break the request it rides on.
RSpec.describe Usage do
  def switch(on) = SiteConfig.set(Usage::SWITCH, on)

  it "records nothing while the owner's switch is off" do
    expect { described_class.record("news.opened") }.not_to change(UsageEvent, :count)
  end

  context "with the switch on" do
    before { switch(true) }

    it "records a catalogued event with its screen and declared properties" do
      described_class.record("question.sent", screen: "senales", via: "help")

      expect(UsageEvent.sole).to have_attributes(name: "question.sent", screen: "senales", properties: { "via" => "help" })
    end

    it "refuses a name the catalogue does not declare" do
      expect { described_class.record("page.viewed", screen: "hoy") }.not_to change(UsageEvent, :count)
    end

    it "keeps no undeclared property and no free text in a declared one" do
      described_class.record("question.sent", via: "¿Cuánto llevo en NVDA?", email: "a@b.c")
      described_class.record("rule_suggestion.shown", condition: "price above 200")

      expect(UsageEvent.pluck(:properties)).to eq([ {}, {} ])
    end

    it "keeps a number as a number" do
      described_class.record("trade.created", seconds: "27")

      expect(UsageEvent.sole.properties).to eq("seconds" => 27)
    end

    it "gives up silently when the write fails" do
      allow(UsageEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, "boom")

      expect(described_class.record("news.opened")).to be_nil
    end
  end

  it "counts a day open whatever the switch says" do
    expect { described_class.opened("/alerts") }.to change { AppOpen.where(path: "/alerts").sum(:count) }.by(1)
  end

  it "keeps 90 days and no more" do
    UsageEvent.create!(name: "news.opened", occurred_at: 91.days.ago)
    kept = UsageEvent.create!(name: "news.opened", occurred_at: 89.days.ago)

    UsageEvent.purge_stale!

    expect(UsageEvent.all).to eq([ kept ])
  end
end
