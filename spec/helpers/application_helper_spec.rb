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

  describe "#button_classes" do
    # #484's own acceptance criterion, and the reason D61's majority rule was
    # rejected here: collapsing these two would change the design.
    it "never renders the screen's own action and an inline one alike" do
      expect(helper.button_classes(:primary, :lg)).not_to eq(helper.button_classes(:primary, :sm))
    end

    it "carries the radius and padding of the size it is given" do
      expect(helper.button_classes(:primary, :lg)).to include("rounded-xl", "py-3.5", "text-base")
      expect(helper.button_classes(:primary, :sm)).to include("rounded-lg", "py-2", "text-sm")
    end

    # The label token, not text-white: fg-inverse is #0F172A in dark, where
    # white on the dark-mode primary measures 3.06:1 and fails AA.
    it "paints the primary label with the token that flips in dark mode" do
      expect(helper.button_classes(:primary)).to include("text-fg-inverse")
      expect(helper.button_classes(:primary)).not_to include("text-white")
    end

    it "keeps the variant's skin independent of its size" do
      %i[lg md sm].each do |size|
        expect(helper.button_classes(:secondary, size)).to include("border-border-default")
        expect(helper.button_classes(:danger, size)).to include("border-negative")
      end
    end

    it "appends the call site's own layout untouched" do
      expect(helper.button_classes(:primary, :md, "w-full cursor-pointer")).to include("w-full", "cursor-pointer")
    end

    # Negative: an unknown size is a typo, and a typo must not silently render
    # an unstyled button.
    it "refuses a size it does not define" do
      expect { helper.button_classes(:primary, :huge) }.to raise_error(KeyError)
      expect { helper.button_classes(:fancy, :md) }.to raise_error(KeyError)
    end
  end

  describe "#field_classes" do
    it "keeps its three steps distinct" do
      sizes = %i[lg md sm].map { |s| helper.field_classes(s) }

      expect(sizes.uniq.size).to eq(3)
    end

    it "carries the focus ring every input shares" do
      expect(helper.field_classes(:md)).to include("focus:ring-focus")
    end
  end
end
