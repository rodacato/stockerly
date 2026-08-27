require "rails_helper"

# db/seeds.rb has broken twice on the same shape: a column is dropped, the seed
# keeps assigning it, and nothing notices because CI never runs db:seed and the
# demo block is guarded by Rails.env.development?. First time it was
# sms_notifications (CODE_CHANGES §6), then buying_power.
#
# This runs the real file, so the next dropped column fails here instead of on
# somebody's first boot.
RSpec.describe "db/seeds.rb" do
  it "runs against the current schema" do
    # The seed ends by invoking stockerly:sync, which `rails db:seed` has loaded
    # for it and a spec does not.
    Rails.application.load_tasks unless Rake::Task.task_defined?("stockerly:sync")
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

    expect { load Rails.root.join("db/seeds.rb") }.not_to raise_error
  end
end
