require "rails_helper"

RSpec.describe Identity::UseCases::SendBugReport do
  let(:user) { create(:user) }
  let(:valid_params) { { title: "Algo se rompió", description: "Cuando hago X pasa Y pero esperaba Z." } }

  describe ".call" do
    it "validates params and enqueues a bug report email" do
      expect {
        result = described_class.call(user: user, params: valid_params)
        expect(result).to be_success
      }.to have_enqueued_mail(BugReportMailer, :notify)
    end

    it "returns Failure for missing title" do
      result = described_class.call(user: user, params: valid_params.merge(title: ""))
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for short description" do
      result = described_class.call(user: user, params: valid_params.merge(description: "no"))
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "does not send mail when validation fails" do
      expect {
        described_class.call(user: user, params: valid_params.merge(title: ""))
      }.not_to have_enqueued_mail(BugReportMailer, :notify)
    end
  end
end
