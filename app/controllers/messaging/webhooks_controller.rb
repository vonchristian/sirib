module Messaging
  class WebhooksController < ApplicationController
    skip_before_action :require_authentication
    skip_before_action :require_permission!, raise: false

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    def receive
      provider_name = extract_provider_name
      payload = webhook_params

      result = Messaging::WebhookProcessor.call(provider_name, payload)

      if result.success?
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def extract_provider_name
      if params[:provider].present?
        params[:provider]
      elsif request.headers["X-Provider"].present?
        request.headers["X-Provider"]
      else
        detect_provider_from_payload
      end
    end

    def detect_provider_from_payload
      payload = webhook_params

      if payload[:sg_message_id] || payload[:event] == "delivered"
        "sendgrid"
      elsif payload[:mail] || payload[:MessageId]
        "ses"
      elsif payload[:messaging] || payload[:entry]
        "facebook"
      else
        "unknown"
      end
    end

    def webhook_params
      if request.content_type == "application/json"
        JSON.parse(request.body.read).with_indifferent_access
      else
        params.permit!
      end
    end

    def not_found
      head :not_found
    end
  end
end
