require "rails_helper"

RSpec.describe External::BankTransaction do
  describe "associations" do
    it { is_expected.to belong_to(:account).class_name("External::BankAccount") }
    it { is_expected.to belong_to(:document).class_name("External::BankDocument").optional }
    it { is_expected.to have_many(:allocations).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:external_bank_transaction) }

    it { is_expected.to validate_presence_of(:transaction_date) }
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:direction) }
    it { is_expected.to validate_presence_of(:hash_signature) }
    it { is_expected.to validate_uniqueness_of(:hash_signature) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:external_bank_transaction)).to be_valid
    end
  end

  describe "scopes" do
    describe ".unreconciled" do
      it "returns transactions without allocations" do
        tx = create(:external_bank_transaction)
        allocated_tx = create(:external_bank_transaction)
        create(:external_bank_transaction_allocation, bank_transaction: allocated_tx)

        expect(described_class.unreconciled).to contain_exactly(tx)
      end
    end

    describe ".by_date" do
      it "orders by date ascending" do
        older = create(:external_bank_transaction, transaction_date: 5.days.ago)
        newer = create(:external_bank_transaction, transaction_date: 1.day.ago)

        expect(described_class.by_date).to eq([older, newer])
      end
    end

    describe ".by_date_desc" do
      it "orders by date descending" do
        older = create(:external_bank_transaction, transaction_date: 5.days.ago)
        newer = create(:external_bank_transaction, transaction_date: 1.day.ago)

        expect(described_class.by_date_desc).to eq([newer, older])
      end
    end
  end

  describe "instance methods" do
    describe "#amount_money" do
      it "returns a Money object" do
        tx = build(:external_bank_transaction, amount_cents: 500_00, amount_currency: "PHP")

        expect(tx.amount_money).to be_a(Money)
        expect(tx.amount_money.cents).to eq(500_00)
      end
    end

    describe "#running_balance_money" do
      it "returns a Money object when balance present" do
        tx = build(:external_bank_transaction, running_balance_cents: 1000_00, running_balance_currency: "PHP")

        expect(tx.running_balance_money).to be_a(Money)
        expect(tx.running_balance_money.cents).to eq(1000_00)
      end

      it "returns nil when balance is nil" do
        tx = build(:external_bank_transaction, running_balance_cents: nil)

        expect(tx.running_balance_money).to be_nil
      end
    end

    describe "#reconciled?" do
      it "returns true when confirmed allocations exist" do
        tx = create(:external_bank_transaction)
        create(:external_bank_transaction_allocation, bank_transaction: tx, status: "confirmed")

        expect(tx.reconciled?).to be true
      end

      it "returns false when no confirmed allocations exist" do
        tx = create(:external_bank_transaction)

        expect(tx.reconciled?).to be false
      end
    end

    describe "#reconciled_amount" do
      it "sums confirmed allocation amounts" do
        tx = create(:external_bank_transaction)
        create(:external_bank_transaction_allocation, bank_transaction: tx, status: "confirmed", allocated_amount_cents: 300_00)
        create(:external_bank_transaction_allocation, bank_transaction: tx, status: "confirmed", allocated_amount_cents: 200_00)
        create(:external_bank_transaction_allocation, bank_transaction: tx, status: "suggested", allocated_amount_cents: 100_00)

        expect(tx.reconciled_amount).to eq(500_00)
      end
    end
  end

  describe ".generate_hash_signature" do
    it "generates a deterministic hash" do
      sig1 = described_class.generate_hash_signature(
        account_id: 1, transaction_date: Date.new(2025, 6, 1),
        description: "Payment", amount: "1000.00", direction: "credit"
      )
      sig2 = described_class.generate_hash_signature(
        account_id: 1, transaction_date: Date.new(2025, 6, 1),
        description: "Payment", amount: "1000.00", direction: "credit"
      )

      expect(sig1).to eq(sig2)
      expect(sig1).to be_a(String)
      expect(sig1.length).to eq(64)
    end

    it "generates different hashes for different data" do
      sig1 = described_class.generate_hash_signature(
        account_id: 1, transaction_date: Date.new(2025, 6, 1),
        description: "Payment A", amount: "1000.00", direction: "credit"
      )
      sig2 = described_class.generate_hash_signature(
        account_id: 1, transaction_date: Date.new(2025, 6, 1),
        description: "Payment B", amount: "1000.00", direction: "credit"
      )

      expect(sig1).not_to eq(sig2)
    end
  end
end