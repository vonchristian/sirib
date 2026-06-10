require "rails_helper"

RSpec.describe Accounting::UpdateRunningBalancesJob do
  describe "#perform" do
    it "calls UpdateRunningBalances service" do
      entry = create(:accounting_entry)
      expect(Accounting::UpdateRunningBalances).to receive(:run!).with(entry:)
      described_class.perform_now(entry)
    end
  end
end