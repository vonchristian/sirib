module Ai
  class ActionRouter
    CONFIRMATION_REQUIRED_ACTIONS = %w[
      validate_transaction
      suggest_correction
      approve_transaction
      flag_for_review
    ].freeze

    def self.route_response(parsed_response)
      new.route_response(parsed_response)
    end

    def self.route(action_type, payload)
      new.route(action_type, payload)
    end

    def route_response(parsed_response)
      {
        type: parsed_response["type"] || "explanation",
        message: parsed_response["message"] || "",
        suggestions: build_suggestions(parsed_response["suggestions"] || []),
        insights: build_insights(parsed_response["insights"] || [])
      }
    end

    def route(action_type, payload)
      case action_type
      when "validate_transaction"
        route_validation(payload)
      when "explain_context"
        route_explain(payload)
      when "suggest_correction"
        route_correction(payload)
      when "flag_for_review"
        route_flag(payload)
      else
        { action: action_type, payload: payload, requires_confirmation: true,
          confirmation_message: "Execute #{action_type}?" }
      end
    end

    private

    def build_suggestions(suggestions)
      return [] unless suggestions.is_a?(Array)

      suggestions.map do |s|
        {
          label: s["label"] || s[:label],
          action: s["action"] || s[:action],
          payload: s["payload"] || s[:payload] || {},
          requires_confirmation: CONFIRMATION_REQUIRED_ACTIONS.include?(s["action"] || s[:action])
        }
      end
    end

    def build_insights(insights)
      return [] unless insights.is_a?(Array)

      insights.map do |i|
        {
          type: i["type"] || i[:type] || "info",
          text: i["text"] || i[:text] || "",
          severity: i["severity"] || i[:severity] || "low"
        }
      end
    end

    def route_validation(payload)
      transaction_id = payload["transaction_id"] || payload[:transaction_id]
      {
        action: "validate_transaction",
        payload: { transaction_id: transaction_id },
        requires_confirmation: true,
        confirmation_message: "Validate transaction ##{transaction_id}? This will check amounts, accounts, and balances."
      }
    end

    def route_explain(payload)
      {
        action: "explain_context",
        payload: payload,
        requires_confirmation: false,
        message: "Analyzing current context..."
      }
    end

    def route_correction(payload)
      {
        action: "suggest_correction",
        payload: payload,
        requires_confirmation: true,
        confirmation_message: "Apply suggested correction?"
      }
    end

    def route_flag(payload)
      {
        action: "flag_for_review",
        payload: payload,
        requires_confirmation: false,
        message: "Item flagged for review."
      }
    end
  end
end
