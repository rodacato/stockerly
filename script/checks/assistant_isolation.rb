# frozen_string_literal: true

require_relative "support"

module Checks
  # ADR-031 §4: deleting app/contexts/assistant must leave the product whole.
  class AssistantIsolation < Check
    ID = "assistant-isolation"
    TITLE = "ADR-031: the assistant is reached only through its doors and reads no foreign model"

    SCANNED = [ "app/**/*.{rb,erb,rake}", "lib/**/*.{rb,rake}", "config/**/*.rb" ].freeze

    # Without FNM_PATHNAME a `*` crosses directories, which is what `**` means here.
    DOORS = [
      "app/contexts/assistant/**",
      "app/controllers/settings/assistants_controller.rb",
      "app/controllers/assistant/**",
      "app/jobs/assistant*",
      "app/views/settings/assistants/**",
      "app/views/assistant/**",
      "config/routes.rb",
      "spec/**"
    ].freeze

    NAMESPACE = /(?<![A-Za-z0-9_:.])Assistant::/

    def run
      outside_references + foreign_models
    end

    private

    def outside_references
      paths = Checks.files(*SCANNED).reject { |path| door?(path) }
      scan(paths) do |line|
        "references Assistant:: outside the assistant's doors — ADR-031 keeps the context deletable" if line.match?(NAMESPACE)
      end
    end

    def foreign_models
      pattern = /(?<![A-Za-z0-9_:.])(#{foreign_model_names.join('|')})\b/
      scan(Checks.files("app/contexts/assistant/**/*.rb")) do |line|
        match = line[pattern, 1]
        match && "reads #{match}, an ActiveRecord model outside the assistant — go through its context's Queries::/UseCases:: API"
      end
    end

    def foreign_model_names
      Checks.files("app/models/*.rb")
        .map { |path| File.basename(path, ".rb").split("_").map(&:capitalize).join }
        .reject { |constant| constant.start_with?("Assistant") }
    end

    def door?(path)
      DOORS.any? { |glob| File.fnmatch?(glob, path) }
    end
  end
end
