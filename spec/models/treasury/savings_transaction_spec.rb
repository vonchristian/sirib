require "rails_helper"

RSpec.describe Treasury::SavingsTransaction do
  describe "associations" do
    it { is_expected.to belong_to(:savings_account) }
    it { is_expected.to belong_to(:cash_account).class_name("Accounting::Account") }
    it { is_expected.to belong_to(:entry).class_name("Accounting::Entry").optional }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending completed failed]) }

    it "validates uniqueness of reference_number" do
      create(:savings_transaction, reference_number: "SD-UNIQUE")
      txn = build(:savings_transaction, reference_number: "SD-UNIQUE")
      expect(txn).not_to be_valid
      expect(txn.errors[:reference_number]).to be_present
    end
  end

  describe "#transaction_type enum" do
    it "defines deposit and withdraw" do
      expect(Treasury::SavingsTransaction::TRANSACTION_TYPES).to eq(deposit: 0, withdraw: 1)
    end
  end

  describe "#reference_number" do
    it "auto-assigns SD prefix for deposits" do
      txn = build(:savings_transaction, transaction_type: :deposit, reference_number: nil)
      txn.valid?
      expect(txn.reference_number).to match(/\ASD-\d{8}-[A-F0-9]{6}\z/)
    end

    it "auto-assigns SW prefix for withdrawals" do
      txn = build(:savings_transaction, transaction_type: :withdraw, reference_number: nil)
      txn.valid?
      expect(txn.reference_number).to match(/\ASW-\d{8}-[A-F0-9]{6}\z/)
    end
  end
end
