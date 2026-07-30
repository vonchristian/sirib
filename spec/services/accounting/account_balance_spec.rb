require "rails_helper"

RSpec.describe Accounting::AccountBalance do
  describe ".load_amounts" do
    let(:debit_acct) { create(:accounting_account) }
    let(:credit_acct) { create(:accounting_account) }

    def create_entry
      build(:accounting_entry, create_lines: false, posted_at: Time.current.change(usec: 0)).tap do |e|
        e.amount_lines.build(amount_type: "debit", amount_cents: 1001, account: debit_acct)
        e.amount_lines.build(amount_type: "credit", amount_cents: 1001, account: credit_acct)
        e.save!
      end
    end

    it "returns amounts when to_date and to_time given" do
      create_entry
      result = described_class.load_amounts(to_date: Date.current, to_time: Time.current)
      expect(result[[ debit_acct.id, "debit" ]]).to eq(1001)
    end

    it "returns amounts when only to_date given" do
      create_entry
      result = described_class.load_amounts(to_date: Date.current)
      expect(result[[ debit_acct.id, "debit" ]]).to eq(1001)
    end

    it "returns amounts when from_date and to_date given" do
      create_entry
      result = described_class.load_amounts(from_date: 1.day.ago, to_date: Date.current)
      expect(result[[ debit_acct.id, "debit" ]]).to eq(1001)
    end

    it "returns amounts when no args given" do
      create_entry
      result = described_class.load_amounts
      expect(result[[ debit_acct.id, "debit" ]]).to eq(1001)
    end
  end

  describe ".load_running_balances" do
    it "loads amounts from running_balances table" do
      account = create(:accounting_account)
      create(:accounting_running_balance, account:, balance_cents: 5000)
      result = described_class.load_running_balances(to_date: Date.current)
      expect(result[account.id]).to eq(5000)
    end
  end

  describe ".apply_scope" do
    it "returns a relation given a scope" do
      scope = Accounting::AmountLine.all
      result = described_class.apply_scope(scope, to_date: Date.current)
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end

  describe ".balance" do
    it "returns Money from amounts hash" do
      account = create(:accounting_account)
      amounts = { account.id => 5000 }
      expect(described_class.balance(account, amounts)).to eq(Money.new(5000, "PHP"))
    end

    it "returns zero when account not in amounts" do
      account = create(:accounting_account)
      expect(described_class.balance(account, {})).to eq(Money.new(0, "PHP"))
    end
  end
end
