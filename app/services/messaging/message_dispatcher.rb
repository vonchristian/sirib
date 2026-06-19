module Messaging
  class MessageDispatcher < ActiveInteraction::Base
    string :message_type
    object :recipient, class: Object, default: nil
    hash :payload, default: {}
    array :channels, default: [] do
      string
    end
    time :scheduled_at, default: nil

    def execute
      message = Message.create!(
        message_type: message_type,
        recipient_type: recipient.class.name,
        recipient_id: recipient.id,
        payload: payload,
        scheduled_at: scheduled_at,
        status: :pending
      )

      channel_objects = find_channels

      deliveries = channel_objects.map do |channel|
        delivery = MessageDelivery.create!(
          message: message,
          channel: channel,
          status: :queued
        )
        delivery
      end

      deliveries.each do |delivery|
        Messaging::ProcessDeliveryJob.perform_later(delivery)
      end

      message
    end

    private

    def find_channels
      available_channels = Channel.enabled.pluck(:name)

      requested_channels = channels.any? ? channels : available_channels

      requested_channels.map do |channel_name|
        Channel.find_by!(name: channel_name)
      end
    end
  end
end
