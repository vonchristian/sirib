require "rails_helper"

RSpec.describe Fraud::Rules::NightTransactionCheck do
  subject(:rule_instance) { described_class.new(rule, transaction: transaction) }

  let(:rule) { create(:fraud_rule, rule_type: "night_transactions", config: { "start_hour" => 22, "end_hour" => 5 }) }

  describe "#call" do
    context "when transaction is during night hours" do
      let(:transaction) { double(created_at: Time.zone.now.change(hour: 23)) }

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when transaction is during early morning" do
      let(:transaction) { double(created_at: Time.zone.now.change(hour: 3)) }

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when transaction is during daytime" do
      let(:transaction) { double(created_at: Time.zone.now.change(hour: 12)) }

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

    context "when transaction has no created_at" do
      let(:transaction) { double }

      before do
        allow(transaction).to receive(:created_at) { nil }
      end

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end
  end

  describe "#description" do
    let(:transaction) { double(created_at: Time.zone.now.change(hour: 23)) }

    it "includes the transaction time" do
      expect(rule_instance.description).to include("23:00")
    end
  end
end
