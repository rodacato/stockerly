module Administration
  module Integrations
    class TogglePoolKey < ApplicationUseCase
      def call(admin:, params:)
        pool_key = yield find(params[:id])
        _        = yield toggle(pool_key)
        _        = yield publish(Administration::PoolKeyToggled.new(
          pool_key_id: pool_key.id,
          key_name: pool_key.name,
          enabled: pool_key.enabled
        ))

        Success(pool_key)
      end

      private

      def find(id)
        pool_key = ApiKeyPool.find_by(id: id)
        pool_key ? Success(pool_key) : Failure([:not_found, "Pool key not found"])
      end

      def toggle(pool_key)
        pool_key.update!(enabled: !pool_key.enabled)
        Success(:toggled)
      end
    end
  end
end
