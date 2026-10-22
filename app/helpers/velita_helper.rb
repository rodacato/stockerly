module VelitaHelper
  # She appears only while the connection answers and the owner switched her
  # on (D167); off, the app is exactly what it was before the assistant.
  def velita_visible?
    return @velita_visible if defined?(@velita_visible)

    connection = Administration::Queries::AssistantConnection.call
    @velita_visible = connection.present? && connection[:status] == :connected && connection[:show_velita]
  end

  def velita_screen = main_nav_items.find { |item| item[:active] }&.dig(:key)

  # Drawn per screen (D166) and kept to questions the selector can answer:
  # each one retrieves at least one card, or it would open on a blank answer.
  def assistant_suggestions(from:, symbol:)
    if symbol
      [ t("assistant.questions.new.sugerencias.activo.rsi", symbol: symbol),
        t("assistant.questions.new.sugerencias.activo.rango"),
        t("assistant.questions.new.sugerencias.activo.titulares", symbol: symbol) ]
    elsif from == "panorama"
      [ t("assistant.questions.new.sugerencias.panorama.vs_cetes"),
        t("assistant.questions.new.sugerencias.panorama.cetes"),
        t("assistant.questions.new.sugerencias.panorama.resultados") ]
    else
      []
    end
  end

  # Asked from a ? popover: the drawer opens with the term already written.
  def velita_question_path(term)
    assistant_path(from: velita_screen, q: term)
  end
end
