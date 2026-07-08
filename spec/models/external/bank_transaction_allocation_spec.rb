require "rails_helper"

RSpec.describe External::BankTransactionAllocation do
  describe "associations" do
    it { is_expected.to belong_to(:bank_transaction).class_name("External::BankTransaction") }
    it { is_expected.to belong_to(:journal_entry).class_name("Accounting::Entry").optional }
    it { is_expected.to belong_to(:created_by).class_name("User").optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:allocated_amount) }
    it { is_expected.to validate_presence_of(:allocated_amount_cents) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:external_bank_transaction_allocation)).to be_valid
    end
  end

  describe "scopes" do
    describe ".confirmed" do
      it "returns confirmed allocations" do
        confirmed = create(:external_bank_transaction_allocation, status: "confirmed")
        create(:external_bank_transaction_allocation, status: "suggested")

        expect(described_class.confirmed).to contain_exactly(confirmed)
      end
    end

    describe ".suggested" do
      it "returns suggested allocations" do
        suggested = create(:external_bank_transaction_allocation, status: "suggested")
        create(:external_bank_transaction_allocation, status: "confirmed")

        expect(described_class.suggested).to contain_exactly(suggested)
      end
    end

    describe ".rejected" do
      it "returns rejected allocations" do
        rejected = create(:external_bank_transaction_allocation, status: "rejected")
        create(:external_bank_transaction_allocation, status: "confirmed")

        expect(described_class.rejected).to contain_exactly(rejected)
      end
    end
  end

  describe "#allocated_amount_money" do
    it "returns a Money object" do
      allocation = build(:external_bank_transaction_allocation, allocated_amount_cents: 750_00, allocated_amount_currency: "PHP")

      expect(allocation.allocated_amount_money).to be_a(Money)
      expect(allocation.allocated_amount_money.cents).to eq(750_00)
    end
  end

  describe "state transitions" do
    it "confirms an allocation" do
      allocation = create(:external_bank_transaction_allocation, status: "suggested")
      allocation.confirm!
      expect(allocation.reload.status).to eq("confirmed")
    end

    it "rejects an allocation" do
      allocation = create(:external_bank_transaction_allocation, status: "suggested")
      allocation.reject!
      expect(allocation.reload.status).to eq("rejected")
    end
  end

  describe ".audit_message" do
    it "builds an audit message hash" do
      allocation = create(:external_bank_transaction_allocation)
      message = described_class.audit_message("confirmed", allocation)

      expect(message[:action]).to eq("confirmed")
      expect(message[:transaction_id]).to eq(allocation.external_bank_transaction_id)
      expect(message[:status]).to eq(allocation.status)
    end
  end
end
