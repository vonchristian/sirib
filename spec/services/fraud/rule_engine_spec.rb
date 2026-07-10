require "rails_helper"

RSpec.describe Fraud::RuleEngine do
  describe ".evaluate" do
    it "returns empty array when no active rules exist" do
      result = described_class.evaluate
      expect(result).to eq([])
    end
  end

  describe "#evaluate" do
    let(:cooperative) { create(:cooperative) }

    it "flags a transaction that exceeds threshold" do
      rule = create(:fraud_rule, rule_type: "large_amount", config: { "threshold_cents" => 10_00 }, cooperative: cooperative)
      transaction = double(amount_cents: 100_00)
      flags = described_class.evaluate(transaction: transaction, cooperative: cooperative)
      expect(flags).not_to be_empty
      expect(flags.first).to include(:rule_id, :rule_name, :description, :severity)
    end

    it "does not flag a transaction below threshold" do
      rule = create(:fraud_rule, rule_type: "large_amount", config: { "threshold_cents" => 10_00 }, cooperative: cooperative)
      transaction = double(amount_cents: 1_00)
      flags = described_class.evaluate(transaction: transaction, cooperative: cooperative)
      expect(flags).to be_empty
    end

    it "scopes rules by cooperative" do
      other_coop = create(:cooperative)
      create(:fraud_rule, rule_type: "large_amount", config: { "threshold_cents" => 1_00 }, cooperative: other_coop)
      transaction = double(amount_cents: 100_00)

      flags = described_class.evaluate(transaction: transaction, cooperative: cooperative)
      expect(flags).to be_empty
    end

    it "only evaluates active rules" do
      create(:fraud_rule, rule_type: "large_amount", config: { "threshold_cents" => 1_00 }, cooperative: cooperative, active: false)
      transaction = double(amount_cents: 100_00)

      flags = described_class.evaluate(transaction: transaction, cooperative: cooperative)
      expect(flags).to be_empty
    end

    it "logs and skips rules with unknown type" do
      bad_rule = create(:fraud_rule, rule_type: "custom", cooperative: cooperative)
      transaction = double(amount_cents: 100_00)

      expect(Rails.logger).to receive(:error).with(/FraudRule\[#{bad_rule.id}\] unknown rule type:/)
      flags = described_class.evaluate(transaction: transaction, cooperative: cooperative)
      expect(flags).to be_empty
    end
  end
end
