# Asks the provider what a bare ticker is and adds the ones it recognises.
#
# Off the request because each lookup is a subprocess and the provider caps
# them per minute, so seventeen symbols is minutes rather than seconds. Hitting
# that cap is not a failure: the rest are re-enqueued and the tally rides along
# so the owner gets one notification for the whole batch, not one per pass.
class ResolveTrackedSymbolsJob < ApplicationJob
  queue_as :default

  RETRY_IN = 1.minute

  def perform(pending, user_id, added = [], unresolved = [])
    user = User.find_by(id: user_id)
    return unless user

    remaining = drain(pending.dup, user, added, unresolved)
    return self.class.set(wait: RETRY_IN).perform_later(remaining, user_id, added, unresolved) if remaining.any?

    notify(user, added, unresolved)
  end

  private

  def drain(remaining, user, added, unresolved)
    while (symbol = remaining.shift)
      case resolve(symbol, user)
      when :added then added << symbol
      when :unresolved then unresolved << symbol
      else
        remaining.unshift(symbol)
        break
      end
    end

    remaining
  end

  def resolve(symbol, user)
    result = Administration::UseCases::Assets::SearchTicker.call(query: symbol)
    return :throttled if result.failure? && result.failure.first == :rate_limited
    return :unresolved if result.failure?

    match = result.value!.find { |candidate| candidate[:symbol].to_s.upcase == symbol }
    return :unresolved if match.nil?

    create(match, user) ? :added : :unresolved
  end

  # An exact ticker match is the whole contract: the provider answering with a
  # near miss is what "a dedazo becomes a junk asset that syncs forever" meant.
  def create(match, user)
    params = match.slice(:symbol, :name, :asset_type, :exchange, :sector, :country, :currency).compact
    Administration::UseCases::Assets::CreateAsset.call(admin: user, params: params).success?
  end

  def notify(user, added, unresolved)
    Notifications::UseCases::CreateNotification.call(
      user_id: user.id,
      title: I18n.t("notificaciones.simbolos.titulo", count: added.size),
      body: body_for(added, unresolved),
      notification_type: :system
    )
  end

  # Each sentence is conditional: with nothing added the first one used to
  # render as "Ya están en Tracked: ." -- a list header with no list. The
  # instruction only earns a place when there is something to re-import.
  def body_for(added, unresolved)
    lines = []
    lines << I18n.t("notificaciones.simbolos.agregados", symbols: added.join(", ")) if added.any?
    lines << I18n.t("notificaciones.simbolos.sin_reconocer", symbols: unresolved.join(", ")) if unresolved.any?
    lines << I18n.t("notificaciones.simbolos.reintenta") if added.any?
    lines.join(" ")
  end
end
