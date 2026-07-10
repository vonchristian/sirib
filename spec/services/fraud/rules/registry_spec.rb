require "rails_helper"

RSpec.describe Fraud::Rules::Registry do
  describe ".for" do
    it "returns AmountThreshold for large_amount" do
      rule = build(:fraud_rule, rule_type: "large_amount")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::AmountThreshold)
    end

    it "returns VelocityCheck for unusual_frequency" do
      rule = build(:fraud_rule, rule_type: "unusual_frequency")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::VelocityCheck)
    end

    it "returns VelocityCheck for rapid_transfers" do
      rule = build(:fraud_rule, rule_type: "rapid_transfers")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::VelocityCheck)
    end

    it "returns DormantAccountCheck for dormant_account" do
      rule = build(:fraud_rule, rule_type: "dormant_account")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::DormantAccountCheck)
    end

    it "returns NightTransactionCheck for night_transactions" do
      rule = build(:fraud_rule, rule_type: "night_transactions")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::NightTransactionCheck)
    end

    it "returns DuplicateCheck for duplicate_transaction" do
      rule = build(:fraud_rule, rule_type: "duplicate_transaction")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::DuplicateCheck)
    end

    it "returns MultipleIpCheck for multiple_ips" do
      rule = build(:fraud_rule, rule_type: "multiple_ips")
      instance = described_class.for(rule)
      expect(instance).to be_a(Fraud::Rules::MultipleIpCheck)
    end

    it "raises ArgumentError for unknown rule type" do
      rule = build(:fraud_rule, rule_type: "custom")

      expect { described_class.for(rule) }.to raise_error(ArgumentError, "Unknown rule type: custom")
    end

    it "passes context to the rule instance" do
      rule = build(:fraud_rule, rule_type: "large_amount")
      transaction = double(:transaction)
      instance = described_class.for(rule, transaction: transaction)
      expect(instance.transaction).to eq(transaction)
    end
  end

  describe "MAPPING" do
    it "is frozen" do
      expect(Fraud::Rules::Registry::MAPPING).to be_frozen
    end
  end
end
