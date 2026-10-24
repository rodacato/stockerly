module VelitaHelper
  # She appears only while the connection answers and the owner switched her
  # on (D167); off, the app is exactly what it was before the assistant.
  def velita_visible?
    return @velita_visible if defined?(@velita_visible)

    connection = velita_connection
    @velita_visible = connection.present? && connection[:status] == :connected && connection[:show_velita]
  end

  def velita_connection
    return @velita_connection if defined?(@velita_connection)

    @velita_connection = Administration::Queries::AssistantConnection.call
  end

  # D173: a light body takes dark eyes, or the expression does not read on it.
  DARK_EYES = "fill-fg-default dark:fill-fg-inverse".freeze
  VELITA_PAINT = {
    "indigo" => [ "text-chart-1", "fill-fg-inverse" ],
    "cielo" => [ "text-chart-2", DARK_EYES ],
    "violeta" => [ "text-chart-6", "fill-fg-inverse" ],
    "naranja" => [ "text-chart-7", DARK_EYES ],
    "cian" => [ "text-chart-8", DARK_EYES ]
  }.freeze

  # Without a connection she is "Sin conexión", whatever colour was picked.
  def velita_paint(state, colour = nil)
    return [ "text-fg-subtle", "fill-fg-inverse" ] if state == :offline

    VELITA_PAINT.fetch(colour || velita_connection&.dig(:velita_colour), VELITA_PAINT["indigo"])
  end

  # The figure beside an answer says what the pipeline is doing (ADR-031 §7).
  def velita_state(message)
    if message.pending? then :searching
    elsif message.streaming? then message.answer.present? ? :speaking : :citing
    elsif message.discarded? then :no_data
    elsif message.failed? then :offline
    else :idle
    end
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

  ANSWER_LIST_ITEM = /\A\s*(?:[-*•]|\d+[.)])\s+/
  ANSWER_INLINE = /(\*\*[^*\n]+\*\*|\[\d+\])/

  # Models write Markdown whatever the prompt says: render paragraphs, lists and bold, drop the rest.
  def assistant_answer_html(message)
    blocks = message.answer.to_s.lines.map(&:strip)
                    .chunk { |line| line.empty? ? :_separator : line.match?(ANSWER_LIST_ITEM) }
    safe_join(blocks.map do |listed, lines|
      if listed
        tag.ul(safe_join(lines.map { |line| tag.li(assistant_inline(line.sub(ANSWER_LIST_ITEM, ""), message)) }),
               class: "flex list-disc flex-col gap-1 pl-5")
      else
        tag.p(safe_join(lines.map { |line| assistant_inline(line.sub(/\A#+\s*/, ""), message) }, tag.br))
      end
    end)
  end

  # Each [n] links to the card it cites; a number with no card stays plain text.
  def assistant_inline(text, message)
    safe_join(text.split(ANSWER_INLINE).map do |part|
      next tag.strong(assistant_inline(part[2...-2], message), class: "font-semibold") if part.start_with?("**")

      number = part[/\A\[(\d+)\]\z/, 1]&.to_i
      next part unless number&.between?(1, message.cards.size)

      link_to(part, "#assistant_card_#{message.id}_#{number}",
              data: { action: "assistant-sources#reveal" }, class: "font-mono text-sm text-primary-fg hover:underline",
              aria: { label: t("assistant.cita", number: number, title: message.cards[number - 1]["title"]) })
    end)
  end

  # Asked from a ? popover: the drawer opens with the term already written.
  def velita_question_path(term, figure: nil)
    assistant_path(from: velita_screen, q: term, via: "help", figure: figure)
  end
end
