require "rails_helper"

RSpec.describe SkeletonHelper do
  describe "#skeleton_loader" do
    it "renders text skeleton with multiple line placeholders" do
      html = helper.skeleton_loader(type: :text, count: 1)

      expect(html).to include("animate-pulse")
      expect(html).to include("skeleton-shimmer")
      expect(html).to include('aria-hidden="true"')
      expect(html).to include("w-full")
      expect(html).to include("w-4/5")
      expect(html).to include("w-3/5")
    end

    it "renders card skeleton with stat card structure" do
      html = helper.skeleton_loader(type: :card, count: 1)

      expect(html).to include("animate-pulse")
      expect(html).to include("rounded-xl")
      expect(html).to include("skeleton-shimmer")
      expect(html).to include("shadow-sm")
    end
  end
end
