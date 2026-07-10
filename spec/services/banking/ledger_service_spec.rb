require "rails_helper"

RSpec.describe Banking::LedgerService do
  let(:cooperative) { create(:cooperative) }
  let(:ledger) { create(:accounting_ledger, cooperative: cooperative) }
  let(:account) { create(:accounting_account, ledger: ledger, cooperative: cooperative) }
  let(:account2) { create(:accounting_account, ledger: ledger, cooperative: cooperative) }

  before do
    allow(Current).to receive(:cooperative).and_return(cooperative)
    allow(BroadcastService).to receive(:entry_posted)
  end

  describe ".post_entry" do
    subject(:result) do
      described_class.post_entry(
        description: "Test ledger entry",
        lines: [
          { account: account, amount_cents: 1000, amount_type: "debit" },
          { account: account2, amount_cents: 1000, amount_type: "credit" }
        ]
      )
    end

    it "returns a successful result" do
      expect(result).to be_valid
    end

    it "creates an accounting entry" do
      expect { result }.to change(Accounting::Entry, :count).by(1)
    end

    it "creates amount lines" do
      expect { result }.to change(Accounting::AmountLine, :count).by(2)
    end

    it "sets the entry status to posted" do
      expect(result.entry.status).to eq("posted")
    end

    it "delegates validation to ValidationEngine" do
      expect(Accounting::ValidationEngine).to receive(:validate!).and_call_original
      result
    end

    it "records an audit log" do
      expect(Management::AuditLogService).to receive(:run!).with(
        hash_including(action: "ledger_entry_posted")
      ).and_call_original
      result
    end

    it "broadcasts via BroadcastService" do
      expect(BroadcastService).to receive(:entry_posted)
      result
    end

    context "with invalid lines" do
      subject(:result) do
        described_class.post_entry(
          description: "Unbalanced entry",
          lines: [
            { account: account, amount_cents: 1000, amount_type: "debit" }
          ]
        )
      end

      it "returns an unsuccessful result" do
        expect(result).not_to be_valid
      end

      it "does not create an entry" do
        expect { result }.not_to change(Accounting::Entry, :count)
      end
    end

    context "with unbalanced lines" do
      subject(:result) do
        described_class.post_entry(
          description: "Unbalanced entry",
          lines: [
            { account: account, amount_cents: 1000, amount_type: "debit" },
            { account: account2, amount_cents: 500, amount_type: "credit" }
          ]
        )
      end

      it "returns an unsuccessful result" do
        expect(result).not_to be_valid
      end
    end
  end

  describe ".account_balance" do
    let!(:entry) do
      described_class.post_entry(
        description: "Balance test",
        lines: [
          { account: account, amount_cents: 5000, amount_type: "debit" },
          { account: account2, amount_cents: 5000, amount_type: "credit" }
        ]
      )
    end

    it "returns account balance hash" do
      result = described_class.account_balance(account.id)
      expect(result).to be_a(Hash)
      expect(result).to include(:account, :balance, :as_of)
    end

    it "returns the account name" do
      result = described_class.account_balance(account.id)
      expect(result[:account]).to eq(account.name)
    end

    context "when account does not exist" do
      it "returns an error result" do
        result = described_class.account_balance(0)
        expect(result).not_to be_valid
        expect(result.errors).to be_present
      end
    end
  end
end
