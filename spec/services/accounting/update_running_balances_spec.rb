require "rails_helper"

RSpec.describe Accounting::UpdateRunningBalances do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe "#execute" do
    it "updates account running balances" do
      entry = create(:accounting_entry, cooperative: cooperative)
      expect {
        described_class.run!(entry:)
      }.to change(Accounting::RunningBalance, :count).by_at_least(1)
    end

    it "locks accounts with FOR UPDATE" do
      entry = create(:accounting_entry, cooperative: cooperative)
      expect(Accounting::Account).to receive(:lock).with("FOR UPDATE").and_call_original
      described_class.run!(entry:)
    end

    it "locks running balance rows with FOR UPDATE" do
      entry = create(:accounting_entry, cooperative: cooperative)
      expect(Accounting::RunningBalance).to receive(:lock).with("FOR UPDATE").at_least(:once).and_call_original
      described_class.run!(entry:)
    end
  end
end
