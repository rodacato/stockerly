require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#duration_in_words_es" do
    it "renders whole hours" do
      expect(helper.duration_in_words_es(2.hours)).to eq("2 horas")
      expect(helper.duration_in_words_es(1.hour)).to eq("1 hora")
    end

    it "renders whole minutes" do
      expect(helper.duration_in_words_es(30.minutes)).to eq("30 minutos")
      expect(helper.duration_in_words_es(1.minute)).to eq("1 minuto")
    end

    it "falls back to seconds when the duration divides into neither" do
      expect(helper.duration_in_words_es(90.seconds)).to eq("90 segundos")
    end
  end

  describe "#card_classes" do
    it "carries the shape D61 settled on, whatever the caller adds" do
      expect(helper.card_classes("p-5")).to eq("rounded-2xl border border-border-default bg-bg-surface p-5")
    end

    it "is the bare shape when a card adds nothing" do
      expect(helper.card_classes).to eq("rounded-2xl border border-border-default bg-bg-surface")
    end

    # The shape is four utilities and nothing else: padding, layout and shadow
    # differ at nearly every call site, so encoding them here would recreate
    # the argument-taking partial D61 rejected.
    it "leaves padding and layout to the caller" do
      expect(described_class::CARD_SHAPE).not_to match(/\bp-\d|\bflex\b|\bshadow/)
    end
  end
end
