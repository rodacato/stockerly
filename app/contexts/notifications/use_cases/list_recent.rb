module Notifications
  module UseCases
    # Inbox query for /notifications. Returns the filtered relation, counts
    # used by the filter chip badges (always reflect the full unfiltered
    # dataset), and a shown/total pair for the "Mostrando X de Y" indicator.
    class ListRecent < SimpleUseCase
      DEFAULT_LIMIT = 100

      # Notifiable polymorphic types that own a `:asset` association the
      # inbox row uses to render the asset link. AlertRule is excluded — it
      # carries `asset_symbol` directly, no association to preload.
      ASSET_OWNING_NOTIFIABLES = [ EarningsEvent, Position ].freeze

      def call(user:, tipo: "todos", estado: "todos", limit: DEFAULT_LIMIT)
        scope    = user.notifications
        filtered = scope.by_tipo(tipo).by_estado(estado).recent.limit(limit).to_a

        preload_notifiables_and_assets(filtered)

        {
          notifications: filtered,
          tipo:          tipo,
          estado:        estado,
          shown_count:   filtered.size,
          counts:        counts_for(scope)
        }
      end

      private

      # Two-step polymorphic preload: first load each notification's
      # `notifiable`, then preload `:asset` on the children that have one.
      # Replaces the per-row Asset.find_by + n.notifiable.asset hits the
      # inbox row would otherwise trigger.
      def preload_notifiables_and_assets(notifications)
        return if notifications.empty?

        ActiveRecord::Associations::Preloader.new(
          records: notifications,
          associations: :notifiable
        ).call

        ASSET_OWNING_NOTIFIABLES.each do |klass|
          group = notifications.map(&:notifiable).select { |n| n.is_a?(klass) }
          next if group.empty?

          ActiveRecord::Associations::Preloader.new(
            records: group,
            associations: :asset
          ).call
        end
      end

      def counts_for(scope)
        by_type = scope.group(:notification_type).count
        alerts  = Notification::ALERTA_TYPES.sum  { |t| by_type[t] || 0 }
        system  = Notification::SISTEMA_TYPES.sum { |t| by_type[t] || 0 }
        all     = alerts + system
        unread  = scope.unread.count

        {
          all:    all,
          alerts: alerts,
          system: system,
          unread: unread,
          read:   all - unread
        }
      end
    end
  end
end
