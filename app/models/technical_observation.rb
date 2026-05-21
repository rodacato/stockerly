class TechnicalObservation < ApplicationRecord
  belongs_to :asset

  # Closed set of detectable transitions (#40 JTBD #6). Adding a new type
  # requires both the detector logic and a phrasing entry in the partial.
  TYPES = %w[
    rsi_oversold_entered
    rsi_overbought_entered
    rsi_oversold_exited
    rsi_overbought_exited
    ma200_crossed_above
    ma200_crossed_below
    ma50_crossed_above
    ma50_crossed_below
    bb_upper_breached
    bb_lower_breached
  ].freeze

  validates :observation_type, presence: true, inclusion: { in: TYPES }
  validates :observed_at, presence: true

  scope :recent, -> { order(observed_at: :desc) }
  scope :within_last, ->(days) { where(observed_at: days.days.ago..) }
  scope :for_assets, ->(asset_ids) { where(asset_id: asset_ids) }

  # Descriptive label per ADR-001 — purely observational, no action verbs.
  # The asset symbol is rendered by the caller so this stays asset-agnostic.
  # Copy is es-MX (Adrian's UI language). The English keys stay as the
  # canonical persisted observation_type — only the user-facing phrase is es-MX.
  PHRASES = {
    "rsi_oversold_entered"   => "entró en zona de sobreventa (RSI(14) por debajo de 30)",
    "rsi_overbought_entered" => "entró en zona de sobrecompra (RSI(14) por encima de 70)",
    "rsi_oversold_exited"    => "salió de la zona de sobreventa",
    "rsi_overbought_exited"  => "salió de la zona de sobrecompra",
    "ma200_crossed_above"    => "cruzó al alza su MA200",
    "ma200_crossed_below"    => "cruzó a la baja su MA200",
    "ma50_crossed_above"     => "cruzó al alza su MA50",
    "ma50_crossed_below"     => "cruzó a la baja su MA50",
    "bb_upper_breached"      => "rompió la banda de Bollinger superior",
    "bb_lower_breached"      => "rompió la banda de Bollinger inferior"
  }.freeze

  # Short uppercase tag rendered next to the phrase in the asset detail
  # "Observaciones recientes" panel (S10 #93).
  TAGS = {
    "rsi_oversold_entered"   => "RSI",
    "rsi_overbought_entered" => "RSI",
    "rsi_oversold_exited"    => "RSI",
    "rsi_overbought_exited"  => "RSI",
    "ma200_crossed_above"    => "MEDIA MÓVIL",
    "ma200_crossed_below"    => "MEDIA MÓVIL",
    "ma50_crossed_above"     => "MEDIA MÓVIL",
    "ma50_crossed_below"     => "MEDIA MÓVIL",
    "bb_upper_breached"      => "BANDAS",
    "bb_lower_breached"      => "BANDAS"
  }.freeze

  # Visual accent ("pos" green, "warn" amber, neutral primary) for the
  # observation dot. Choice mirrors the Stockerly-2.0 mockup intent:
  # bullish-leaning signals → pos; bearish/extreme → warn; rest → neutral.
  ACCENTS = {
    "rsi_oversold_entered"   => "warn",
    "rsi_overbought_entered" => "warn",
    "rsi_oversold_exited"    => "pos",
    "rsi_overbought_exited"  => "neutral",
    "ma200_crossed_above"    => "pos",
    "ma200_crossed_below"    => "warn",
    "ma50_crossed_above"     => "pos",
    "ma50_crossed_below"     => "warn",
    "bb_upper_breached"      => "warn",
    "bb_lower_breached"      => "warn"
  }.freeze

  def phrase
    PHRASES.fetch(observation_type, observation_type.humanize)
  end

  def tag
    TAGS.fetch(observation_type, "SEÑAL")
  end

  def accent
    ACCENTS.fetch(observation_type, "neutral")
  end
end
