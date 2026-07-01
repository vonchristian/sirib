module Management
  module Messaging
    class ProvidersController < Management::Messaging::BaseController
      include Pagy::Backend

      before_action :require_permission!, subject: "messaging_providers"
      before_action :set_channel
      before_action :set_provider, only: [ :show, :edit, :update, :destroy ]

      def index
        providers = @channel.providers
        @pagy, @providers = pagy(providers, limit: 25)
      end

      def new
        @provider = @channel.providers.build
      end

      def create
        @provider = @channel.providers.build(provider_params)

        if @provider.save
          redirect_to management_messaging_channel_provider_path(@channel, @provider), notice: "Provider created successfully."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def show
      end

      def edit
      end

      def update
        if @provider.update(provider_params)
          redirect_to management_messaging_channel_provider_path(@channel, @provider), notice: "Provider updated successfully."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @provider.message_deliveries.any?
          redirect_to management_messaging_channel_provider_path(@channel, @provider), alert: "Cannot delete provider with existing deliveries."
        else
          @provider.destroy
          redirect_to management_messaging_channel_providers_path(@channel), notice: "Provider deleted successfully."
        end
      end

      private

      def set_channel
        @channel = Messaging::Channel.find(params[:channel_id])
      end

      def set_provider
        @provider = @channel.providers.find(params[:id])
      end

      def provider_params
        params.require(:messaging_provider).permit(:name, :config, :enabled)
      end
    end
  end
end
