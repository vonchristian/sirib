require "rails_helper"

RSpec.describe Messaging::Provider do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates uniqueness of name scoped to channel_id" do
      channel = create(:messaging_channel, name: "email")
      create(:messaging_provider, channel: channel, name: "sendgrid")

      provider = build(:messaging_provider, channel: channel, name: "sendgrid")
      expect(provider).not_to be_valid
      expect(provider.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:channel).class_name("Messaging::Channel") }
    it { is_expected.to have_many(:message_deliveries).class_name("Messaging::MessageDelivery").dependent(:restrict_with_error) }
    it { is_expected.to have_many(:provider_webhooks).class_name("Messaging::ProviderWebhook").dependent(:restrict_with_error) }
  end

  describe "scopes" do
    describe ".enabled" do
      it "returns only enabled providers" do
        enabled_provider = create(:messaging_provider, name: "sendgrid", enabled: true)
        disabled_provider = create(:messaging_provider, name: "ses", enabled: false)

        expect(described_class.enabled).to include(enabled_provider)
        expect(described_class.enabled).not_to include(disabled_provider)
      end
    end
  end

  describe "#sendgrid?" do
    it "returns true for sendgrid provider" do
      provider = build(:messaging_provider, name: "sendgrid")
      expect(provider.sendgrid?).to be true
    end

    it "returns false for non-sendgrid provider" do
      provider = build(:messaging_provider, name: "ses")
      expect(provider.sendgrid?).to be false
    end
  end

  describe "#ses?" do
    it "returns true for ses provider" do
      provider = build(:messaging_provider, name: "ses")
      expect(provider.ses?).to be true
    end

    it "returns false for non-ses provider" do
      provider = build(:messaging_provider, name: "sendgrid")
      expect(provider.ses?).to be false
    end
  end

  describe "#facebook?" do
    it "returns true for facebook provider" do
      provider = build(:messaging_provider, name: "facebook")
      expect(provider.facebook?).to be true
    end

    it "returns false for non-facebook provider" do
      provider = build(:messaging_provider, name: "sendgrid")
      expect(provider.facebook?).to be false
    end
  end
end