require "rails_helper"

RSpec.describe Treasury::OpenTimeDepositService do
  subject(:outcome) do
    described_class.run(
      depositor: depositor,
      product: product,
      amount_cents: amount_cents,
      amount_currency: "PHP"
    )
  end

  let(:depositor) { create(:user, password: "secret123") }
  let(:product) { create(:time_deposit_product, interest_rate: 0.035, term_in_days: 30, minimum_deposit_cents: 1_000_00) }
  let(:amount_cents) { 10_000_00 }

  before do
    Accounting::Account.find_or_create_by!(account_code: "11110") do |a|
      a.name = "Cash on Hand"
      a.account_type = "asset"
      a.ledger = Accounting::Ledger.find_or_create_by!(name: "Cash", account_type: "asset", account_code: "11100")
    end
    Accounting::Account.find_or_create_by!(account_code: "21120") do |a|
      a.name = "Time Deposits"
      a.account_type = "liability"
      a.ledger = Accounting::Ledger.find_or_create_by!(name: "Deposit Liabilities", account_type: "liability", account_code: "21100")
    end
  end

  describe "#execute" do
    it "creates a time deposit" do
      expect { outcome }.to change(Treasury::TimeDeposit, :count).by(1)
    end

    it "posts a journal entry" do
      expect { outcome }.to change(Accounting::Entry, :count).by(1)
    end

    it "sets the deposit status to active" do
      expect(outcome.result.status).to eq("active")
    end

    it "sets the correct amount" do
      expect(outcome.result.amount_cents).to eq(10_000_00)
    end

    context "when the minimum deposit is not met" do
      let(:amount_cents) { 500_00 }

      it "is invalid" do
        expect(outcome).to be_invalid
      end

      it "does not create a deposit" do
        expect { outcome }.not_to change(Treasury::TimeDeposit, :count)
      end

      it "does not post a journal entry" do
        expect { outcome }.not_to change(Accounting::Entry, :count)
      end
    end

    context "with zero amount" do
      let(:amount_cents) { 0 }

      it "is invalid" do
        expect(outcome).to be_invalid
      end
    end
  end
end
