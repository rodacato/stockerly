module MarketData
  module Gateways
    # Driven adapter: LLM API for AI-powered analysis (portfolio insights, sentiment, etc.)
    # Supports Anthropic and OpenAI API formats. Custom base_url enables SheLLM, Ollama, Together, etc.
    # Fail-safe: returns Failure(:not_configured) when no Integration exists — never raises.
    class LlmGateway
    include Dry::Monads[:result]

    PROVIDER = "AI Intelligence"
    TIMEOUT  = 30

    DEFAULT_BASE_URLS = {
      "anthropic" => "https://api.anthropic.com",
      "openai"    => "https://api.openai.com"
    }.freeze

    def initialize
      @integration = Integration.find_by(provider_name: PROVIDER)
      @configured  = @integration.present? && @integration.api_key_encrypted.present?
    end

    def configured?
      @configured
    end

    # Send a completion request to the configured LLM provider.
    # Returns Success({ content:, provider:, model: }) or Failure.
    def complete(prompt:, system_prompt: nil, max_tokens: 1000)
      return Failure([ :not_configured, "AI Intelligence not configured" ]) unless configured?

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      provider = @integration.setting("provider") || "anthropic"
      model    = @integration.setting("model") || default_model(provider)
      base_url = @integration.setting("base_url") || DEFAULT_BASE_URLS[provider]

      case provider
      when "anthropic"
        complete_anthropic(prompt: prompt, system_prompt: system_prompt,
                           max_tokens: max_tokens, model: model, base_url: base_url)
      when "openai"
        complete_openai(prompt: prompt, system_prompt: system_prompt,
                        max_tokens: max_tokens, model: model, base_url: base_url)
      else
        Failure([ :gateway_error, "Unknown LLM provider: #{provider}" ])
      end
    end

    private

    def complete_anthropic(prompt:, system_prompt:, max_tokens:, model:, base_url:)
      body = {
        model: model,
        max_tokens: max_tokens,
        messages: [ { role: "user", content: prompt } ]
      }
      body[:system] = system_prompt if system_prompt.present?

      response = connection(base_url).post("/v1/messages") do |req|
        req.headers["x-api-key"] = @integration.api_key_encrypted
        req.headers["anthropic-version"] = "2023-06-01"
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      handle_response(response, provider: "anthropic", model: model) do |parsed|
        content = parsed.dig("content", 0, "text")
        content.present? ? Success({ content: content, provider: "anthropic", model: model }) :
                           Failure([ :gateway_error, "Empty response from Anthropic" ])
      end
    rescue Faraday::TimeoutError, Timeout::Error
      Failure([ :gateway_error, "LLM request timed out" ])
    rescue Faraday::Error => e
      timeout_failure?(e) ? Failure([ :gateway_error, "LLM request timed out" ]) :
                            Failure([ :gateway_error, e.message ])
    end

    def complete_openai(prompt:, system_prompt:, max_tokens:, model:, base_url:)
      messages = []
      messages << { role: "system", content: system_prompt } if system_prompt.present?
      messages << { role: "user", content: prompt }

      body = { model: model, max_tokens: max_tokens, messages: messages }

      response = connection(base_url).post("/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{@integration.api_key_encrypted}"
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end

      handle_response(response, provider: "openai", model: model) do |parsed|
        content = parsed.dig("choices", 0, "message", "content")
        content.present? ? Success({ content: content, provider: "openai", model: model }) :
                           Failure([ :gateway_error, "Empty response from OpenAI" ])
      end
    rescue Faraday::TimeoutError, Timeout::Error
      Failure([ :gateway_error, "LLM request timed out" ])
    rescue Faraday::Error => e
      timeout_failure?(e) ? Failure([ :gateway_error, "LLM request timed out" ]) :
                            Failure([ :gateway_error, e.message ])
    end

    def handle_response(response, provider:, model:)
      return Failure([ :rate_limited, "LLM rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "LLM returned #{response.status}" ]) unless response.success?

      parsed = JSON.parse(response.body)
      yield parsed
    rescue JSON::ParserError
      Failure([ :gateway_error, "Invalid JSON response from LLM" ])
    end

    def connection(base_url)
      Faraday.new(url: base_url) do |f|
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def timeout_failure?(error)
      error.cause.is_a?(Timeout::Error) || error.message.include?("timed out")
    end

    def default_model(provider)
      case provider
      when "anthropic" then "claude-sonnet-4-5-20250514"
      when "openai"    then "gpt-4o"
      end
    end
    end
  end
end
