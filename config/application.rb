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

    # Hexagonal Architecture: contexts/ is a root — subdirs become namespaces
    # e.g. app/contexts/identity/events/user_registered.rb → Identity::Events::UserRegistered
    config.autoload_paths << Rails.root.join("app/contexts")
    config.autoload_paths << Rails.root.join("app/shared")

    # Zeitwerk collapse: organizational folders within contexts being migrated
    # retain collapse temporarily; shared infrastructure always collapsed.
    # Contexts are removed from this list as they adopt explicit submodules.
    COLLAPSED_CONTEXTS = %w[market_data administration].freeze

    initializer "stockerly.zeitwerk_collapse", before: "zeitwerk.eager_load" do
      COLLAPSED_CONTEXTS.each do |ctx|
        base = Rails.root.join("app/contexts/#{ctx}")
        %w[contracts domain events gateways handlers use_cases].each do |layer|
          dir = base.join(layer)
          Rails.autoloaders.main.collapse(dir) if dir.exist?
        end
      end

      # Shared infrastructure: no namespace prefix (CircuitBreaker, EventBus, etc.)
      Rails.autoloaders.main.collapse(
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
