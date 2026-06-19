module Messaging
  module Providers
    class BaseProvider
      Result = Struct.new(:success?, :provider_message_id, :error, keyword_init: true) do
        def self.success(provider_message_id)
          new(success?: true, provider_message_id: provider_message_id)
        end

        def self.failure(error)
          new(success?: false, error: error)
        end
      end

      attr_reader :delivery

      def send(delivery)
        @delivery = delivery
        perform_send
      rescue => e
        Result.failure(e.message)
      end

      private

      def message
        @delivery.message
      end

      def recipient
        @recipient ||= message.recipient_type.constantize.find(message.recipient_id)
      end

      def payload
        message.payload_data
      end

      def perform_send
        raise NotImplementedError, "Subclasses must implement #perform_send"
      end

      def config
        @delivery.provider.config || {}
      end
    end
  end
end
