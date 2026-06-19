module Messaging
  class ProcessDeliveryJob < ApplicationJob
    queue_as :messaging

    retry_on StandardError, attempts: 3, wait: :exponential_backoff

    def perform(delivery)
      delivery = MessageDelivery.find(delivery.id)

      message = delivery.message
      message.mark_processing! if message.pending?

      Messaging::DeliveryProcessor.call(delivery)
    end
  end
end
