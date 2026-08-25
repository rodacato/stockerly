Rails.application.config.session_store :cookie_store,
  key: "_stockerly_session",
  # A day past ApplicationController::ABSOLUTE_TIMEOUT, so that check fires and
  # says why instead of the cookie vanishing first and dropping you at /login.
  expire_after: 31.days
