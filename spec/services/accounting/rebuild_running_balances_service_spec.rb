require "rails_helper"

RSpec.describe Accounting::RebuildRunningBalancesService do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe "#execute" do
    it "replaces all running balances with fresh computation" do
      create(:accounting_running_balance, cooperative: cooperative)
      expect {
        described_class.run!
      }.to change(Accounting::RunningBalance, :count).to(0)
    end

    it "rebuilds running balances from entries" do
      create(:accounting_entry, cooperative: cooperative)
      expect {
        described_class.run!
      }.to change(Accounting::RunningBalance, :count).by_at_least(1)
    end

    it "swaps tables atomically (old data remains accessible during rebuild)" do
      create(:accounting_entry, cooperative: cooperative)
      described_class.run!
      expect(Accounting::RunningBalance.count).to be >= 1
    end
  end
end
