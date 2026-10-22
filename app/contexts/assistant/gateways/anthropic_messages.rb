module Assistant
  module Gateways
    # Anthropic's Messages API, streamed. SheLLM speaks the same dialect at
    # /v1/messages, so a base URL is all that tells the two apart.
    class AnthropicMessages
      class Error < StandardError; end

      Verification = Data.define(:status, :detail)

      API_VERSION = "2023-06-01"
      VERIFY_STATUSES = { 401 => :unauthorized, 403 => :unauthorized, 404 => :not_found }.freeze

      def initialize(base_url:, api_key:, model:, timeout: 90)
        @base_url = base_url
        @api_key = api_key
        @model = model
        @timeout = timeout
      end

      def stream(system:, messages:, max_tokens: 600, &on_text)
        parser = EventStream.new
        failed = +""
        connection.post("/v1/messages") do |req|
          req.headers.update(headers)
          req.body = JSON.generate(model: @model, max_tokens:, stream: true, system:, messages:)
          req.options.on_data = proc do |chunk, _bytes, env|
            next failed << chunk if env&.status.to_i >= 400

            parser.feed(chunk) { |event| handle(event, &on_text) }
          end
        end
        raise Error, redact(failed) unless failed.empty?
      rescue Faraday::Error => e
        raise Error, redact(e.message)
      end

      # One non-streamed request; the planner's reply is text, so any Messages host can plan.
      def complete(system:, messages:, max_tokens: 400)
        response = plan_connection.post("/v1/messages") do |req|
          req.headers.update(headers)
          req.body = JSON.generate(model: @model, max_tokens:, system:, messages:)
        end
        raise Error, redact(provider_message(response)) if response.status >= 400

        content = JSON.parse(response.body.to_s)["content"]
        raise Error, "malformed response" unless content.is_a?(Array)

        content.filter_map { |block| block["text"] if block.is_a?(Hash) && block["type"] == "text" }.join
      rescue JSON::ParserError
        raise Error, "malformed response"
      rescue Faraday::Error => e
        raise Error, redact(e.message)
      end

      def verify
        response = verify_connection.post("/v1/messages") do |req|
          req.headers.update(headers)
          req.body = JSON.generate(model: @model, max_tokens: 1, messages: [ { role: "user", content: "ping" } ])
        end
        verification_for(response)
      rescue Faraday::TimeoutError => e
        Verification.new(status: :timeout, detail: redact(e.message))
      rescue Faraday::ConnectionFailed => e
        status = e.wrapped_exception.is_a?(Timeout::Error) ? :timeout : :unreachable
        Verification.new(status:, detail: redact(e.message))
      rescue Faraday::Error => e
        Verification.new(status: :unreachable, detail: redact(e.message))
      end

      private

      def headers
        { "x-api-key" => @api_key, "anthropic-version" => API_VERSION, "content-type" => "application/json" }
      end

      def verification_for(response)
        return Verification.new(status: :ok, detail: nil) if response.status < 400

        status = VERIFY_STATUSES.fetch(response.status, :failed)
        Verification.new(status:, detail: redact(provider_message(response)))
      end

      def provider_message(response)
        body = JSON.parse(response.body.to_s)
        message = body.dig("error", "message") if body.is_a?(Hash) && body["error"].is_a?(Hash)
        message.presence || response.status.to_s
      rescue JSON::ParserError
        response.status.to_s
      end

      # A provider or a proxy may echo the request back; the key must never reach the UI.
      def redact(text)
        @api_key.present? ? text.to_s.gsub(@api_key, "[redacted]") : text.to_s
      end

      def handle(event)
        case event["type"]
        when "content_block_delta"
          yield event.dig("delta", "text") if event.dig("delta", "type") == "text_delta"
        when "error"
          raise Error, redact(event.dig("error", "message"))
        end
      end

      def connection
        @connection ||= Faraday.new(url: @base_url) do |f|
          f.options.timeout = @timeout
          f.options.open_timeout = 10
        end
      end

      def plan_connection
        Faraday.new(url: @base_url) do |f|
          f.options.timeout = 15
          f.options.open_timeout = 5
        end
      end

      def verify_connection
        Faraday.new(url: @base_url) do |f|
          f.options.timeout = 10
          f.options.open_timeout = 5
        end
      end

      # Server-sent events arrive in arbitrary chunks; an event ends at a blank line.
      # A malformed or oversized stream is the provider failing, not a crash.
      class EventStream
        MAX_BUFFER = 1_000_000

        def initialize = @buffer = +""

        def feed(chunk)
          @buffer << chunk
          raise Error, "stream buffer exceeded" if @buffer.bytesize > MAX_BUFFER

          while (boundary = @buffer.index("\n\n"))
            data = @buffer.slice!(0, boundary + 2)[/^data: (.+)$/, 1]
            yield parse(data) if data
          end
        end

        private

        def parse(data)
          event = JSON.parse(data)
          raise Error, "malformed stream event" unless event.is_a?(Hash)

          event
        rescue JSON::ParserError
          raise Error, "malformed stream event"
        end
      end
    end
  end
end
