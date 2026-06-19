require "rails_helper"

RSpec.describe Messaging::Channel do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates uniqueness of name" do
      create(:messaging_channel, name: "email")
      channel = build(:messaging_channel, name: "email")
      expect(channel).not_to be_valid
      expect(channel.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:providers).class_name("Messaging::Provider").dependent(:restrict_with_error) }
    it { is_expected.to have_many(:message_deliveries).class_name("Messaging::MessageDelivery").dependent(:restrict_with_error) }
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled channels" do
        email_channel = create(:messaging_channel, name: "unique_email_1", enabled: true)
        messenger_channel = create(:messaging_channel, name: "unique_messenger_1", enabled: false)

        expect(described_class.enabled).to include(email_channel)
        expect(described_class.enabled).not_to include(messenger_channel)
      end
    end
  end

  describe "#email?" do
    it "returns true for email channel" do
      channel = build(:messaging_channel, name: "email")
      expect(channel.email?).to be true
    end

    it "returns false for non-email channel" do
      channel = build(:messaging_channel, name: "messenger")
      expect(channel.email?).to be false
    end
  end

  describe "#messenger?" do
    it "returns true for messenger channel" do
      channel = build(:messaging_channel, name: "messenger")
      expect(channel.messenger?).to be true
    end

    it "returns false for non-messenger channel" do
      channel = build(:messaging_channel, name: "email")
      expect(channel.messenger?).to be false
    end
  end
end