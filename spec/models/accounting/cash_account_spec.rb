require "rails_helper"

RSpec.describe Accounting::CashAccount do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    subject { create(:accounting_cash_account) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:account_id) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:accounting_cash_account)).to be_valid
    end
  end
end
