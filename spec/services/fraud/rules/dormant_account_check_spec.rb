require "rails_helper"

RSpec.describe Fraud::Rules::DormantAccountCheck do
  subject(:rule_instance) { described_class.new(rule, account: account) }

  let(:rule) { create(:fraud_rule, rule_type: "dormant_account", config: { "days_threshold" => 90 }) }
  let(:cooperative) { rule.cooperative }
  let(:account) { create(:accounting_account, cooperative: cooperative) }

  around { |example| Current.with(cooperative: cooperative) { example.run } }

  describe "#call" do
    context "when account has no activity" do
      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when last activity is older than threshold" do
      before do
        entry = create(:accounting_entry, cooperative: cooperative, created_at: 100.days.ago)
        create(:accounting_amount_line, entry: entry, account: account, cooperative: cooperative)
      end

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when last activity is within threshold" do
      before do
        entry = create(:accounting_entry, cooperative: cooperative, created_at: 1.day.ago)
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
    it "includes the days threshold" do
      expect(rule_instance.description).to include("90 days")
    end
  end
end
