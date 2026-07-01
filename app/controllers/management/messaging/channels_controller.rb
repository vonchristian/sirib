module Management
  module Messaging
    class ChannelsController < Management::Messaging::BaseController
      include Pagy::Backend

      before_action :require_permission!, subject: "messaging_channels"

      def index
        channels = Messaging::Channel.all
        @pagy, @channels = pagy(channels, limit: 25)
      end

      def show
        @channel = Messaging::Channel.find(params[:id])
        @providers = @channel.providers
      end

      def update
        @channel = Messaging::Channel.find(params[:id])

        if @channel.update(channel_params)
          redirect_to management_messaging_channel_path(@channel), notice: "Channel updated successfully."
        else
          redirect_to management_messaging_channel_path(@channel), alert: @channel.errors.full_messages.to_sentence
        end
      end

      private

      def channel_params
        params.require(:messaging_channel).permit(:enabled)
      end
    end
  end
end
