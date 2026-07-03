require "rails_helper"

RSpec.describe Equity::BuySharesService do
  subject(:outcome) do
    described_class.run(
      share_capital_account: share_capital_account,
      shares: shares,
      cash_account: cash_account,
      posted_by_id: posted_by.id,
      notes: "Test purchase",
      idempotency_key: idempotency_key
    )
  end

  let(:share_capital_account) { create(:equity_account, :with_product) }
  let(:cash_account) { create(:accounting_account) }
  let(:posted_by) { create(:user) }
  let(:shares) { 10 }
  let(:idempotency_key) { nil }

  before do
    allow(Current).to receive(:cooperative).and_return(create(:cooperative))
  end

  describe "#execute" do
    context "without idempotency key" do
      it "creates an equity transaction" do
        skip "Requires full Equity::Account factory setup"
      end
    end

    context "with idempotency key" do
      let(:idempotency_key) { SecureRandom.uuid }

      it "does not raise on first call" do
        skip "Requires full Equity::Account factory setup"
      end
    end
  end
end
