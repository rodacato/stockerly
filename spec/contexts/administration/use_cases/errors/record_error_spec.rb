require "rails_helper"

RSpec.describe Administration::UseCases::Errors::RecordError do
  include ActiveSupport::Testing::TimeHelpers

  def raised(klass = ArgumentError, message = "boom")
    raise klass, message
  rescue klass => error
    error
  end

  describe "the first occurrence" do
    it "stores the class, the message and the failing line" do
      event = described_class.call(error: raised, source: "request")

      expect(event.exception_class).to eq("ArgumentError")
      expect(event.message).to eq("boom")
      expect(event.app_line).to include("record_error_spec.rb")
      expect(event.occurrences).to eq(1)
    end

    it "truncates a message that would not fit" do
      event = described_class.call(error: raised(ArgumentError, "x" * 5_000))

      expect(event.message.length).to eq(described_class::MESSAGE_LIMIT)
    end
  end

  describe "a repeat of the same failure" do
    it "counts the occurrence instead of adding a row" do
      described_class.call(error: raised)

      expect { described_class.call(error: raised) }.not_to change(ErrorEvent, :count)
      expect(ErrorEvent.sole.occurrences).to eq(2)
    end

    it "keeps the newest request context, which is the one worth having" do
      described_class.call(error: raised, context: { request_path: "/first" })
      described_class.call(error: raised, context: { request_path: "/second" })

      expect(ErrorEvent.sole.request_path).to eq("/second")
    end

    it "moves last_seen_at forward and leaves first_seen_at alone" do
      first = described_class.call(error: raised)
      original_first_seen = first.first_seen_at

      travel_to(1.hour.from_now) { described_class.call(error: raised) }
      first.reload

      expect(first.first_seen_at).to be_within(1.second).of(original_first_seen)
      expect(first.last_seen_at).to be > original_first_seen
    end
  end

  describe "a different failure" do
    it "gets its own row" do
      described_class.call(error: raised(ArgumentError))
      described_class.call(error: raised(TypeError))

      expect(ErrorEvent.count).to eq(2)
    end
  end

  describe "request parameters" do
    it "stores a password as filtered, never as typed" do
      params = { "user" => { "email" => "me@example.com", "password" => "hunter2" } }

      event = described_class.call(error: raised, context: { request_params: params })

      expect(event.request_params.to_json).not_to include("hunter2")
      expect(event.request_params.dig("user", "password")).to eq("[FILTERED]")
    end

    it "filters the email too, since the filter list covers it" do
      event = described_class.call(error: raised, context: { request_params: { "email" => "me@example.com" } })

      expect(event.request_params["email"]).to eq("[FILTERED]")
    end

    it "records the error anyway when a param is not a plain JSON value" do
      event = described_class.call(error: raised, context: { request_params: { "file" => Object.new } })

      expect(event).to be_persisted
      expect(event.exception_class).to eq("ArgumentError")
    end
  end
end
