require "rails_helper"

RSpec.describe Notifications::UseCases::SendDailyDigest do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  def send_digests
    perform_enqueued_jobs { described_class.call }
  end

  def notify(created_at: Time.current, title: "AAPL cruzó USD 200.00 al alza")
    create(:notification, user: user, title: title, created_at: created_at)
  end

  it "sends one digest carrying the day's notifications" do
    create(:alert_preference, user: user, email_digest: true)
    notify(title: "AAPL cruzó USD 200.00 al alza")
    notify(title: "Tus CETES 28d vencen en 3 días")

    expect { send_digests }.to change { ActionMailer::Base.deliveries.size }.by(1)

    email = ActionMailer::Base.deliveries.last
    expect(email.to).to eq([ user.email ])
    expect(email.subject).to eq("Tu resumen de hoy · 2 avisos")

    [ email.text_part, email.html_part ].each do |part|
      expect(part.decoded).to include("AAPL cruzó USD 200.00 al alza")
      expect(part.decoded).to include("Tus CETES 28d vencen en 3 días")
    end
  end

  it "says one aviso in singular" do
    create(:alert_preference, user: user, email_digest: true)
    notify

    send_digests

    expect(ActionMailer::Base.deliveries.last.subject).to eq("Tu resumen de hoy · 1 aviso")
  end

  it "sends nothing when the user has nothing to report" do
    create(:alert_preference, user: user, email_digest: true)

    expect { send_digests }.not_to(change { ActionMailer::Base.deliveries.size })
  end

  it "skips notifications older than the window" do
    create(:alert_preference, user: user, email_digest: true)
    notify(created_at: 3.days.ago)

    expect { send_digests }.not_to(change { ActionMailer::Base.deliveries.size })
  end

  it "leaves alone the user who turned the digest off" do
    create(:alert_preference, user: user, email_digest: false)
    notify

    expect { send_digests }.not_to(change { ActionMailer::Base.deliveries.size })
  end

  it "returns how many digests it sent" do
    create(:alert_preference, user: user, email_digest: true)
    notify

    expect(described_class.call).to eq(1)
  end
end
