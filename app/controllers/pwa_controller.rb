# Two static documents the browser fetches outside any session, so this one
# skips the app's authentication, setup and maintenance filters entirely.
class PwaController < ActionController::Base
  skip_forgery_protection
  before_action :revalidate_every_load

  def manifest
    render formats: :json, content_type: "application/manifest+json", layout: false
  end

  def service_worker
    render formats: :js, content_type: "text/javascript", layout: false
  end

  private

  # These two used to live in `public/`, whose far-future max-age stranded an
  # installed app on the service worker it happened to be deployed with.
  def revalidate_every_load
    response.headers["cache-control"] = "public, max-age=0, must-revalidate"
  end
end
