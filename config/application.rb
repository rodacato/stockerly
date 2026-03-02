require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Stockerly
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Hexagonal Architecture: each bounded context is a root namespace
    config.autoload_paths += Dir[Rails.root.join("app/contexts/*")]
    config.autoload_paths << Rails.root.join("app/shared")

    # Zeitwerk collapse: folders organize for humans, Ruby sees flat namespaces
    # e.g. app/contexts/alerts/domain/alert_evaluator.rb → Alerts::AlertEvaluator
    initializer "stockerly.zeitwerk_collapse", before: "zeitwerk.eager_load" do
      Rails.autoloaders.main.collapse(
        *Dir[Rails.root.join("app/contexts/*/contracts")],
        *Dir[Rails.root.join("app/contexts/*/domain")],
        *Dir[Rails.root.join("app/contexts/*/events")],
        *Dir[Rails.root.join("app/contexts/*/handlers")],
        *Dir[Rails.root.join("app/contexts/*/gateways")],
        *Dir[Rails.root.join("app/contexts/*/use_cases")],
        Rails.root.join("app/shared/base"),
        Rails.root.join("app/shared/domain"),
        Rails.root.join("app/shared/events"),
        Rails.root.join("app/shared/types")
      )
    end

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
