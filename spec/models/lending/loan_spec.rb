require "rails_helper"

RSpec.describe Lending::Loan do
  describe "associations" do
    it { is_expected.to belong_to(:loan_application) }
    it { is_expected.to belong_to(:member).class_name("Membership::Member") }
    it { is_expected.to belong_to(:loan_product) }
    it { is_expected.to have_many(:loan_payments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:loan_schedules).dependent(:destroy) }
    it { is_expected.to have_many(:loan_events).dependent(:destroy) }
    it { is_expected.to have_many(:loan_restructure_cases).dependent(:destroy) }
    it { is_expected.to have_many(:outgoing_loan_links).class_name("Lending::LoanLink").with_foreign_key(:from_loan_id).dependent(:destroy) }
    it { is_expected.to have_many(:incoming_loan_links).class_name("Lending::LoanLink").with_foreign_key(:to_loan_id).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:principal_cents).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:interest_rate).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:interest_calculation).in_array(%w[straight_line declining_balance]) }
    it { is_expected.to validate_numericality_of(:term_months).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:outstanding_principal_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active paid defaulted written_off refinanced modified hybrid_restructured restructure_requested under_review]) }
  end

  describe "scopes" do
    let!(:active_loan) { create(:lending_loan, status: "active") }
    let!(:paid_loan) { create(:lending_loan, status: "paid") }
    let!(:modified_loan) { create(:lending_loan, status: "modified") }
    let!(:refinanced_loan) { create(:lending_loan, status: "refinanced") }

    it "scopes by status" do
      expect(Lending::Loan.active).to contain_exactly(active_loan)
      expect(Lending::Loan.paid).to contain_exactly(paid_loan)
    end

    it "scopes restructured" do
      expect(Lending::Loan.restructured).to contain_exactly(modified_loan, refinanced_loan)
    end
  end

  describe "#restructurable?" do
    it "returns true for active loans under limit" do
      loan = build(:lending_loan, status: "active", restructures_count: 0, max_restructures: 2)
      expect(loan).to be_restructurable
    end

    it "returns true for defaulted loans under limit" do
      loan = build(:lending_loan, status: "defaulted", restructures_count: 0, max_restructures: 2)
      expect(loan).to be_restructurable
    end

    it "returns false when max restructures reached" do
      loan = build(:lending_loan, status: "active", restructures_count: 2, max_restructures: 2)
      expect(loan).not_to be_restructurable
    end

    it "returns false for paid loans" do
      loan = build(:lending_loan, status: "paid", restructures_count: 0, max_restructures: 2)
      expect(loan).not_to be_restructurable
    end

    it "returns false for written_off loans" do
      loan = build(:lending_loan, status: "written_off", restructures_count: 0, max_restructures: 2)
      expect(loan).not_to be_restructurable
    end
  end

  describe "#increment_restructures!" do
    it "increments the restructures counter" do
      loan = create(:lending_loan, restructures_count: 0)
      expect { loan.increment_restructures! }.to change { loan.reload.restructures_count }.by(1)
    end
  end

  describe "#lineage" do
    it "returns [self] for loans with no links" do
      loan = create(:lending_loan)
      expect(loan.lineage).to eq([ loan ])
    end

    it "traces ancestors through refinance links" do
      ancestor = create(:lending_loan)
      loan = create(:lending_loan)
      create(:lending_loan_link, from_loan: ancestor, to_loan: loan, link_type: "refinance")
      expect(loan.lineage).to eq([ ancestor, loan ])
    end
  end

  describe "#linked_loans" do
    it "returns all linked loans" do
      loan = create(:lending_loan)
      linked = create(:lending_loan)
      create(:lending_loan_link, from_loan: loan, to_loan: linked, link_type: "refinance")
      expect(loan.linked_loans).to contain_exactly(linked)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan)).to be_valid
    end
  end
end
