require "rails_helper"

RSpec.describe Accounting::PostPendingEntryService do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe "#execute" do
    let(:asset_account) { create(:accounting_account, account_type: :asset, cooperative: cooperative) }
    let(:liability_account) { create(:accounting_account, account_type: :liability, cooperative: cooperative) }

    let(:pending_entry) do
      Accounting::PostEntryService.run!(
        description: "Pending test entry",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ],
        post_immediately: false
      )
    end

    it "transitions a pending entry to posted" do
      expect {
        described_class.run!(entry: pending_entry)
      }.to change { pending_entry.reload.status }.from("pending").to("posted")
    end

    it "updates running balances after posting" do
      expect {
        described_class.run!(entry: pending_entry)
      }.to change(Accounting::RunningBalance, :count).by(4) # 2 account + 2 ledger balances
    end

    it "rejects a posted entry" do
      posted_entry = Accounting::PostEntryService.run!(
        description: "Posted test entry",
        debits: [ { account: asset_account, amount: 5000 } ],
        credits: [ { account: liability_account, amount: 5000 } ],
        post_immediately: true
      )

      result = described_class.run(entry: posted_entry)
      expect(result).to be_invalid
      expect(result.errors[:entry]).to include("must be pending")
    end

    it "returns the entry" do
      result = described_class.run!(entry: pending_entry)
      expect(result).to eq(pending_entry)
    end
  end
end
