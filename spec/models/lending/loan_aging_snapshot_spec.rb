require "rails_helper"

RSpec.describe Lending::LoanAgingSnapshot do
  describe "associations" do
    it { is_expected.to belong_to(:loan_aging_group) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:snapshot_date) }
    it { is_expected.to validate_numericality_of(:loan_count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:member_count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:principal_amount_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:interest_amount_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_exposure_cents).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    it "filters by date" do
      today = create(:lending_loan_aging_snapshot, snapshot_date: Date.current)
      create(:lending_loan_aging_snapshot, snapshot_date: 1.day.ago)

      expect(described_class.for_date(Date.current)).to include(today)
    end
  end
end
