require "rails_helper"

RSpec.describe Lending::LoanLink do
  describe "associations" do
    it { is_expected.to belong_to(:from_loan).class_name("Lending::Loan") }
    it { is_expected.to belong_to(:to_loan).class_name("Lending::Loan") }
    it { is_expected.to belong_to(:cooperative) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:link_type).in_array(%w[modification refinance hybrid]) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    let!(:mod_link) { create(:lending_loan_link, link_type: "modification") }
    let!(:refi_link) { create(:lending_loan_link, link_type: "refinance") }
    let!(:hybrid_link) { create(:lending_loan_link, link_type: "hybrid") }

    it "filters by type" do
      expect(Lending::LoanLink.modifications).to contain_exactly(mod_link)
      expect(Lending::LoanLink.refinances).to contain_exactly(refi_link)
      expect(Lending::LoanLink.hybrids).to contain_exactly(hybrid_link)
    end
  end

  describe "uniqueness" do
    subject { build(:lending_loan_link) }

    it "validates uniqueness of to_loan_id scoped to from_loan_id" do
      existing = create(:lending_loan_link)
      duplicate = build(:lending_loan_link, from_loan: existing.from_loan, to_loan: existing.to_loan)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:to_loan_id]).to include("link already exists between these loans")
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan_link)).to be_valid
    end
  end
end
