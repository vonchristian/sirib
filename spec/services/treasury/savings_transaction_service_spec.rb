require "rails_helper"

RSpec.describe Treasury::SavingsTransactionService do
  subject(:outcome) do
    described_class.run(
      savings_account: savings_account,
      transaction_type: transaction_type,
      amount_cents: amount_cents,
      amount_currency: "PHP",
      cash_account: cash_account,
      notes: "Test",
      idempotency_key: idempotency_key
    )
  end

  let(:savings_account) { create(:savings_account) }
  let(:cash_account) { create(:accounting_account) }
  let(:amount_cents) { 1000 }
  let(:idempotency_key) { nil }
  let(:transaction_type) { "deposit" }

  before do
    allow(Current).to receive(:cooperative).and_return(create(:cooperative))
    allow(savings_account).to receive(:balance).and_return(Money.new(5000, "PHP"))
  end

  describe "#execute" do
    context "without idempotency key" do
      it "creates a savings transaction" do
        expect { outcome }.to change(Treasury::SavingsTransaction, :count).by(1)
      end
    end

    context "with idempotency key" do
      let(:idempotency_key) { SecureRandom.uuid }

      it "creates an IdempotencyKey record" do
        expect { outcome }.to change(IdempotencyKey, :count).by(1)
      end

      it "returns cached result on duplicate call" do
        first = outcome.result
        second = described_class.run(
          savings_account: savings_account,
          transaction_type: transaction_type,
          amount_cents: amount_cents,
          amount_currency: "PHP",
          cash_account: cash_account,
          notes: "Test",
          idempotency_key: idempotency_key
        )
        expect(second.result).to eq(first)
      end
    end
  end
end
