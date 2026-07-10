require "rails_helper"

RSpec.describe Fraud::Rules::AmountThreshold do
  subject(:rule_instance) { described_class.new(rule, transaction: transaction) }

  let(:rule) { create(:fraud_rule, rule_type: "large_amount", config: { "threshold_cents" => 50_00 }) }

  describe "#call" do
    context "when transaction exceeds threshold" do
      let(:transaction) { double(amount_cents: 100_00) }

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when transaction is below threshold" do
      let(:transaction) { double(amount_cents: 10_00) }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when transaction equals threshold" do
      let(:transaction) { double(amount_cents: 50_00) }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when transaction is nil" do
      let(:transaction) { nil }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when config has no threshold_cents" do
      let(:rule) { create(:fraud_rule, rule_type: "large_amount", config: {}) }
      let(:transaction) { double(amount_cents: 1_000_000_00) }

      it "uses default of 10_000_00" do
        expect(rule_instance.call).to be true
      end
    end
  end

  describe "#description" do
    let(:transaction) { double(amount_cents: 100_00) }

    it "includes the transaction amount" do
      expect(rule_instance.description).to include("10000 cents")
    end
  end
end
