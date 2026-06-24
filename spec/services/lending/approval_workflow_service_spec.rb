require "rails_helper"

RSpec.describe Lending::ApprovalWorkflowService do
  describe ".call" do
    subject(:workflow) { described_class.call(restructure_case: restructure_case) }

    let(:loan) { create(:lending_loan, principal_cents: 100_000_00, outstanding_principal_cents: 75_000_00) }
    let(:restructure_case) { create(:lending_loan_restructure_case, loan: loan) }

    it "returns required_approvals" do
      expect(workflow[:required_approvals]).to be_an(Array)
    end

    it "includes credit_officer as first level" do
      expect(workflow[:required_approvals].first).to eq("credit_officer")
    end

    it "returns routing info for each level" do
      expect(workflow[:routing]).to all(include(:name, :description))
    end
  end
end
