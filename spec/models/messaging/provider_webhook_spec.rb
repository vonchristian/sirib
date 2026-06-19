require "rails_helper"

RSpec.describe Messaging::ProviderWebhook do
  let(:channel) { create(:messaging_channel, name: "email") }
  let(:provider) { create(:messaging_provider, channel: channel, name: "sendgrid") }

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }

    it "validates uniqueness of event_type scoped to provider for unprocessed records" do
      create(:messaging_provider_webhook, provider: provider, event_type: "delivered")
      webhook = build(:messaging_provider_webhook, provider: provider, event_type: "delivered")
      expect(webhook).not_to be_valid
      expect(webhook.errors[:event_type]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:provider).class_name("Messaging::Provider") }
  end

  describe "scopes" do
    describe ".unprocessed" do
      it "returns unprocessed webhooks" do
        unprocessed = create(:messaging_provider_webhook, provider: provider, processed_at: nil)
        processed = create(:messaging_provider_webhook, provider: provider, processed_at: Time.current)

        expect(described_class.unprocessed).to include(unprocessed)
        expect(described_class.unprocessed).not_to include(processed)
      end
    end

    describe ".by_event_type" do
      it "returns webhooks by event type" do
        delivered = create(:messaging_provider_webhook, provider: provider, event_type: "delivered")
        failed = create(:messaging_provider_webhook, provider: provider, event_type: "failed")

        expect(described_class.by_event_type("delivered")).to include(delivered)
        expect(described_class.by_event_type("delivered")).not_to include(failed)
      end
    end
  end

  describe "#payload_data" do
    it "returns payload as indifferent access hash" do
      webhook = build(:messaging_provider_webhook, payload: { "message_id" => "msg_123", "status" => "delivered" })
      expect(webhook.payload_data[:message_id]).to eq("msg_123")
      expect(webhook.payload_data["status"]).to eq("delivered")
    end
  end

  describe "#process!" do
    it "sets processed_at timestamp" do
      webhook = create(:messaging_provider_webhook, provider: provider, processed_at: nil)
      webhook.process!

      expect(webhook.processed_at).to be_present
    end
  end

  describe "#processed?" do
    it "returns true when processed_at is set" do
      webhook = create(:messaging_provider_webhook, provider: provider, processed_at: Time.current)
      expect(webhook.processed?).to be true
    end

    it "returns false when processed_at is nil" do
      webhook = create(:messaging_provider_webhook, provider: provider, processed_at: nil)
      expect(webhook.processed?).to be false
    end
  end
end