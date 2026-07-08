require "rails_helper"

RSpec.describe External::ReconciliationAuditJob do
  describe "#perform" do
    it "logs an audit message" do
      allocation = create(:external_bank_transaction_allocation)
      allow(Rails.logger).to receive(:info).and_call_original
      expect(Rails.logger).to receive(:info).with(/ReconciliationAudit:/)
      described_class.perform_now(allocation, "confirmed", 1)
    end
  end
end
