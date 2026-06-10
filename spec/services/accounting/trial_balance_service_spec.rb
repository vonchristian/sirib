require "rails_helper"

RSpec.describe Accounting::TrialBalanceService do
  describe "#execute" do
    it "returns a Money object" do
      result = described_class.run!
      expect(result).to be_a(Money)
    end

    it "returns zero when no entries exist" do
      result = described_class.run!
      expect(result).to eq(Money.new(0, "PHP"))
    end

    it "calculates the trial balance" do
      asset = create(:accounting_account, account_type: :asset)
      liability = create(:accounting_account, account_type: :liability)
      entry = create(:accounting_entry, posted_at: Time.current)
      create(:accounting_amount_line, entry:, account: asset, amount_type: "debit", amount_cents: 10000)
      create(:accounting_amount_line, entry:, account: liability, amount_type: "credit", amount_cents: 10000)
      result = described_class.run!(as_of: Date.current)
      expect(result).to eq(Money.new(0, "PHP"))
    end
  end
end