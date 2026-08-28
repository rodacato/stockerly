require "rails_helper"
require "rake"

# D55: `/forgot-password` is the only recovery path the product has, and it
# depends on the mail ADR-018 calls the single most likely thing to be broken
# on a self-hosted box. This is the door that needs no mail — the operator has
# shell access by definition.
RSpec.describe "stockerly:reset_password rake task" do
  before(:all) do
    Rails.application.load_tasks unless Rake::Task.task_defined?("stockerly:reset_password")
  end

  before { Rake::Task["stockerly:reset_password"].reenable }

  let!(:user) { create(:user, email: "owner@example.com", password: "original-password", password_confirmation: "original-password") }

  def invoke(email, tty: true, entries: [ "brand-new-password", "brand-new-password" ])
    stdin = allow($stdin)
    stdin.to receive(:tty?).and_return(tty)
    stdin.to receive(:getpass).and_return(*entries) if entries.any?
    Rake::Task["stockerly:reset_password"].invoke(email)
  end

  it "sets a password the user can authenticate with" do
    expect { invoke("owner@example.com") }.to output(/Password updated for owner@example.com/).to_stdout

    expect(user.reload.authenticate("brand-new-password")).to be_truthy
    expect(user.authenticate("original-password")).to be_falsey
  end

  it "finds the user regardless of case and surrounding space" do
    invoke("  OWNER@example.com  ")

    expect(user.reload.authenticate("brand-new-password")).to be_truthy
  end

  it "says the second factor is untouched, so the operator does not assume it was cleared" do
    user.update!(otp_enrolled_at: Time.current, otp_secret: "S3CR3T")

    expect { invoke("owner@example.com") }.to output(/Two-factor authentication is unchanged/).to_stdout
    expect(user.reload.otp_enrolled?).to be(true)
  end

  it "aborts without touching the password when the two entries differ" do
    expect {
      invoke("owner@example.com", entries: [ "one-password", "another-password" ])
    }.to raise_error(SystemExit)

    expect(user.reload.authenticate("original-password")).to be_truthy
  end

  it "aborts when the password is too short for the model's own rule" do
    expect {
      invoke("owner@example.com", entries: [ "short", "short" ])
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(user.reload.authenticate("original-password")).to be_truthy
  end

  it "aborts on an unknown email rather than creating anything" do
    expect { invoke("nobody@example.com", entries: []) }.to raise_error(SystemExit)
    expect(User.count).to eq(1)
  end

  it "aborts with no email at all" do
    expect { invoke("", entries: []) }.to raise_error(SystemExit)
  end

  # The negative case that matters: without a TTY the prompt would echo the
  # password into the scrollback, so the task refuses instead.
  it "refuses to run without a TTY rather than echoing the password" do
    expect {
      invoke("owner@example.com", tty: false, entries: [])
    }.to raise_error(SystemExit)

    expect(user.reload.authenticate("original-password")).to be_truthy
  end
end
