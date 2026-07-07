require "rails_helper"

RSpec.describe Accounting::PostEntryService do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe "#execute" do
    let(:asset_account) { create(:accounting_account, account_type: :asset, cooperative: cooperative) }
    let(:liability_account) { create(:accounting_account, account_type: :liability, cooperative: cooperative) }

    it "creates an entry with debits and credits" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [ { account: asset_account, amount: 10000 } ],
          credits: [ { account: liability_account, amount: 10000 } ]
        )
      }.to change(Accounting::Entry, :count).by(1)
    end

    it "creates amount lines" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [ { account: asset_account, amount: 10000 } ],
          credits: [ { account: liability_account, amount: 10000 } ]
        )
      }.to change(Accounting::AmountLine, :count).by(2)
    end

    it "updates running balances when post_immediately is true" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [ { account: asset_account, amount: 10000 } ],
          credits: [ { account: liability_account, amount: 10000 } ],
          post_immediately: true
        )
      }.to change(Accounting::RunningBalance, :count).by(4) # 2 account + 2 ledger balances
    end

    it "does not update running balances when post_immediately is false" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [ { account: asset_account, amount: 10000 } ],
          credits: [ { account: liability_account, amount: 10000 } ],
          post_immediately: false
        )
      }.not_to change(Accounting::RunningBalance, :count)
    end

    it "creates a pending entry when post_immediately is false" do
      result = described_class.run!(
        description: "Test entry",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ],
        post_immediately: false
      )
      expect(result).to be_pending
    end

    it "creates a posted entry when post_immediately is true (default)" do
      result = described_class.run!(
        description: "Test entry",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_posted
    end

    it "returns the created entry" do
      result = described_class.run!(
        description: "Test entry",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_a(Accounting::Entry)
    end

    it "accepts optional reference_number" do
      result = described_class.run!(
        description: "Test entry",
        reference_number: "CUSTOM-REF-001",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result.reference_number).to eq("CUSTOM-REF-001")
    end
  end
end
