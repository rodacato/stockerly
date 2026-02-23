class PagesController < ApplicationController
  layout "public"

  before_action { expires_in 1.hour, public: true }

  def landing; end

  def open_source; end
end
