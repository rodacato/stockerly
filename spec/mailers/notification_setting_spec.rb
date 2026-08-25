require "rails_helper"

# D17's other half: the switch the settings screen wrote and nothing read.
RSpec.describe "email_notifications_enabled", type: :mailer do
  let(:user) { create(:user, email: "adrian@example.com") }
  let(:notification) { create(:notification, user: user, title: "NVDA cruzó 200") }

  def deliver_digest = AlertMailer.daily_digest(user, [ notification ]).deliver_now
  def deliver_urgent = AlertMailer.urgent_alert(user, notification).deliver_now

  describe "when notifications by email are off" do
    before { SiteConfig.set("email_notifications_enabled", false) }

    it "does not send the digest" do
      expect { deliver_digest }.not_to change { ActionMailer::Base.deliveries.size }
    end

    it "does not send an urgent alert" do
      expect { deliver_urgent }.not_to change { ActionMailer::Base.deliveries.size }
    end

    # A single-user instance with no support desk cannot afford a settings
    # switch that locks its owner out of their own account.
    it "still sends a password reset" do
      expect { UserMailer.password_reset(user, "https://example.com/r/abc").deliver_now }
        .to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  describe "when they are on" do
    it "sends the digest" do
      SiteConfig.set("email_notifications_enabled", true)

      expect { deliver_digest }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  it "defaults to on when the setting was never touched" do
    expect(SiteConfig.where(key: "email_notifications_enabled")).to be_empty

    expect { deliver_digest }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
end
