require "rails_helper"

RSpec.describe "Management::Messaging::Providers", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:channel) { create(:messaging_channel, name: "email") }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /management/messaging/channels/:channel_id/providers" do
    it "renders the providers index page" do
      get management_messaging_channel_providers_path(channel)
      expect(response).to have_http_status(:ok)
    end

    it "displays providers for the channel" do
      create(:messaging_provider, channel: channel, name: "sendgrid")
      get management_messaging_channel_providers_path(channel)
      expect(response.body).to include("sendgrid")
    end
  end

  describe "GET /management/messaging/channels/:channel_id/providers/new" do
    it "renders the new provider form" do
      get new_management_messaging_channel_provider_path(channel)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /management/messaging/channels/:channel_id/providers" do
    it "creates a new provider" do
      expect {
        post management_messaging_channel_providers_path(channel), params: {
          messaging_provider: { name: "ses", enabled: true, config: {} }
        }
      }.to change(Messaging::Provider, :count).by(1)

      expect(response).to redirect_to(management_messaging_channel_provider_path(channel, Messaging::Provider.last))
      expect(flash[:notice]).to include("created successfully")
    end

    it "renders new form on validation error" do
      expect {
        post management_messaging_channel_providers_path(channel), params: {
          messaging_provider: { name: "", enabled: true }
        }
      }.not_to change(Messaging::Provider, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /management/messaging/channels/:channel_id/providers/:id" do
    it "renders the provider show page" do
      provider = create(:messaging_provider, channel: channel, name: "sendgrid")
      get management_messaging_channel_provider_path(channel, provider)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("sendgrid")
    end
  end

  describe "GET /management/messaging/channels/:channel_id/providers/:id/edit" do
    it "renders the edit provider form" do
      provider = create(:messaging_provider, channel: channel, name: "sendgrid")
      get edit_management_messaging_channel_provider_path(channel, provider)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /management/messaging/channels/:channel_id/providers/:id" do
    it "updates the provider" do
      provider = create(:messaging_provider, channel: channel, name: "sendgrid", enabled: true)

      patch management_messaging_channel_provider_path(channel, provider), params: {
        messaging_provider: { name: "ses", enabled: false }
      }

      provider.reload
      expect(provider.name).to eq("ses")
      expect(provider.enabled).to be false
      expect(response).to redirect_to(management_messaging_channel_provider_path(channel, provider))
    end

    it "renders edit form on validation error" do
      provider = create(:messaging_provider, channel: channel, name: "sendgrid")

      patch management_messaging_channel_provider_path(channel, provider), params: {
        messaging_provider: { name: "" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /management/messaging/channels/:channel_id/providers/:id" do
    it "deletes the provider" do
      provider = create(:messaging_provider, channel: channel, name: "sendgrid")

      expect {
        delete management_messaging_channel_provider_path(channel, provider)
      }.to change(Messaging::Provider, :count).by(-1)

      expect(response).to redirect_to(management_messaging_channel_providers_path(channel))
    end

    it "prevents deletion of provider with deliveries" do
      message = create(:messaging_message)
      provider = create(:messaging_provider, channel: channel, name: "sendgrid")
      create(:messaging_message_delivery, message: message, channel: channel, provider: provider)

      expect {
        delete management_messaging_channel_provider_path(channel, provider)
      }.not_to change(Messaging::Provider, :count)

      expect(response).to redirect_to(management_messaging_channel_provider_path(channel, provider))
      expect(flash[:alert]).to include("Cannot delete")
    end
  end
end