# Ensure the first-boot setup redirect doesn't fire in most specs.
# When the DB is clean (no users), ApplicationController redirects to /setup.
# We create a sentinel user so the redirect is skipped, unless a spec
# explicitly opts out with `setup_bypass: false` metadata.
RSpec.configure do |config|
  %i[request system controller].each do |spec_type|
    config.before(:each, type: spec_type) do |example|
      next if example.metadata[:setup_bypass] == false

      User.find_or_create_by!(email: "setup-bypass@test.local") do |u|
        u.full_name = "Setup Bypass"
        u.password = "password123"
        u.password_confirmation = "password123"
        u.onboarded_at = Time.current
      end
    end
  end
end
