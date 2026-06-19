require "rails_helper"

RSpec.describe Messaging::WebhookProcessor do
  describe ".call" do
    let(:provider) { create(:messaging_provider, name: "sendgrid", enabled: true) }
    let(:email_channel) { create(:messaging_channel, name: "email", enabled: true) }
    let(:member) { create(:member) }
    let(:message) { create(:messaging_message, recipient_type: "Membership::Member", recipient_id: member.id) }
    let(:delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, provider: provider, status: "sent") }

    context "with delivered event" do
      it "marks delivery as delivered" do
        payload = { provider_message_id: delivery.provider_message_id, event: "delivered" }

        described_class.call("sendgrid", payload)

        expect(delivery.reload.status).to eq("delivered")
        expect(delivery.delivered_at).to be_present
      end

      it "processes the webhook record" do
        payload = { provider_message_id: delivery.provider_message_id, event: "delivered" }

        described_class.call("sendgrid", payload)

        webhook = Messaging::ProviderWebhook.last
        expect(webhook.processed_at).to be_present
      end
    end

    context "with bounced event" do
      it "marks delivery as failed" do
        payload = { provider_message_id: delivery.provider_message_id, event: "bounced", reason: "Mailbox full" }

        described_class.call("sendgrid", payload)

        expect(delivery.reload.status).to eq("failed")
        expect(delivery.last_error).to include("Mailbox full")
      end
    end

    context "with failed event" do
      it "marks delivery as failed" do
        payload = { provider_message_id: delivery.provider_message_id, event: "failed", reason: "Invalid recipient" }

        described_class.call("sendgrid", payload)

        expect(delivery.reload.status).to eq("failed")
        expect(delivery.last_error).to include("Invalid recipient")
      end
    end

    context "with read event" do
      it "updates delivered_at if not already set" do
        delivery.update!(status: "sent", sent_at: Time.current, delivered_at: nil)
        payload = { provider_message_id: delivery.provider_message_id, event: "read" }

        described_class.call("sendgrid", payload)

        expect(delivery.reload.delivered_at).to be_present
      end
    end

    context "with duplicate webhook" do
      it "does not reprocess already processed webhook" do
        create(:messaging_provider_webhook, provider: provider, event_type: "delivered",
               payload: { provider_message_id: delivery.provider_message_id }, processed_at: Time.current)

        initial_delivered_at = delivery.delivered_at
        payload = { provider_message_id: delivery.provider_message_id, event: "delivered" }

        result = described_class.call("sendgrid", payload)

        expect(result.message).to include("already processed")
        expect(delivery.reload.delivered_at).to eq(initial_delivered_at)
      end
    end

    context "with unknown provider" do
      it "returns failure" do
        payload = { event: "delivered" }

        result = described_class.call("unknown_provider", payload)

        expect(result.success?).to be false
        expect(result.message).to include("Provider not found")
      end
    end

    context "with delivery not found" do
      it "returns failure when provider_message_id is missing" do
        payload = { event: "delivered" }

        result = described_class.call("sendgrid", payload)

        expect(result.success?).to be false
        expect(result.message).to include("Delivery not found")
      end

      it "returns failure when provider_message_id does not match any delivery" do
        payload = { provider_message_id: "nonexistent_id", event: "delivered" }

        result = described_class.call("sendgrid", payload)

        expect(result.success?).to be false
        expect(result.message).to include("Delivery not found")
      end
    end
  end
end