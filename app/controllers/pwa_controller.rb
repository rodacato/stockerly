# Two static documents the browser fetches outside any session, so this one
# skips the app's authentication, setup and maintenance filters entirely.
class PwaController < ActionController::Base
  # Not the CSRF token check — that one passes GET through untouched and stays
  # on. This is the sibling guard that refuses any non-XHR text/javascript
  # response, and the worker is a static document with nothing of the reader
  # in it, so there is no session data for a cross-origin script tag to read.
  skip_after_action :verify_same_origin_request, only: :service_worker

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
