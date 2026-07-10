require "rails_helper"

RSpec.describe Fraud::Rules::DuplicateCheck do
  subject(:rule_instance) { described_class.new(rule, transaction: transaction) }

  let(:rule) { create(:fraud_rule, rule_type: "duplicate_transaction", config: { "window_minutes" => 5 }) }
  let(:cooperative) { rule.cooperative }
  let(:transaction) { double(description: "Duplicate test") }

  around { |example| Current.with(cooperative: cooperative) { example.run } }

  describe "#call" do
    context "when a duplicate entry exists" do
      before do
        create(:accounting_entry, cooperative: cooperative, description: "Duplicate test")
      end

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when no duplicate entry exists" do
      before do
        create(:accounting_entry, cooperative: cooperative, description: "Unique test")
      end

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
  end

  describe "#description" do
    it "returns a description" do
      expect(rule_instance.description).to eq("Duplicate transaction detected")
    end
  end
end
