require "rails_helper"

RSpec.describe Administration::Handlers::RecordUnhandledError do
  def raised(message = "boom")
    raise ArgumentError, message
  rescue ArgumentError => error
    error
  end

  describe "what it records" do
    it "ignores an error the application already handled" do
      expect {
        described_class.report(raised, handled: true, context: {})
      }.not_to change(ErrorEvent, :count)
    end

    it "records an unhandled error with no context as coming from nowhere in particular" do
      described_class.report(raised, handled: false, context: {})

      expect(ErrorEvent.sole.source).to eq("other")
    end
  end

  describe "a failure inside a request" do
    let(:request) do
      ActionDispatch::TestRequest.create(
        "PATH_INFO" => "/portfolio",
        "REQUEST_METHOD" => "POST",
        "action_dispatch.request_id" => "req-abc"
      )
    end
    let(:controller) { Struct.new(:request).new(request) }

    it "keeps the verb, the path and the request id" do
      described_class.report(raised, handled: false, context: { controller: controller })

      event = ErrorEvent.sole
      expect(event.source).to eq("request")
      expect(event.request_method).to eq("POST")
      expect(event.request_path).to eq("/portfolio")
      expect(event.reference).to eq("req-abc")
    end
  end

  describe "a failure inside a job" do
    it "keeps the job class and its job id" do
      job = CheckSyncHealthJob.new

      described_class.report(raised, handled: false, context: { job: job })

      event = ErrorEvent.sole
      expect(event.source).to eq("job")
      expect(event.job_class).to eq("CheckSyncHealthJob")
      expect(event.reference).to eq(job.job_id)
    end
  end

  describe "when the reporter itself cannot do its work" do
    it "gives up silently instead of raising a second error" do
      not_an_exception = Object.new

      expect {
        described_class.report(not_an_exception, handled: false, context: {})
      }.not_to raise_error
    end

    it "records nothing in that case" do
      expect {
        described_class.report(Object.new, handled: false, context: {})
      }.not_to change(ErrorEvent, :count)
    end
  end

  describe "the live subscription" do
    it "reaches the database through Rails.error, not only through a direct call" do
      expect {
        Rails.error.report(raised("through the reporter"), handled: false)
      }.to change(ErrorEvent, :count).by(1)

      expect(ErrorEvent.sole.message).to eq("through the reporter")
    end
  end
end
