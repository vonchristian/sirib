module Messaging
  class DeliveryProcessor
    def self.call(delivery)
      new(delivery).process
    end

    def initialize(delivery)
      @delivery = delivery
    end

    def process
      return unless can_process?

      message = @delivery.message
      channel = @delivery.channel
      provider = find_provider(channel)

      unless provider
        @delivery.mark_failed!("No enabled provider for channel: #{channel.name}")
        update_message_status
        return
      end

      @delivery.update!(provider: provider)
      @delivery.increment_attempts!

      send_via_provider(provider)
    rescue => e
      handle_failure(e)
    end

    private

    def can_process?
      return false if @delivery.sent? || @delivery.delivered?
      true
    end

    def find_provider(channel)
      channel.providers.enabled.order(:id).first
    end

    def send_via_provider(provider)
      result = provider_klass(provider).send(@delivery)

      if result.success?
        @delivery.mark_sent!(provider_message_id: result.provider_message_id)
        update_message_status
      else
        @delivery.mark_failed!(result.error)
        update_message_status
      end
    end

    def provider_klass(provider)
      case provider.name
      when "sendgrid"
        Messaging::Providers::SendgridProvider
      when "ses"
        Messaging::Providers::SesProvider
      when "facebook"
        Messaging::Providers::FacebookProvider
      else
        raise ArgumentError, "Unknown provider: #{provider.name}"
      end
    end

    def handle_failure(error)
      @delivery.mark_failed!(error.message)
      update_message_status
    end

    def update_message_status
      message = @delivery.message

      if message.all_deliveries_completed?
        if message.any_delivery_failed?
          message.mark_failed!
        else
          message.mark_completed!
        end
      elsif message.pending?
        message.mark_processing!
      end
    end
  end
end
