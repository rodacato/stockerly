module VelitaHelper
  # She appears only while the connection answers and the owner switched her
  # on (D167); off, the app is exactly what it was before the assistant.
  def velita_visible?
    return @velita_visible if defined?(@velita_visible)

    connection = Administration::Queries::AssistantConnection.call
    @velita_visible = connection.present? && connection[:status] == :connected && connection[:show_velita]
  end

  # A page that answers its own question gets its own key; the rest go by their tab.
  PAGES = { "signals" => "senales", "portfolios" => "consolidado" }.freeze

  def velita_screen = PAGES[controller_path] || main_nav_items.find { |item| item[:active] }&.dig(:key)

  def assistant_screen_label(key) = t("assistant.pantallas.#{key}", default: :"nav.#{key}")

  # The figures Hoy's ? popovers explained on this page, so the drawer only
  # suggests what the screen is actually showing.
  def velita_seen_terms = content_for(:assistant_terms).to_s.split.uniq.join(",")

  # Drawn per screen (D166) and kept to questions the selector can answer:
  # each one retrieves at least one card, or it would open on a blank answer.
  def assistant_suggestions(from:, symbol:, seen: [])
    if symbol
      [ t("assistant.questions.new.sugerencias.activo.rsi", symbol: symbol),
        t("assistant.questions.new.sugerencias.activo.rango"),
        t("assistant.questions.new.sugerencias.activo.titulares", symbol: symbol) ]
    elsif from == "panorama"
      by_figure = {
        "vs_cetes" => [ t("assistant.questions.new.sugerencias.panorama.vs_cetes"), t("assistant.questions.new.sugerencias.panorama.cetes") ],
        "earnings" => [ t("assistant.questions.new.sugerencias.panorama.resultados") ]
      }
      by_figure.select { |figure, _| seen.include?(figure) }.values.flatten
    elsif from == "senales"
      [ t("assistant.questions.new.sugerencias.senales.semana") ]
    else
      []
    end
  end

  # Today's questions say only the hour; older ones, the day too.
  def assistant_asked_at(time)
    time.to_date == Date.current ? l(time, format: "%H:%M") : l(time, format: "%-d %b · %H:%M")
  end

  # The prose with each [n] turned into a link to the card it cites; a number
  # with no card stays plain text.
  def assistant_answer_with_citations(message)
    cards = message.cards.size
    parts = message.answer.to_s.split(/(\[\d+\])/).map do |part|
      number = part[/\A\[(\d+)\]\z/, 1]&.to_i
      next part unless number&.between?(1, cards)

      link_to(part, "#assistant_card_#{message.id}_#{number}",
              data: { action: "assistant-sources#reveal" }, class: "font-mono text-sm text-primary-fg hover:underline",
              aria: { label: t("assistant.cita", number: number, title: message.cards[number - 1]["title"]) })
    end
    safe_join(parts)
  end

  # Asked from a ? popover: the drawer opens with the term already written.
  def velita_question_path(term)
    assistant_path(from: velita_screen, q: term)
  end
end
