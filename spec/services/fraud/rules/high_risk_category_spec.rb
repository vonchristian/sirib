require "rails_helper"

RSpec.describe Fraud::Rules::HighRiskCategory do
  subject(:rule_instance) { described_class.new(rule, transaction: transaction) }

  let(:rule) { create(:fraud_rule, rule_type: "high_risk_category", config: { "risk_categories" => %w[high risky] }) }

  describe "#call" do
    context "when transaction category is in risk list" do
      let(:transaction) { double(category: "high") }

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when transaction category is not in risk list" do
      let(:transaction) { double(category: "low") }

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

    context "when transaction does not respond to category" do
      let(:transaction) { double }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when risk_categories is not configured" do
      let(:rule) { create(:fraud_rule, rule_type: "high_risk_category", config: {}) }
      let(:transaction) { double(category: "anything") }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end
  end

  describe "#description" do
    let(:transaction) { double(category: "high") }

    it "returns a description" do
      expect(rule_instance.description).to eq("Transaction category is high risk")
    end
  end
end
