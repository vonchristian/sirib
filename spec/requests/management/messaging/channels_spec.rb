require "rails_helper"

RSpec.describe "Management::Messaging::Channels", type: :request do
  let(:user) { create(:user, password: "password123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /management/messaging/channels" do
    it "renders the channels index page" do
      get management_messaging_channels_path
      expect(response).to have_http_status(:ok)
    end

    it "displays channels" do
      create(:messaging_channel, name: "email")
      get management_messaging_channels_path
      expect(response.body).to include("email")
    end
  end

  describe "GET /management/messaging/channels/:id" do
    it "renders the channel show page" do
      channel = create(:messaging_channel, name: "email")
      get management_messaging_channel_path(channel)
      expect(response).to have_http_status(:ok)
    end

    it "displays associated providers" do
      channel = create(:messaging_channel, name: "email")
      create(:messaging_provider, channel: channel, name: "sendgrid")

      get management_messaging_channel_path(channel)
      expect(response.body).to include("sendgrid")
    end
  end

  describe "PATCH /management/messaging/channels/:id" do
    it "enables a disabled channel" do
      channel = create(:messaging_channel, name: "email", enabled: false)

      patch management_messaging_channel_path(channel), params: { messaging_channel: { enabled: true } }

      expect(channel.reload.enabled).to be true
      expect(response).to redirect_to(management_messaging_channel_path(channel))
      expect(flash[:notice]).to include("updated successfully")
    end

    it "disables an enabled channel" do
      channel = create(:messaging_channel, name: "email", enabled: true)

      patch management_messaging_channel_path(channel), params: { messaging_channel: { enabled: false } }

      expect(channel.reload.enabled).to be false
    end

    it "handles invalid params" do
      channel = create(:messaging_channel, name: "email")

      patch management_messaging_channel_path(channel), params: { messaging_channel: { name: "" } }

      expect(response).not_to have_http_status(:redirect)
    end
  end
end