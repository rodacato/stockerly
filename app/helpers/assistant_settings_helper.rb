module AssistantSettingsHelper
  # Unconfigured, saved but never checked, answering, or failing with a reason.
  def assistant_connection_state(connection)
    return :sin_configurar if connection.nil?
    return :conectada if connection[:status] == :connected
    return :sin_verificar if connection[:failure_tag].blank?

    :no_responde
  end

  def assistant_host_label(connection)
    host = URI.parse(connection[:base_url].to_s).host
    host == "api.anthropic.com" ? "Anthropic" : host
  rescue URI::InvalidURIError
    connection[:base_url]
  end
end
