require "rails_helper"

RSpec.describe "Management::Messaging::Messages", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:member) { create(:member) }

  before do
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end

  describe "GET /management/messaging/messages" do
    it "renders the messages index page" do
      get management_messaging_messages_path
      expect(response).to have_http_status(:ok)
    end

    it "includes messages in the response" do
      create(:messaging_message, recipient: member)
      get management_messaging_messages_path
      expect(response.body).to include("member_activation")
    end
  end

  describe "GET /management/messaging/messages/:id" do
    it "renders the message show page" do
      message = create(:messaging_message, recipient: member)
      get management_messaging_message_path(message)
      expect(response).to have_http_status(:ok)
    end

    it "displays delivery information" do
      message = create(:messaging_message, recipient: member)
      email_channel = create(:messaging_channel, name: "email")
      create(:messaging_message_delivery, message: message, channel: email_channel, status: "sent")

      get management_messaging_message_path(message)
      expect(response.body).to include("queued")
    end
  end
end
