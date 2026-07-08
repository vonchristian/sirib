require "rails_helper"

RSpec.describe Messaging::Message do
  describe "validations" do
    it { is_expected.to validate_presence_of(:message_type) }
    it { is_expected.to validate_presence_of(:recipient_type) }
    it { is_expected.to validate_presence_of(:recipient_id) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "associations" do
    it { is_expected.to have_many(:deliveries).class_name("Messaging::MessageDelivery").dependent(:destroy) }
  end

  describe "enums" do
    it "defines status enum" do
      expect(subject).to define_enum_for(:status)
        .with_values(
          pending: "pending",
          processing: "processing",
          completed: "completed",
          failed: "failed"
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe "scopes" do
    describe ".pending" do
      it "returns pending messages" do
        pending_message = create(:messaging_message, status: "pending")
        completed_message = create(:messaging_message, status: "completed")

        expect(described_class.pending).to include(pending_message)
        expect(described_class.pending).not_to include(completed_message)
      end
    end

    describe ".failed" do
      it "returns failed messages" do
        failed_message = create(:messaging_message, status: "failed")
        pending_message = create(:messaging_message, status: "pending")

        expect(described_class.failed).to include(failed_message)
        expect(described_class.failed).not_to include(pending_message)
      end
    end
  end

  describe "#payload_data" do
    it "returns payload as indifferent access hash" do
      message = build(:messaging_message, payload: { "subject" => "Test", "body" => "Content" })
      expect(message.payload_data[:subject]).to eq("Test")
      expect(message.payload_data["body"]).to eq("Content")
    end

    it "returns empty indifferent access hash when payload is nil" do
      message = build(:messaging_message, payload: nil)
      expect(message.payload_data).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end
  end

  describe "#mark_processing!" do
    it "updates status to processing" do
      message = create(:messaging_message, status: "pending")
      message.mark_processing!
      expect(message.status).to eq("processing")
    end
  end

  describe "#mark_completed!" do
    it "updates status to completed" do
      message = create(:messaging_message, status: "processing")
      message.mark_completed!
      expect(message.status).to eq("completed")
    end
  end

  describe "#mark_failed!" do
    it "updates status to failed" do
      message = create(:messaging_message, status: "processing")
      message.mark_failed!
      expect(message.status).to eq("failed")
    end
  end

  describe "#all_deliveries_completed?" do
    it "returns true when all deliveries are completed" do
      message = create(:messaging_message)
      email_delivery = create(:messaging_message_delivery, message: message, status: "sent")
      messenger_delivery = create(:messaging_message_delivery, message: message, status: "delivered")

      expect(message.all_deliveries_completed?).to be true
    end

    it "returns false when some deliveries are not completed" do
      message = create(:messaging_message)
      email_delivery = create(:messaging_message_delivery, message: message, status: "sent")
      messenger_delivery = create(:messaging_message_delivery, message: message, status: "queued")

      expect(message.all_deliveries_completed?).to be false
    end
  end

  describe "#any_delivery_failed?" do
    it "returns true when any delivery has failed" do
      message = create(:messaging_message)
      email_delivery = create(:messaging_message_delivery, message: message, status: "sent")
      messenger_delivery = create(:messaging_message_delivery, message: message, status: "failed")

      expect(message.any_delivery_failed?).to be true
    end

    it "returns false when no delivery has failed" do
      message = create(:messaging_message)
      email_delivery = create(:messaging_message_delivery, message: message, status: "sent")
      messenger_delivery = create(:messaging_message_delivery, message: message, status: "delivered")

      expect(message.any_delivery_failed?).to be false
    end
  end
end
