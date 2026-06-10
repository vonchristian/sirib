require "rails_helper"

RSpec.describe Accounting::RunningBalance do
  describe "validations" do
    it { is_expected.to validate_presence_of(:as_of_date) }
    it { is_expected.to validate_presence_of(:balance_cents) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account).optional }
    it { is_expected.to belong_to(:ledger) }
  end

  describe "custom validations" do
    it "requires either account or ledger" do
      rb = build(:accounting_running_balance, account: nil, ledger_id: nil)
      rb.valid?
      expect(rb.errors[:base]).to include("must belong to either an account or a ledger")
    end

    it "requires account_id for account balance" do
      rb = build(:accounting_running_balance, account: nil)
      rb.valid?
      expect(rb.errors[:account_id]).to include("can't be blank")
    end
  end

  describe "#account_balance?" do
    it "returns true when account_id is present" do
      rb = build(:accounting_running_balance)
      expect(rb).to be_account_balance
    end

    it "returns false when account_id is nil" do
      rb = build(:accounting_running_balance, account: nil, ledger: create(:accounting_ledger))
      expect(rb).not_to be_account_balance
    end
  end

  describe "#ledger_balance?" do
    it "returns true when account_id is nil" do
      rb = build(:accounting_running_balance, account: nil, ledger: create(:accounting_ledger))
      expect(rb).to be_ledger_balance
    end

    it "returns false when account_id is present" do
      rb = build(:accounting_running_balance)
      expect(rb).not_to be_ledger_balance
    end
  end

  describe "scopes" do
    let!(:older) { create(:accounting_running_balance, as_of_date: 5.days.ago) }
    let!(:recent) { create(:accounting_running_balance, as_of_date: Date.current) }

    it "filters as_of date" do
      expect(described_class.as_of(Date.current)).to contain_exactly(recent)
    end

    it "filters on_or_before date" do
      expect(described_class.on_or_before(3.days.ago)).to contain_exactly(older)
    end

    it "returns account_balances" do
      ledger = create(:accounting_ledger)
      ledger_rb = create(:accounting_running_balance, account: nil, ledger:)
      expect(described_class.account_balances).to include(recent)
      expect(described_class.account_balances).not_to include(ledger_rb)
    end

    it "returns ledger_balances" do
      ledger = create(:accounting_ledger)
      ledger_rb = create(:accounting_running_balance, account: nil, ledger:)
      expect(described_class.ledger_balances).to include(ledger_rb)
      expect(described_class.ledger_balances).not_to include(recent)
    end
  end

  describe ".latest_for_account" do
    it "returns the most recent running balance on or before a date" do
      account = create(:accounting_account)
      old = create(:accounting_running_balance, account:, as_of_date: 5.days.ago, balance_cents: 100)
      recent = create(:accounting_running_balance, account:, as_of_date: Date.current, balance_cents: 200)
      expect(described_class.latest_for_account(account.id)).to eq(recent)
    end
  end

  describe ".latest_for_ledger" do
    it "returns the most recent running balance on or before a date" do
      ledger = create(:accounting_ledger)
      old = create(:accounting_running_balance, account: nil, ledger:, as_of_date: 5.days.ago, balance_cents: 100)
      recent = create(:accounting_running_balance, account: nil, ledger:, as_of_date: Date.current, balance_cents: 200)
      expect(described_class.latest_for_ledger(ledger.id)).to eq(recent)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:accounting_running_balance)).to be_valid
    end
  end
end