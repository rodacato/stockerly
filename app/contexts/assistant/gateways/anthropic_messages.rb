module Assistant
  module Gateways
    # Anthropic's Messages API, streamed. SheLLM speaks the same dialect at
    # /v1/messages, so a base URL is all that tells the two apart.
    class AnthropicMessages
      class Error < StandardError; end

      API_VERSION = "2023-06-01"

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
          req.headers.update("x-api-key" => @api_key, "anthropic-version" => API_VERSION,
                             "content-type" => "application/json")
          req.body = JSON.generate(model: @model, max_tokens:, stream: true, system:, messages:)
          req.options.on_data = proc do |chunk, _bytes, env|
            next failed << chunk if env&.status.to_i >= 400

            parser.feed(chunk) { |event| handle(event, &on_text) }
          end
        end
        raise Error, failed unless failed.empty?
      rescue Faraday::Error => e
        raise Error, e.message
      end

      private

      def handle(event)
        case event["type"]
        when "content_block_delta"
          yield event.dig("delta", "text") if event.dig("delta", "type") == "text_delta"
        when "error"
          raise Error, event.dig("error", "message").to_s
        end
      end

      def connection
        @connection ||= Faraday.new(url: @base_url) do |f|
          f.options.timeout = @timeout
          f.options.open_timeout = 10
        end
      end

      # Server-sent events arrive in arbitrary chunks; an event ends at a blank line.
      class EventStream
        def initialize = @buffer = +""

        def feed(chunk)
          @buffer << chunk
          while (boundary = @buffer.index("\n\n"))
            data = @buffer.slice!(0, boundary + 2)[/^data: (.+)$/, 1]
            yield JSON.parse(data) if data
          end
        end
      end
    end
  end
end
