require "rails_helper"

RSpec.describe Treasury::SavingsProduct do
  describe "associations" do
    it { is_expected.to have_many(:interest_rates).dependent(:destroy) }
    it { is_expected.to have_many(:savings_accounts).dependent(:restrict_with_error) }
    it { is_expected.to belong_to(:liability_ledger).class_name("Accounting::Ledger").optional }
    it { is_expected.to belong_to(:interest_expense_ledger).class_name("Accounting::Ledger").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active inactive]) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:savings_product)).to be_valid
    end
  end

  describe "#current_interest_rate" do
    it "returns the rate marked as current" do
      product = create(:savings_product)
      product.interest_rates.create!(rate: 0.001, current: false)
      current = product.interest_rates.create!(rate: 0.0025, current: true)

      expect(product.current_interest_rate).to eq(current)
    end

    it "returns nil when no current rate exists" do
      product = create(:savings_product)
      expect(product.current_interest_rate).to be_nil
    end
  end
end
