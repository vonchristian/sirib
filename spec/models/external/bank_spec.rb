require "rails_helper"

RSpec.describe External::Bank do
  describe "associations" do
    it { is_expected.to have_many(:accounts).dependent(:destroy) }
    it { is_expected.to belong_to(:cash_on_hand_ledger).class_name("Accounting::Ledger").optional }
    it { is_expected.to belong_to(:interest_income_ledger).class_name("Accounting::Ledger").optional }
    it { is_expected.to belong_to(:cash_on_hand_account).class_name("Accounting::Account").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to define_enum_for(:status).with_values(active: "active", inactive: "inactive").backed_by_column_of_type(:string) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:external_bank)).to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active banks" do
        active_bank = create(:external_bank, status: "active")
        create(:external_bank, status: "inactive")

        expect(described_class.active).to contain_exactly(active_bank)
      end
    end
  end

  describe "#create_tracking_accounts" do
    it "creates cash and interest ledgers plus cash account" do
      cash_ledger = Accounting::Ledger.find_or_create_by!(
        name: "Cash in Bank",
        account_code: "11130",
        account_type: :asset
      )

      interest_parent = Accounting::Ledger.find_or_create_by!(
        name: "Income from Credit Operations",
        account_code: "40100",
        account_type: :revenue
      )

      bank = create(:external_bank)
      bank.reload

      expect(bank.cash_on_hand_ledger).to be_present
      expect(bank.cash_on_hand_account).to be_present
      expect(bank.interest_income_ledger).to be_present
      expect(bank.cash_on_hand_ledger.parent).to eq(cash_ledger)
      expect(bank.interest_income_ledger.parent).to eq(interest_parent)
    end
  end
end
