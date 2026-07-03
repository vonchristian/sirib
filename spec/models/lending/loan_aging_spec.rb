require "rails_helper"

RSpec.describe Lending::LoanAging do
  describe "associations" do
    it { is_expected.to belong_to(:loan) }
    it { is_expected.to belong_to(:loan_aging_group) }
  end

  describe "validations" do
    subject(:aging) { build(:lending_loan_aging) }

    it { is_expected.to validate_numericality_of(:days_past_due).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:outstanding_principal_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:outstanding_interest_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:penalty_amount_cents).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_exposure_cents).is_greater_than_or_equal_to(0) }
  end

  describe "scopes" do
    let(:cooperative) { create(:cooperative) }
    let!(:current_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "Current", min_days: 0, max_days: 0) }
    let!(:delinquent_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "1-30 Days", min_days: 1, max_days: 30) }

    it "scope delinquent returns only loans in buckets with min_days > 0" do
      current_aging = create(:lending_loan_aging, cooperative: cooperative, loan_aging_group: current_group)
      delinquent_aging = create(:lending_loan_aging, cooperative: cooperative, loan_aging_group: delinquent_group)

      expect(described_class.delinquent).to include(delinquent_aging)
      expect(described_class.delinquent).not_to include(current_aging)
    end

    it "scope by_group filters by group" do
      create(:lending_loan_aging, cooperative: cooperative, loan_aging_group: current_group)
      delinquent = create(:lending_loan_aging, cooperative: cooperative, loan_aging_group: delinquent_group)

      result = described_class.by_group(delinquent_group.id)
      expect(result).to include(delinquent)
    end
  end

  describe "#group_name" do
    it "delegates name to loan_aging_group" do
      group = build(:lending_loan_aging_group, name: "Current")
      aging = build(:lending_loan_aging, loan_aging_group: group)
      expect(aging.group_name).to eq("Current")
    end
  end
end
