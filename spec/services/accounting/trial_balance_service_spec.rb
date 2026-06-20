require "rails_helper"

RSpec.describe Accounting::TrialBalanceService do
  describe "#execute" do
    it "returns a hash with as_of_date" do
      result = described_class.run!(as_of: Date.new(2025, 6, 1))
      expect(result).to be_a(Hash)
      expect(result[:as_of_date]).to eq(Date.new(2025, 6, 1))
    end

    it "returns empty accounts and balanced state when no entries exist" do
      result = described_class.run!
      expect(result[:accounts]).to eq([])
      expect(result[:total_debit_cents]).to eq(0)
      expect(result[:total_credit_cents]).to eq(0)
      expect(result[:balanced]).to be true
    end

    it "returns account balances from posted entries" do
      asset = create(:accounting_account, account_type: :asset)
      liability = create(:accounting_account, account_type: :liability)
      entry = build(:accounting_entry, posted_at: Time.current)
      entry.amount_lines = []
      entry.amount_lines << build(:accounting_amount_line, entry: entry, account: asset, amount_type: "debit", amount_cents: 10000)
      entry.amount_lines << build(:accounting_amount_line, entry: entry, account: liability, amount_type: "credit", amount_cents: 10000)
      entry.save!

      result = described_class.run!(as_of: Date.current)

      account_ids = result[:accounts].map { |l| l[:account].id }
      expect(account_ids).to contain_exactly(asset.id, liability.id)
      expect(result[:total_debit_cents]).to eq(10000)
      expect(result[:total_credit_cents]).to eq(10000)
      expect(result[:balanced]).to be true
    end

    it "reports unbalanced when debits != credits" do
      asset = create(:accounting_account, account_type: :asset)
      entry = create(:accounting_entry, posted_at: Time.current)
      create(:accounting_amount_line, entry:, account: asset, amount_type: "debit", amount_cents: 10000)

      result = described_class.run!(as_of: Date.current)

      expect(result[:balanced]).to be false
      expect(result[:total_debit_cents]).not_to eq(result[:total_credit_cents])
    end

    it "computes net balance correctly for debit-normal accounts" do
      asset = create(:accounting_account, account_type: :asset)
      entry = create(:accounting_entry, posted_at: Time.current)
      create(:accounting_amount_line, entry:, account: asset, amount_type: "debit", amount_cents: 15000)
      create(:accounting_amount_line, entry:, account: asset, amount_type: "credit", amount_cents: 5000)

      result = described_class.run!(as_of: Date.current)
      line = result[:accounts].find { |l| l[:account].id == asset.id }

      expect(line[:net_debit_cents]).to eq(10000)
      expect(line[:net_credit_cents]).to eq(0)
    end

    it "computes net balance correctly for credit-normal accounts" do
      revenue = create(:accounting_account, account_type: :revenue)
      entry = create(:accounting_entry, posted_at: Time.current)
      create(:accounting_amount_line, entry:, account: revenue, amount_type: "debit", amount_cents: 3000)
      create(:accounting_amount_line, entry:, account: revenue, amount_type: "credit", amount_cents: 12000)

      result = described_class.run!(as_of: Date.current)
      line = result[:accounts].find { |l| l[:account].id == revenue.id }

      expect(line[:net_credit_cents]).to eq(9000)
      expect(line[:net_debit_cents]).to eq(0)
    end

    it "excludes entries posted after as_of date" do
      asset = create(:accounting_account, account_type: :asset)
      liability = create(:accounting_account, account_type: :liability)
      entry = create(:accounting_entry, posted_at: Date.new(2025, 6, 15))
      create(:accounting_amount_line, entry:, account: asset, amount_type: "debit", amount_cents: 10000)
      create(:accounting_amount_line, entry:, account: liability, amount_type: "credit", amount_cents: 10000)

      result = described_class.run!(as_of: Date.new(2025, 6, 1))

      expect(result[:accounts]).to be_empty
      expect(result[:balanced]).to be true
    end

    it "includes accounts with the correct structure" do
      asset = create(:accounting_account, account_type: :asset)
      entry = create(:accounting_entry, posted_at: Time.current)
      create(:accounting_amount_line, entry:, account: asset, amount_type: "debit", amount_cents: 5000)

      result = described_class.run!(as_of: Date.current)
      line = result[:accounts].first

      expect(line).to have_key(:account)
      expect(line).to have_key(:debit_cents)
      expect(line).to have_key(:credit_cents)
      expect(line).to have_key(:net_debit_cents)
      expect(line).to have_key(:net_credit_cents)
    end
  end
end
