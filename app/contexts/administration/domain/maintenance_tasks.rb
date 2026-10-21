module Administration
  module Domain
    # Clean-ups the owner can run from the panel; each is idempotent, so running it twice is safe.
    module MaintenanceTasks
      Task = Data.define(:key, :job_class, :icon) do
        def log_name = job_class::TASK
      end

      ALL = [
        Task.new(key: "bmv_symbols", job_class: ResolveBmvSymbolsJob, icon: "swap_horiz"),
        Task.new(key: "price_histories", job_class: BackfillMissingHistoriesJob, icon: "history"),
        Task.new(key: "catalogue", job_class: SeedCatalogJob, icon: "inventory_2")
      ].freeze

      def self.find(key)
        ALL.find { |task| task.key == key.to_s } || raise(KeyError, "unknown maintenance task: #{key}")
      end
    end
  end
end
