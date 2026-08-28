require "rails_helper"

# The unit specs build the reporter's context by hand. This one does not: it
# breaks a real controller action and checks what Rails actually hands the
# subscriber, which is the part that decides whether a production 500 arrives
# with its route attached or as an anonymous "other".
RSpec.describe "Capturing a real request failure", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current) }

  before do
    login_as(user)
    allow(SiteConfig).to receive(:developer_mode?).and_raise(ArgumentError, "boom from a real action")
  end

  it "records the failure with the request that caused it" do
    expect { get settings_path }.to raise_error(ArgumentError)

    event = ErrorEvent.sole
    expect(event.exception_class).to eq("ArgumentError")
    expect(event.message).to eq("boom from a real action")
    expect(event.source).to eq("request")
    expect(event.request_method).to eq("GET")
    expect(event.request_path).to eq(settings_path)
    expect(event.reference).to be_present
  end

  it "points at the application line that failed, not at framework code" do
    expect { get settings_path }.to raise_error(ArgumentError)

    expect(ErrorEvent.sole.app_line).to include("settings_controller.rb")
  end
end
