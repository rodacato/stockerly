class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, { alert_triggered: 0, earnings_reminder: 1, system: 2, maturity_reminder: 3 }

  # `reglas-bandeja` filters by what the notice is about, not by whether the
  # app or a rule produced it. The enum already drew that line; the inbox
  # collapsed three of its four values into one "alertas" bucket and threw the
  # distinction away.
  TIPO_SCOPES = {
    "alertas"  => %w[alert_triggered],
    "reportes" => %w[earnings_reminder],
    "cetes"    => %w[maturity_reminder]
  }.freeze

  # Kept: AlertsHelper and the mailer still ask "is this a rule firing or the
  # instance talking?", which is a different question from the inbox filter.
  ALERTA_TYPES  = %w[alert_triggered earnings_reminder maturity_reminder].freeze
  SISTEMA_TYPES = %w[system].freeze

  validates :title, presence: true

  scope :unread,  -> { where(read: false) }
  scope :read_only, -> { where(read: true) }
  scope :recent,  -> { order(created_at: :desc) }

  scope :by_tipo, ->(tipo) {
    types = TIPO_SCOPES[tipo.to_s]
    types ? where(notification_type: types) : all
  }

  scope :by_estado, ->(estado) {
    case estado.to_s
    when "no_leidas" then unread
    when "leidas"    then read_only
    else all
    end
  }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end

  # Binary grouping used by the inbox UI: alerts (user-relevant triggers) vs
  # system (platform-wide notices). Reminder types live under "alertas"
  # because they fire on user-held assets.
  def kind
    Notification::ALERTA_TYPES.include?(notification_type) ? "alerta" : "sistema"
  end
end
