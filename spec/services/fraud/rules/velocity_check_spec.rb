require "rails_helper"

RSpec.describe Fraud::Rules::VelocityCheck do
  subject(:rule_instance) { described_class.new(rule, account: account) }

  let(:rule) { create(:fraud_rule, rule_type: "unusual_frequency", config: { "threshold" => 2, "window_minutes" => 60 }) }
  let(:cooperative) { rule.cooperative }
  let(:account) { create(:accounting_account, cooperative: cooperative) }

  around { |example| Current.with(cooperative: cooperative) { example.run } }

  describe "#call" do
    context "when transaction count exceeds threshold" do
      before do
        3.times do
          entry = create(:accounting_entry, cooperative: cooperative)
          create(:accounting_amount_line, entry: entry, account: account, cooperative: cooperative)
        end
      end

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when transaction count is below threshold" do
      before do
        entry = create(:accounting_entry, cooperative: cooperative)
        create(:accounting_amount_line, entry: entry, account: account, cooperative: cooperative)
      end

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when account is nil" do
      subject(:rule_instance) { described_class.new(rule, account: nil) }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end
  end

  describe "#description" do
    it "includes threshold and window" do
      expect(rule_instance.description).to include("2+")
      expect(rule_instance.description).to include("60 minutes")
    end
  end
end
