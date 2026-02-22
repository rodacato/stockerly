require "webmock/rspec"

# Disable all real HTTP connections in tests.
# Allow localhost for Capybara system tests.
WebMock.disable_net_connect!(allow_localhost: true)
