require "rails_helper"

RSpec.describe Lending::LoanRestructureCase do
  describe "associations" do
    it { is_expected.to belong_to(:loan) }
    it { is_expected.to belong_to(:new_loan).class_name("Lending::Loan").optional }
    it { is_expected.to belong_to(:requested_by).class_name("User").optional }
    it { is_expected.to belong_to(:approved_by).class_name("User").optional }
    it { is_expected.to belong_to(:cooperative) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:restructure_type).in_array(%w[modification refinance hybrid]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft submitted under_review approved rejected executed failed]) }
  end

  describe "scopes" do
    let!(:draft_case) { create(:lending_loan_restructure_case, status: "draft") }
    let!(:submitted_case) { create(:lending_loan_restructure_case, status: "submitted") }
    let!(:approved_case) { create(:lending_loan_restructure_case, status: "approved") }
    let!(:executed_case) { create(:lending_loan_restructure_case, status: "executed") }
    let!(:rejected_case) { create(:lending_loan_restructure_case, status: "rejected") }

    it "scopes by status" do
      expect(Lending::LoanRestructureCase.draft).to contain_exactly(draft_case)
      expect(Lending::LoanRestructureCase.submitted).to contain_exactly(submitted_case)
      expect(Lending::LoanRestructureCase.approved).to contain_exactly(approved_case)
      expect(Lending::LoanRestructureCase.executed).to contain_exactly(executed_case)
      expect(Lending::LoanRestructureCase.rejected).to contain_exactly(rejected_case)
    end

    it "scopes pending_decision" do
      expect(Lending::LoanRestructureCase.pending_decision).to contain_exactly(submitted_case)
    end

    it "scopes by_type" do
      mod_cases = Lending::LoanRestructureCase.where(restructure_type: "modification").to_a
      new_mod = create(:lending_loan_restructure_case, restructure_type: "modification")
      expect(Lending::LoanRestructureCase.by_type("modification")).to contain_exactly(*mod_cases, new_mod)
    end
  end

  describe "#editable?" do
    it "returns true for draft cases" do
      expect(build(:lending_loan_restructure_case, status: "draft")).to be_editable
    end

    it "returns true for rejected cases" do
      expect(build(:lending_loan_restructure_case, status: "rejected")).to be_editable
    end

    it "returns false for submitted cases" do
      expect(build(:lending_loan_restructure_case, status: "submitted")).not_to be_editable
    end
  end

  describe "state transitions" do
    let(:restructure_case) { create(:lending_loan_restructure_case, status: "draft") }
    let(:user) { create(:user) }

    it "transitions from draft to submitted" do
      restructure_case.submit!
      expect(restructure_case).to be_submitted
      expect(restructure_case.submitted_at).to be_present
    end

    it "transitions from submitted to under_review" do
      restructure_case.submit!
      restructure_case.review!
      expect(restructure_case).to be_under_review
    end

    it "transitions from submitted to approved" do
      restructure_case.submit!
      restructure_case.approve!(approver: user)
      expect(restructure_case).to be_approved
      expect(restructure_case.approved_by).to eq(user)
      expect(restructure_case.reviewed_at).to be_present
    end

    it "transitions from submitted to rejected" do
      restructure_case.submit!
      restructure_case.reject!(approver: user)
      expect(restructure_case).to be_rejected
      expect(restructure_case.approved_by).to eq(user)
    end

    it "transitions from approved to executed" do
      restructure_case.submit!
      restructure_case.approve!(approver: user)
      restructure_case.execute!
      expect(restructure_case).to be_executed
      expect(restructure_case.executed_at).to be_present
    end

    it "transitions to failed" do
      restructure_case.fail!
      expect(restructure_case).to be_failed
    end
  end

  describe "type helpers" do
    it "detects modification" do
      expect(build(:lending_loan_restructure_case, restructure_type: "modification")).to be_modification
    end

    it "detects refinance" do
      expect(build(:lending_loan_restructure_case, restructure_type: "refinance")).to be_refinance
    end

    it "detects hybrid" do
      expect(build(:lending_loan_restructure_case, restructure_type: "hybrid")).to be_hybrid
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan_restructure_case)).to be_valid
    end
  end
end
