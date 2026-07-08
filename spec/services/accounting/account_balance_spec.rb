require "rails_helper"

RSpec.describe Accounting::AccountBalance do
  describe ".resolve" do
    it "returns AsOfDateTime strategy when to_date and to_time given" do
      strategy = described_class.resolve(to_date: Date.current, to_time: Time.current)
      expect(strategy).to be_a(Accounting::AccountBalance::AsOfDateTime)
    end

    it "returns AsOfDate strategy when only to_date given" do
      strategy = described_class.resolve(to_date: Date.current)
      expect(strategy).to be_a(Accounting::AccountBalance::AsOfDate)
    end

    it "returns DateRange strategy when from_date given" do
      strategy = described_class.resolve(from_date: 5.days.ago)
      expect(strategy).to be_a(Accounting::AccountBalance::DateRange)
    end

    it "returns DateRange strategy when from_date and to_date given" do
      strategy = described_class.resolve(from_date: 5.days.ago, to_date: Date.current)
      expect(strategy).to be_a(Accounting::AccountBalance::DateRange)
    end

    it "returns Latest strategy with no args" do
      strategy = described_class.resolve
      expect(strategy).to be_a(Accounting::AccountBalance::Latest)
    end

    it "raises ArgumentError when to_time given without to_date" do
      expect {
        described_class.resolve(to_time: Time.current)
      }.to raise_error(ArgumentError, "to_time requires to_date")
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

  describe Accounting::AccountBalance::AsOfDateTime do
    subject(:strategy) { described_class.new(to_date: Date.current, to_time: Time.current) }

    it "loads amounts" do
      create(:accounting_amount_line, amount_cents: 1000)
      result = strategy.load_amounts
      expect(result.values.sum).to eq(1000)
    end

    it "applies scope" do
      scope = Accounting::AmountLine.all
      result = strategy.apply(scope)
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end

  describe Accounting::AccountBalance::AsOfDate do
    subject(:strategy) { described_class.new(to_date: Date.current) }

    it "loads amounts" do
      create(:accounting_amount_line, amount_cents: 1000)
      result = strategy.load_amounts
      expect(result.values.sum).to eq(1000)
    end

    it "applies scope" do
      scope = Accounting::AmountLine.all
      result = strategy.apply(scope)
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end

  describe Accounting::AccountBalance::DateRange do
    subject(:strategy) { described_class.new(from_date: 5.days.ago, to_date: Date.current) }

    it "loads amounts" do
      create(:accounting_amount_line, amount_cents: 1000)
      result = strategy.load_amounts
      expect(result.values.sum).to eq(1000)
    end

    it "applies scope" do
      scope = Accounting::AmountLine.all
      result = strategy.apply(scope)
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end

  describe Accounting::AccountBalance::Latest do
    subject(:strategy) { described_class.new }

    it "loads amounts" do
      create(:accounting_amount_line, amount_cents: 1000)
      result = strategy.load_amounts
      expect(result.values.sum).to eq(1000)
    end

    it "applies scope" do
      scope = Accounting::AmountLine.all
      result = strategy.apply(scope)
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end

  describe Accounting::AccountBalance::RunningBalance do
    subject(:strategy) { described_class.new(to_date: Date.current) }

    it "loads amounts from running_balances table" do
      account = create(:accounting_account)
      create(:accounting_running_balance, account:, balance_cents: 5000)
      result = strategy.load_amounts
      expect(result[account.id]).to eq(5000)
    end
  end
end
