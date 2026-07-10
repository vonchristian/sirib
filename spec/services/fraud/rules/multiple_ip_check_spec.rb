require "rails_helper"

RSpec.describe Fraud::Rules::MultipleIpCheck do
  subject(:rule_instance) { described_class.new(rule, user: user) }

  let(:rule) { create(:fraud_rule, rule_type: "multiple_ips", config: { "threshold" => 2, "window_minutes" => 1440 }) }
  let(:cooperative) { rule.cooperative }
  let(:user) { create(:user, cooperative: cooperative) }

  describe "#call" do
    context "when user has multiple IPs exceeding threshold" do
      before do
        create(:session, user: user, ip_address: "192.168.1.1")
        create(:session, user: user, ip_address: "192.168.1.2")
      end

      it "returns true" do
        expect(rule_instance.call).to be true
      end
    end

    context "when user has fewer IPs than threshold" do
      before do
        create(:session, user: user, ip_address: "192.168.1.1")
      end

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end

    context "when user is nil" do
      subject(:rule_instance) { described_class.new(rule, user: nil) }

      it "returns false" do
        expect(rule_instance.call).to be false
      end
    end
  end

  describe "#description" do
    let(:user) { create(:user, cooperative: cooperative) }

    it "includes threshold and window" do
      expect(rule_instance.description).to include("2+")
      expect(rule_instance.description).to include("1440 minutes")
    end
  end
end
