require "rails_helper"

RSpec.describe Messaging::MessageDelivery do
  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:message).class_name("Messaging::Message") }
    it { is_expected.to belong_to(:channel).class_name("Messaging::Channel") }
    it { is_expected.to belong_to(:provider).class_name("Messaging::Provider").optional }
  end

  describe "enums" do
    it "defines status enum" do
      expect(subject).to define_enum_for(:status)
        .with_values(
          queued: "queued",
          sent: "sent",
          delivered: "delivered",
          failed: "failed",
          retrying: "retrying"
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe "scopes" do
    describe ".pending" do
      it "returns pending deliveries" do
        queued_delivery = create(:messaging_message_delivery, status: "queued")
        retrying_delivery = create(:messaging_message_delivery, status: "retrying")
        sent_delivery = create(:messaging_message_delivery, status: "sent")

        expect(described_class.pending).to include(queued_delivery)
        expect(described_class.pending).to include(retrying_delivery)
        expect(described_class.pending).not_to include(sent_delivery)
      end
    end

    describe ".failed" do
      it "returns failed deliveries" do
        failed_delivery = create(:messaging_message_delivery, status: "failed")
        sent_delivery = create(:messaging_message_delivery, status: "sent")

        expect(described_class.failed).to include(failed_delivery)
        expect(described_class.failed).not_to include(sent_delivery)
      end
    end
  end

  describe "#completed?" do
    it "returns true for sent status" do
      delivery = build(:messaging_message_delivery, status: "sent")
      expect(delivery.completed?).to be true
    end

    it "returns true for delivered status" do
      delivery = build(:messaging_message_delivery, status: "delivered")
      expect(delivery.completed?).to be true
    end

    it "returns false for queued status" do
      delivery = build(:messaging_message_delivery, status: "queued")
      expect(delivery.completed?).to be false
    end

    it "returns false for failed status" do
      delivery = build(:messaging_message_delivery, status: "failed")
      expect(delivery.completed?).to be false
    end
  end

  describe "#increment_attempts!" do
    it "increments attempts_count" do
      delivery = create(:messaging_message_delivery, attempts_count: 0)
      delivery.increment_attempts!
      expect(delivery.attempts_count).to eq(1)
    end
  end

  describe "#mark_sent!" do
    it "updates status to sent and sets sent_at" do
      delivery = create(:messaging_message_delivery, status: "queued")
      delivery.mark_sent!(provider_message_id: "msg_123")

      expect(delivery.status).to eq("sent")
      expect(delivery.sent_at).to be_present
      expect(delivery.provider_message_id).to eq("msg_123")
    end
  end

  describe "#mark_delivered!" do
    it "updates status to delivered and sets delivered_at" do
      delivery = create(:messaging_message_delivery, status: "sent")
      delivery.mark_delivered!

      expect(delivery.status).to eq("delivered")
      expect(delivery.delivered_at).to be_present
    end
  end

  describe "#mark_failed!" do
    it "updates status to failed and sets last_error" do
      delivery = create(:messaging_message_delivery, status: "queued")
      delivery.mark_failed!("Connection timeout")

      expect(delivery.status).to eq("failed")
      expect(delivery.last_error).to eq("Connection timeout")
    end
  end

  describe "#mark_retrying!" do
    it "updates status to retrying and sets last_error" do
      delivery = create(:messaging_message_delivery, status: "failed")
      delivery.mark_retrying!("Temporary failure")

      expect(delivery.status).to eq("retrying")
      expect(delivery.last_error).to eq("Temporary failure")
    end
  end
end