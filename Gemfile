source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# CSV generation (default gem until Ruby 3.4)
gem "csv"

# DDD / Domain modeling [https://dry-rb.org/]
gem "dry-types", "~> 1.7"
gem "dry-struct", "~> 1.6"
gem "dry-validation", "~> 1.10"
gem "dry-monads", "~> 1.6"

# Pagination [https://github.com/ddnexus/pagy]
gem "pagy", "~> 9.0"

# Currency formatting and conversion [https://github.com/RubyMoney/money-rails]
gem "money-rails", "~> 1.15"

# HTTP client for external API gateways [https://github.com/lostisland/faraday]
gem "faraday", "~> 2.9"
gem "faraday-retry"

# Structured JSON logging for production [https://github.com/roidrage/lograge]
gem "lograge"

# Error tracking and application monitoring [https://www.honeybadger.io]
gem "honeybadger"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "mission_control-jobs"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Load environment variables from .env files [https://github.com/bkeepers/dotenv]
  gem "dotenv-rails"

  # Testing framework [https://rspec.info/]
  gem "rspec-rails"
  gem "factory_bot_rails"

  # System tests [https://github.com/teamcapybara/capybara]
  gem "capybara"

  # Code coverage [https://github.com/simplecov-ruby/simplecov]
  gem "simplecov", require: false

  # Stub HTTP requests in tests [https://github.com/bblimke/webmock]
  gem "webmock"

  # N+1 query detection [https://github.com/flyerhzm/bullet]
  gem "bullet"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
