require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#admin_nav_active?" do
    it "returns active classes when on the current page" do
      allow(helper).to receive(:current_page?).and_return(true)
      result = helper.admin_nav_active?("/admin/assets")
      expect(result).to include("bg-primary")
      expect(result).to include("text-white")
    end

    it "returns inactive classes when not on the current page" do
      allow(helper).to receive(:current_page?).and_return(false)
      result = helper.admin_nav_active?("/admin/assets")
      expect(result).to include("text-slate-600")
      expect(result).not_to include("bg-primary")
    end
  end

  describe "#app_nav_active?" do
    it "returns active classes when on the current page" do
      allow(helper).to receive(:current_page?).and_return(true)
      result = helper.app_nav_active?("/dashboard")
      expect(result).to include("text-primary")
      expect(result).to include("bg-primary/10")
    end

    it "returns inactive classes when not on the current page" do
      allow(helper).to receive(:current_page?).and_return(false)
      result = helper.app_nav_active?("/dashboard")
      expect(result).to include("text-slate-600")
      expect(result).not_to include("bg-primary/10")
    end
  end
end
