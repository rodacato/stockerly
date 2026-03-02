module Administration
  module Integrations
    class RemovePoolKey < ApplicationUseCase
      def call(admin:, params:)
        pool_key = yield find(params[:id])
        key_name = pool_key.name
        key_id   = pool_key.id
        _        = yield destroy(pool_key)
        _        = yield publish(Administration::PoolKeyRemoved.new(
          pool_key_id: key_id,
          key_name: key_name
        ))

        Success(:removed)
      end

      private

      def find(id)
        pool_key = ApiKeyPool.find_by(id: id)
        pool_key ? Success(pool_key) : Failure([:not_found, "Pool key not found"])
      end

      def destroy(pool_key)
        pool_key.destroy!
        Success(:destroyed)
      end
    end
  end
end
