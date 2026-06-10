require "rails_helper"

RSpec.describe Accounting::PostEntryService do
  describe "#execute" do
    let(:asset_account) { create(:accounting_account, account_type: :asset) }
    let(:liability_account) { create(:accounting_account, account_type: :liability) }

    it "creates an entry with debits and credits" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [{ account: asset_account, amount: 10000 }],
          credits: [{ account: liability_account, amount: 10000 }]
        )
      }.to change(Accounting::Entry, :count).by(1)
    end

    it "creates amount lines" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [{ account: asset_account, amount: 10000 }],
          credits: [{ account: liability_account, amount: 10000 }]
        )
      }.to change(Accounting::AmountLine, :count).by(2)
    end

    it "updates running balances" do
      expect {
        described_class.run!(
          description: "Test entry",
          debits: [{ account: asset_account, amount: 10000 }],
          credits: [{ account: liability_account, amount: 10000 }]
        )
      }.to change(Accounting::RunningBalance, :count).by(2)
    end

    it "returns the created entry" do
      result = described_class.run!(
        description: "Test entry",
        debits: [{ account: asset_account, amount: 10000 }],
        credits: [{ account: liability_account, amount: 10000 }]
      )
      expect(result).to be_a(Accounting::Entry)
    end

    it "accepts optional reference_number" do
      result = described_class.run!(
        description: "Test entry",
        reference_number: "CUSTOM-REF-001",
        debits: [{ account: asset_account, amount: 10000 }],
        credits: [{ account: liability_account, amount: 10000 }]
      )
      expect(result.reference_number).to eq("CUSTOM-REF-001")
    end
  end
end