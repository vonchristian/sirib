require "rails_helper"

RSpec.describe External::BankAccount do
  describe "associations" do
    it { is_expected.to belong_to(:bank).class_name("External::Bank") }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
    it { is_expected.to have_many(:transactions).dependent(:destroy) }
    it { is_expected.to belong_to(:cash_on_hand_account).class_name("Accounting::Account").optional }
    it { is_expected.to belong_to(:interest_income_account).class_name("Accounting::Account").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:account_name) }
    it { is_expected.to validate_presence_of(:account_type) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to define_enum_for(:status).with_values(active: "active", inactive: "inactive").backed_by_column_of_type(:string) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:external_bank_account)).to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active accounts" do
        active = create(:external_bank_account, status: "active")
        create(:external_bank_account, status: "inactive")

        expect(described_class.active).to contain_exactly(active)
      end
    end
  end

  describe "#delegations" do
    it "delegates bank_name to bank" do
      bank = create(:external_bank, name: "BDO")
      account = create(:external_bank_account, bank: bank)

      expect(account.bank_name).to eq("BDO")
    end
  end

  describe "#current_balance_money" do
    it "returns a Money object" do
      account = build(:external_bank_account, current_balance_cents: 500_00, currency: "PHP")

      expect(account.current_balance_money).to be_a(Money)
      expect(account.current_balance_money.cents).to eq(500_00)
      expect(account.current_balance_money.currency.to_s).to eq("PHP")
    end

    it "returns zero when balance is nil" do
      account = build(:external_bank_account, current_balance_cents: nil)

      expect(account.current_balance_money.cents).to eq(0)
    end
  end

  describe "#last_transaction" do
    it "returns the most recent transaction" do
      account = create(:external_bank_account)
      old_tx = create(:external_bank_transaction, account: account, transaction_date: 5.days.ago)
      new_tx = create(:external_bank_transaction, account: account, transaction_date: 1.day.ago)

      expect(account.last_transaction).to eq(new_tx)
    end

    it "returns nil when no transactions exist" do
      account = create(:external_bank_account)

      expect(account.last_transaction).to be_nil
    end
  end

  describe "#update_balance!" do
    it "updates balance from last transaction running balance" do
      account = create(:external_bank_account)
      create(:external_bank_transaction, account: account,
             transaction_date: Date.current, running_balance_cents: 2500_00, running_balance_currency: "PHP")

      account.update_balance!

      expect(account.reload.current_balance_cents).to eq(2500_00)
    end

    it "sets balance to zero when no transactions exist" do
      account = create(:external_bank_account, current_balance_cents: 1000_00)

      account.update_balance!

      expect(account.reload.current_balance_cents).to eq(0)
    end
  end
end