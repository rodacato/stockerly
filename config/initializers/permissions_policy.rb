# Be sure to restart your server when you modify this file.

# Define an application-wide permissions policy.
# See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy

Rails.application.config.permissions_policy do |policy|
  policy.camera      :none
  policy.microphone  :none
  policy.geolocation :none
  policy.usb         :none
end
