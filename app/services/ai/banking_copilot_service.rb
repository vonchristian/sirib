module Ai
  class BankingCopilotService
    DEFAULT_LLM_URL = "https://api.openai.com/v1/chat/completions"

    def self.call(message:, context:)
      new(message:, context:).call
    end

    def initialize(message:, context:)
      @message = message
      @context = context
    end

    def call
      prompt = PromptBuilder.build(system_context: @context, message: @message)
      response = query_llm(prompt)
      parsed = parse_response(response)
      ActionRouter.route_response(parsed)
    rescue StandardError => e
      {
        type: "error",
        message: "AI service unavailable: #{e.message}",
        suggestions: [],
        insights: []
      }
    end

    private

    def query_llm(prompt)
      api_key = ENV["OPENAI_API_KEY"]
      return mock_response(prompt) if api_key.blank?

      uri = URI(ENV.fetch("LLM_API_URL", DEFAULT_LLM_URL))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{api_key}"
      request.body = {
        model: ENV.fetch("LLM_MODEL", "gpt-4o-mini"),
        messages: prompt[:messages],
        temperature: 0.3,
        response_format: { type: "json_object" }
      }.to_json

      response = http.request(request)
      body = JSON.parse(response.body)

      if response.is_a?(Net::HTTPSuccess)
        body.dig("choices", 0, "message", "content")
      else
        Rails.logger.error("LLM API error: #{body}")
        mock_response(prompt)
      end
    end

    def mock_response(prompt)
      {
        type: "explanation",
        message: "AI Copilot is in offline mode. I can still provide basic guidance based on the current context.",
        suggestions: [
          { label: "Explain current view", action: "explain_context" },
          { label: "Validate transaction", action: "validate_transaction" }
        ],
        insights: [
          { type: "info", text: "Role: #{@context[:user_role]}" },
          { type: "info", text: "Route: #{@context[:current_route]}" }
        ]
      }.to_json
    end

    def parse_response(raw)
      return raw if raw.is_a?(Hash)

      JSON.parse(raw)
    rescue JSON::ParserError
      { type: "explanation", message: raw.to_s, suggestions: [], insights: [] }
    end
  end
end
