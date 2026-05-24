require "rails_helper"

RSpec.describe EmailEvent, type: :model do
  describe "validations" do
    subject { build(:email_event) }

    it { is_expected.to be_valid }

    it "requires an email" do
      subject.email = nil
      expect(subject).not_to be_valid
    end

    it "requires an event_type" do
      subject.event_type = nil
      expect(subject).not_to be_valid
    end

    it "requires occurred_at" do
      subject.occurred_at = nil
      expect(subject).not_to be_valid
    end

    it "rejects unknown event_type values" do
      subject.event_type = "unsubscribed"
      expect(subject).not_to be_valid
    end

    %w[sent delivered bounced complained opened clicked].each do |type|
      it "accepts #{type} as event_type" do
        subject.event_type = type
        expect(subject).to be_valid
      end
    end
  end

  describe "email normalization" do
    it "downcases on validation" do
      record = build(:email_event, email: "Amigo@Example.COM")
      record.valid?
      expect(record.email).to eq("amigo@example.com")
    end

    it "strips surrounding whitespace" do
      record = build(:email_event, email: "  amigo@example.com  ")
      record.valid?
      expect(record.email).to eq("amigo@example.com")
    end
  end

  describe "scopes" do
    describe ".for_email" do
      it "filters by email" do
        match = create(:email_event, email: "alice@example.com")
        _other = create(:email_event, email: "bob@example.com")
        expect(EmailEvent.for_email("alice@example.com")).to contain_exactly(match)
      end

      it "is case-insensitive" do
        match = create(:email_event, email: "alice@example.com")
        expect(EmailEvent.for_email("ALICE@example.com")).to contain_exactly(match)
      end
    end

    describe ".for_message" do
      it "filters by message_id" do
        match = create(:email_event, message_id: "msg_abc")
        _other = create(:email_event, message_id: "msg_xyz")
        expect(EmailEvent.for_message("msg_abc")).to contain_exactly(match)
      end
    end

    describe ".by_type" do
      it "filters by event_type" do
        delivered = create(:email_event, :delivered, message_id: "msg_d")
        _bounced  = create(:email_event, :bounced,   message_id: "msg_b")
        expect(EmailEvent.by_type("delivered")).to contain_exactly(delivered)
      end
    end

    describe ".recent" do
      it "orders by occurred_at descending" do
        older = create(:email_event, occurred_at: 2.days.ago, message_id: "msg_old")
        newer = create(:email_event, occurred_at: 1.hour.ago, message_id: "msg_new")
        expect(EmailEvent.recent).to eq([ newer, older ])
      end
    end
  end
end
