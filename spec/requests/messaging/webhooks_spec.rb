require "rails_helper"

RSpec.describe "Messaging::Webhooks", type: :request do
  describe "POST /messaging/webhooks/receive" do
    let(:provider) { create(:messaging_provider, name: "sendgrid", enabled: true) }
    let(:email_channel) { create(:messaging_channel, name: "email", enabled: true) }
    let(:member) { create(:member) }
    let(:message) { create(:messaging_message, recipient: member) }
    let(:delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, provider: provider, status: "sent") }

    context "with valid sendgrid payload" do
      it "processes delivered event successfully" do
        payload = {
          provider_message_id: delivery.provider_message_id,
          event: "delivered"
        }.to_json

        post messaging_webhooks_receive_path, params: payload, headers: { "Content-Type" => "application/json", "X-Provider" => "sendgrid" }

        expect(response).to have_http_status(:ok)
        expect(delivery.reload.status).to eq("delivered")
      end

      it "processes failed event successfully" do
        payload = {
          provider_message_id: delivery.provider_message_id,
          event: "failed",
          reason: "Invalid email"
        }.to_json

        post messaging_webhooks_receive_path, params: payload, headers: { "Content-Type" => "application/json", "X-Provider" => "sendgrid" }

        expect(response).to have_http_status(:ok)
        expect(delivery.reload.status).to eq("failed")
        expect(delivery.last_error).to include("Invalid email")
      end

      it "returns unprocessable_entity for unknown provider" do
        payload = { event: "delivered" }.to_json

        post messaging_webhooks_receive_path, params: payload, headers: { "Content-Type" => "application/json", "X-Provider" => "unknown_provider" }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with provider detection from payload" do
      it "detects sendgrid from sg_message_id" do
        payload = {
          sg_message_id: delivery.provider_message_id,
          event: "delivered"
        }.to_json

        post messaging_webhooks_receive_path, params: payload, headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
      end
    end

    it "does not require authentication" do
      payload = { event: "delivered" }.to_json

      post messaging_webhooks_receive_path, params: payload, headers: { "Content-Type" => "application/json" }

      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
