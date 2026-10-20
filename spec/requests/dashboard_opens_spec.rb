require "rails_helper"

RSpec.describe "Dashboard opens", type: :request do
  def opens_today
    AppOpen.where(path: "/dashboard", day: Time.zone.today).sum(:count)
  end

  context "when logged in" do
    before { login_as(create(:user, password: "password123")) }

    it "counts every full HTML load of the cockpit" do
      2.times { get dashboard_path }

      expect(opens_today).to eq(2)
    end

    it "does not count a turbo-frame request" do
      get dashboard_path, headers: { "Turbo-Frame" => "panel" }

      expect(opens_today).to eq(0)
    end

    it "does not count a prefetch" do
      get dashboard_path, headers: { "X-Sec-Purpose" => "prefetch" }

      expect(opens_today).to eq(0)
    end
  end

  it "does not count a logged-out visit" do
    get dashboard_path

    expect(opens_today).to eq(0)
  end
end
