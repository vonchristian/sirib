require "rails_helper"

RSpec.describe Lending::LoanAgingGroup do
  describe "validations" do
    subject(:group) { build(:lending_loan_aging_group) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:min_days).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:display_order).is_greater_than_or_equal_to(0) }

    it "validates max_days >= min_days" do
      group.min_days = 30
      group.max_days = 15
      expect(group).not_to be_valid
      expect(group.errors[:max_days]).to include("must be greater than or equal to min_days")
    end

    it "allows nil max_days" do
      group.min_days = 181
      group.max_days = nil
      expect(group).to be_valid
    end
  end

  describe "scopes" do
    it "orders by display_order" do
      groups = []
      groups << create(:lending_loan_aging_group, display_order: 2, name: "B")
      groups << create(:lending_loan_aging_group, display_order: 1, name: "A")
      groups << create(:lending_loan_aging_group, display_order: 3, name: "C")

      ordered = described_class.ordered.pluck(:name)
      expect(ordered).to eq(%w[A B C])
    end

    it "scopes active groups" do
      create(:lending_loan_aging_group, active: true, name: "Active")
      create(:lending_loan_aging_group, active: false, name: "Inactive")

      expect(described_class.active.count).to eq(1)
    end
  end

  describe "#covers?" do
    let(:group) { build(:lending_loan_aging_group, min_days: 31, max_days: 60) }

    it "returns true when dpd is within range" do
      expect(group.covers?(45)).to be true
    end

    it "returns false when dpd is below range" do
      expect(group.covers?(15)).to be false
    end

    it "returns false when dpd is above range" do
      expect(group.covers?(90)).to be false
    end

    it "returns true for inclusive boundaries" do
      expect(group.covers?(31)).to be true
      expect(group.covers?(60)).to be true
    end

    context "with nil max_days" do
      let(:group) { build(:lending_loan_aging_group, min_days: 181, max_days: nil) }

      it "returns true for any dpd >= min_days" do
        expect(group.covers?(200)).to be true
        expect(group.covers?(181)).to be true
      end

      it "returns false for dpd < min_days" do
        expect(group.covers?(100)).to be false
      end
    end

    context "when inactive" do
      let(:group) { build(:lending_loan_aging_group, active: false, min_days: 0, max_days: 0) }

      it "returns false" do
        expect(group.covers?(0)).to be false
      end
    end
  end

  describe ".find_bucket" do
    let(:cooperative) { create(:cooperative) }

    before do
      [
        { name: "Current", min_days: 0, max_days: 0, display_order: 0 },
        { name: "1-30 Days", min_days: 1, max_days: 30, display_order: 1 },
        { name: "Over 180 Days", min_days: 181, max_days: nil, display_order: 5 }
      ].each do |attrs|
        create(:lending_loan_aging_group, cooperative: cooperative, **attrs)
      end
    end

    it "finds current bucket for dpd 0" do
      expect(described_class.find_bucket(0).name).to eq("Current")
    end

    it "finds 1-30 bucket for dpd 15" do
      expect(described_class.find_bucket(15).name).to eq("1-30 Days")
    end

    it "finds over 180 bucket for dpd 200" do
      expect(described_class.find_bucket(200).name).to eq("Over 180 Days")
    end
  end

  describe "#range_label" do
    it "returns 'Current' for 0-0" do
      group = build(:lending_loan_aging_group, min_days: 0, max_days: 0, name: "Current")
      expect(group.range_label).to eq("Current")
    end

    it "returns '1-30 Days' for 1-30" do
      group = build(:lending_loan_aging_group, min_days: 1, max_days: 30)
      expect(group.range_label).to eq("1-30 Days")
    end

    it "returns '181 Days' for 181-nil" do
      group = build(:lending_loan_aging_group, min_days: 181, max_days: nil)
      expect(group.range_label).to eq("181 Days")
    end
  end
end
