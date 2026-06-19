require "ostruct"

module Messaging
  class WebhookProcessor
    def self.call(provider_name, payload)
      new(provider_name, payload).process
    end

    def initialize(provider_name, payload)
      @provider_name = provider_name
      @payload = payload.with_indifferent_access
    end

    def process
      provider = Provider.enabled.find_by(name: @provider_name)
      return failure("Provider not found: #{@provider_name}") unless provider

      webhook = create_webhook_record(provider)
      return success("Webhook already processed") if webhook.processed?

      delivery = find_delivery(provider, webhook)
      return failure("Delivery not found for webhook") unless delivery

      process_event(delivery, webhook)
      webhook.process!

      success("Webhook processed")
    rescue => e
      failure(e.message)
    end

    private

    def create_webhook_record(provider)
      ProviderWebhook.create_with(
        payload: @payload.to_h
      ).find_or_create_by!(
        provider: provider,
        event_type: event_type
      )
    end

    def find_delivery(provider, webhook)
      provider_message_id = extract_provider_message_id
      return nil unless provider_message_id

      MessageDelivery.find_by(
        provider: provider,
        provider_message_id: provider_message_id
      )
    end

    def process_event(delivery, webhook)
      case event_type
      when "delivered"
        delivery.mark_delivered!
      when "bounced", "failed"
        delivery.mark_failed!(@payload[:reason] || "Provider reported failure")
      when "read"
        delivery.update!(delivered_at: Time.current) if delivery.sent?
      end
    end

    def event_type
      @event_type ||= extract_event_type
    end

    def extract_event_type
      @payload[:event] || @payload[:eventType] || @payload[:type] || "unknown"
    end

    def extract_provider_message_id
      @payload[:provider_message_id] ||
        @payload[:message_id] ||
        @payload[:sg_message_id] ||
        @payload[:messageId]
    end

    def success(message)
      OpenStruct.new(success?: true, message: message)
    end

    def failure(message)
      OpenStruct.new(success?: false, message: message)
    end
  end
end
