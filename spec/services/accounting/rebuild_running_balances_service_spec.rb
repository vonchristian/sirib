require "rails_helper"

RSpec.describe Accounting::RebuildRunningBalancesService do
  describe "#execute" do
    it "deletes all existing running balances" do
      create(:accounting_running_balance)
      expect {
        described_class.run!
      }.to change(Accounting::RunningBalance, :count).to(0)
    end

    it "rebuilds running balances from entries" do
      create(:accounting_entry_with_debits_and_credits)
      expect {
        described_class.run!
      }.to change(Accounting::RunningBalance, :count).by_at_least(1)
    end
  end
end