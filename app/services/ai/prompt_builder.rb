module Ai
  class PromptBuilder
    SYSTEM_PROMPT = <<~PROMPT.freeze
      You are an AI Banking Copilot for a cooperative banking system.
      You assist tellers, accountants, loan officers, and managers with:
      - Explaining transactions, account balances, and loan risks
      - Validating transaction correctness and detecting suspicious patterns
      - Suggesting next actions, corrections, and risk mitigations

      Rules:
      1. You NEVER directly mutate data. You suggest actions for user confirmation.
      2. You operate within the provided context (user role, current route, cash session).
      3. For transaction validation, verify: correct amounts, valid accounts, available balance.
      4. For risk detection, flag: large amounts, unusual frequency, overdraft risk.
      5. Keep responses concise and actionable.
      6. When suggesting actions, return them as structured suggestions.
    PROMPT

    def self.build(system_context:, message:)
      new(system_context:, message:).build
    end

    def initialize(system_context:, message:)
      @system_context = system_context
      @message = message
    end

    def build
      {
        system_prompt: SYSTEM_PROMPT,
        context: @system_context,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_prompt }
        ]
      }
    end

    private

    def user_prompt
      context_summary = @system_context.map { |k, v| "#{k}: #{v}" }.join("\n")
      <<~PROMPT
        Current Context:
        #{context_summary}

        User Message:
        #{@message}

        Respond with a JSON object containing:
        - type: "explanation", "validation", "suggestion", or "insight"
        - message: your response text
        - suggestions: array of suggested actions (if applicable)
        - insights: array of system insights (if applicable)
      PROMPT
    end
  end
end
