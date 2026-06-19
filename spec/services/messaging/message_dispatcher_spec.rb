require "rails_helper"

RSpec.describe Messaging::MessageDispatcher do
  describe "#execute" do
    let(:member) { create(:member) }

    context "with valid inputs" do
      it "creates a message with pending status" do
        create(:messaging_channel, name: "email", enabled: true)

        result = described_class.run!(
          message_type: "member_activation",
          recipient: member,
          payload: { token: "abc123" },
          channels: ["email"]
        )

        expect(result).to be_persisted
        expect(result.status).to eq("pending")
        expect(result.message_type).to eq("member_activation")
        expect(result.recipient_type).to eq("Membership::Member")
        expect(result.recipient_id).to eq(member.id)
        expect(result.payload).to include("token" => "abc123")
      end

      it "creates message deliveries for each channel" do
        email_channel = create(:messaging_channel, name: "email", enabled: true)
        messenger_channel = create(:messaging_channel, name: "messenger", enabled: true)

        result = described_class.run!(
          message_type: "block_notice",
          recipient: member,
          payload: { body: "Account blocked" },
          channels: ["email", "messenger"]
        )

        expect(result.deliveries.count).to eq(2)
        expect(result.deliveries.pluck(:channel_id)).to match_array([email_channel.id, messenger_channel.id])
        expect(result.deliveries.pluck(:status)).to all(eq("queued"))
      end

      it "uses all enabled channels when no channels specified" do
        email_channel = create(:messaging_channel, name: "email", enabled: true)
        messenger_channel = create(:messaging_channel, name: "messenger", enabled: true)
        disabled_channel = create(:messaging_channel, name: "sms", enabled: false)

        result = described_class.run!(
          message_type: "password_reset",
          recipient: member,
          payload: {}
        )

        expect(result.deliveries.count).to eq(2)
        expect(result.deliveries.pluck(:channel_id)).not_to include(disabled_channel.id)
      end

      it "enqueues ProcessDeliveryJob for each delivery" do
        create(:messaging_channel, name: "email", enabled: true)

        expect {
          described_class.run!(
            message_type: "member_activation",
            recipient: member,
            payload: { token: "abc" },
            channels: ["email"]
          )
        }.to have_enqueued_job(Messaging::ProcessDeliveryJob)
      end

      it "sets scheduled_at when provided" do
        create(:messaging_channel, name: "email", enabled: true)
        scheduled_time = 1.day.from_now

        result = described_class.run!(
          message_type: "member_activation",
          recipient: member,
          payload: {},
          channels: ["email"],
          scheduled_at: scheduled_time
        )

        expect(result.scheduled_at).to be_within(1.second).of(scheduled_time)
      end
    end

    context "with invalid inputs" do
      it "fails when message_type is missing" do
        result = described_class.run(
          message_type: nil,
          recipient: member,
          payload: {}
        )

        expect(result).not_to be_valid
        expect(result.errors[:message_type]).to be_present
      end

      it "fails when recipient is missing" do
        result = described_class.run(
          message_type: "member_activation",
          recipient: nil,
          payload: {}
        )

        expect(result).not_to be_valid
        expect(result.errors[:recipient]).to be_present
      end

      it "fails when channel does not exist" do
        result = described_class.run(
          message_type: "member_activation",
          recipient: member,
          payload: {},
          channels: ["nonexistent_channel"]
        )

        expect(result).not_to be_valid
        expect(result.errors[:channels]).to be_present
      end
    end
  end
end