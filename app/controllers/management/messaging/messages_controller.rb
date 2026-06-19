module Management
  module Messaging
    class MessagesController < Management::Messaging::BaseController
      include Pagy::Backend

      before_action :require_permission!, action: :index, subject: "messaging_messages"
      before_action :require_permission!, action: :show, subject: "messaging_messages"

      def index
        messages = Messaging::Message.order(created_at: :desc)
        @pagy, @messages = pagy(messages, limit: 25)
      end

      def show
        @message = Messaging::Message.find(params[:id])
        @deliveries = @message.deliveries.includes(:channel, :provider)
      end
    end
  end
end