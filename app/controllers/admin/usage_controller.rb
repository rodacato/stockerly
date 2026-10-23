module Admin
  # ADR-032: the usage record's one reader. Opening it is counted, because the
  # record is deleted if this screen goes unread.
  class UsageController < BaseController
    def show
      Usage.opened("/admin/usage")
      @report = Usage::Queries::Report.call
    end
  end
end
