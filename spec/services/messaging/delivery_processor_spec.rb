require "rails_helper"

RSpec.describe Messaging::DeliveryProcessor do
  describe ".call" do
    let(:member) { create(:member) }
    let(:email_channel) { create(:messaging_channel, name: "email", enabled: true) }
    let(:provider) { create(:messaging_provider, channel: email_channel, name: "sendgrid", enabled: true) }

    context "when delivery can be processed" do
      let(:message) { create(:messaging_message, recipient_type: "Membership::Member", recipient_id: member.id) }
      let(:delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, status: "queued") }

      it "sets provider on delivery" do
        described_class.call(delivery)

        delivery.reload
        expect(delivery.provider).to eq(provider)
      end

      it "increments attempts_count" do
        expect {
          described_class.call(delivery)
        }.to change { delivery.reload.attempts_count }.by(1)
      end

      it "marks message as processing if pending" do
        described_class.call(delivery)

        expect(message.reload.status).to eq("processing")
      end

      it "returns early if delivery already sent" do
        delivery.update!(status: "sent", sent_at: Time.current)

        expect {
          described_class.call(delivery)
        }.not_to change { delivery.reload.attempts_count }
      end

      it "returns early if delivery already delivered" do
        delivery.update!(status: "delivered", delivered_at: Time.current)

        expect {
          described_class.call(delivery)
        }.not_to change { delivery.reload.attempts_count }
      end
    end

    context "when no provider is available" do
      let(:message) { create(:messaging_message, recipient_type: "Membership::Member", recipient_id: member.id) }
      let(:delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, status: "queued") }

      before do
        provider.update!(enabled: false)
      end

      it "marks delivery as failed" do
        described_class.call(delivery)

        expect(delivery.reload.status).to eq("failed")
        expect(delivery.last_error).to include("No enabled provider")
      end
    end

    context "when message already processing" do
      let(:message) { create(:messaging_message, status: "processing", recipient_type: "Membership::Member", recipient_id: member.id) }
      let(:delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, status: "queued") }

      it "does not update message status again" do
        described_class.call(delivery)

        expect(message.reload.status).to eq("processing")
      end
    end

    context "when all deliveries complete" do
      let(:message) { create(:messaging_message, status: "processing", recipient_type: "Membership::Member", recipient_id: member.id) }
      let(:email_delivery) { create(:messaging_message_delivery, message: message, channel: email_channel, provider: provider, status: "queued") }
      let(:messenger_channel) { create(:messaging_channel, name: "messenger", enabled: true) }
      let(:messenger_delivery) { create(:messaging_message_delivery, message: message, channel: messenger_channel, status: "queued") }

      before do
        email_delivery
        messenger_delivery
      end

      it "marks message as completed when all deliveries succeed" do
        allow(Messaging::Providers::SendgridProvider).to receive(:send).and_return(Messaging::Providers::BaseProvider::Result.success("msg_123"))

        described_class.call(email_delivery)
        described_class.call(messenger_delivery)

        expect(message.reload.status).to eq("completed")
      end

      it "marks message as failed if any delivery fails" do
        allow(Messaging::Providers::SendgridProvider).to receive(:send).and_return(Messaging::Providers::BaseProvider::Result.success("msg_123"))
        allow_any_instance_of(Messaging::Providers::FacebookProvider).to receive(:send).and_return(Messaging::Providers::BaseProvider::Result.failure("Facebook error"))

        described_class.call(email_delivery)

        facebook_provider = create(:messaging_provider, channel: messenger_channel, name: "facebook", enabled: true)
        messenger_delivery.update!(provider: facebook_provider)
        described_class.call(messenger_delivery)

        expect(message.reload.status).to eq("failed")
      end
    end
  end
end