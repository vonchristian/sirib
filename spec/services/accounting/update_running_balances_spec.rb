require "rails_helper"

RSpec.describe Accounting::UpdateRunningBalances do
  describe "#execute" do
    it "updates account running balances" do
      entry = create(:accounting_entry_with_debits_and_credits)
      expect {
        described_class.run!(entry:)
      }.to change(Accounting::RunningBalance, :count).by_at_least(1)
    end
  end
end