require "rails_helper"

RSpec.describe Notifications::Handlers::SendUrgentEmail do
  let(:user) { create(:user) }

  def fire(notification)
    described_class.call(notification_id: notification.id, user_id: user.id, title: notification.title)
  end

  describe ".async?" do
    it { expect(described_class.async?).to be true }
  end

  it "emails the user who asked to be interrupted when a rule fires" do
    create(:alert_preference, user: user, urgent_email: true)
    notification = create(:notification, user: user, notification_type: :alert_triggered,
                                         title: "AAPL cruzó USD 200.00 al alza")

    expect { fire(notification) }.to have_enqueued_mail(AlertMailer, :urgent_alert)
  end

  it "stays quiet for the user who did not ask" do
    create(:alert_preference, user: user, urgent_email: false)
    notification = create(:notification, user: user, notification_type: :alert_triggered)

    expect { fire(notification) }.not_to have_enqueued_mail(AlertMailer, :urgent_alert)
  end

  it "does not interrupt for notices that carry a date rather than an urgency" do
    create(:alert_preference, user: user, urgent_email: true)

    %i[earnings_reminder maturity_reminder system].each do |type|
      notification = create(:notification, user: user, notification_type: type)

      expect { fire(notification) }.not_to have_enqueued_mail(AlertMailer, :urgent_alert)
    end
  end

  it "survives a notification that no longer exists" do
    create(:alert_preference, user: user, urgent_email: true)
    notification = create(:notification, user: user, notification_type: :alert_triggered)
    id = notification.id
    notification.destroy!

    expect {
      described_class.call(notification_id: id, user_id: user.id, title: "gone")
    }.not_to raise_error
  end

  it "survives a user who never got preferences" do
    notification = create(:notification, user: user, notification_type: :alert_triggered)

    expect { fire(notification) }.not_to have_enqueued_mail(AlertMailer, :urgent_alert)
  end
end
