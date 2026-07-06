require "rails_helper"

RSpec.describe Banking::TransactionService do
  let(:cooperative) { create(:cooperative) }

  before do
    allow(Current).to receive(:cooperative).and_return(cooperative)
    allow(BroadcastService).to receive(:transaction_posted)
  end

  describe ".debit" do
    subject(:result) do
      described_class.debit(
        amount: Money.new(1000, "PHP"),
        from_account: from_account,
        to_account: to_account,
        cash_session: cash_session,
        description: "Test debit",
        idempotency_key: idempotency_key
      )
    end

    let(:from_account) { create(:accounting_account) }
    let(:to_account) { create(:accounting_account) }
    let(:cash_session) { instance_double(Treasury::CashSession, open?: true, id: 1) }
    let(:idempotency_key) { nil }

    before do
      allow(from_account).to receive(:balance).and_return(Money.new(100_000, "PHP"))
    end

    it "returns a successful result" do
      expect(result).to be_valid
    end

    it "creates an accounting entry" do
      expect { result }.to change(Accounting::Entry, :count).by(1)
    end

    context "with idempotency key" do
      let(:idempotency_key) { SecureRandom.uuid }

      it "creates an IdempotencyKey record" do
        expect { result }.to change(IdempotencyKey, :count).by(1)
      end

      it "returns cached result on duplicate call" do
        first = result
        second = described_class.debit(
          amount: Money.new(1000, "PHP"),
          from_account: from_account,
          to_account: to_account,
          cash_session: cash_session,
          description: "Test debit",
          idempotency_key: idempotency_key
        )
        expect(second.transaction.entry).to eq(first.transaction.entry)
      end

      it "does not create a duplicate entry on second call" do
        result
        expect {
          described_class.debit(
            amount: Money.new(1000, "PHP"),
            from_account: from_account,
            to_account: to_account,
            cash_session: cash_session,
            description: "Test debit",
            idempotency_key: idempotency_key
          )
        }.not_to change(Accounting::Entry, :count)
      end
    end
  end

  describe ".debit without sufficient balance" do
    subject(:result) do
      described_class.debit(
        amount: Money.new(1_000_000, "PHP"),
        from_account: from_account,
        to_account: to_account,
        cash_session: cash_session,
        description: "Overdraft test",
        idempotency_key: nil
      )
    end

    let(:from_account) { create(:accounting_account) }
    let(:to_account) { create(:accounting_account) }
    let(:cash_session) { instance_double(Treasury::CashSession, open?: true, id: 1) }

    before do
      allow(from_account).to receive(:balance).and_return(Money.new(100, "PHP"))
    end

    it "returns an unsuccessful result" do
      expect(result).not_to be_valid
      expect(result.errors).to include("Insufficient balance")
    end
  end

  describe ".credit" do
    subject(:result) do
      described_class.credit(
        amount: Money.new(1000, "PHP"),
        to_account: to_account,
        from_account: source_account,
        cash_session: cash_session,
        description: "Test credit",
        idempotency_key: idempotency_key
      )
    end

    let(:to_account) { create(:accounting_account) }
    let(:source_account) { create(:accounting_account) }
    let(:cash_session) { instance_double(Treasury::CashSession, open?: true, id: 1) }
    let(:idempotency_key) { nil }

    it "returns a successful result" do
      expect(result).to be_valid
    end

    it "creates an accounting entry" do
      expect { result }.to change(Accounting::Entry, :count).by(1)
    end

    context "with idempotency key" do
      let(:idempotency_key) { SecureRandom.uuid }

      it "creates an IdempotencyKey record" do
        expect { result }.to change(IdempotencyKey, :count).by(1)
      end
    end
  end
end
