require "rails_helper"

RSpec.describe Treasury::TimeDeposit do
  describe "associations" do
    it { is_expected.to belong_to(:depositor) }
    it { is_expected.to belong_to(:time_deposit_product) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:amount_cents) }
    it { is_expected.to validate_numericality_of(:amount_cents).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:interest_rate) }
    it { is_expected.to validate_numericality_of(:interest_rate).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "scopes" do
    describe ".pending" do
      it "returns time deposits with pending status" do
        pending_deposit = create(:time_deposit, status: "pending")
        active_deposit = create(:time_deposit, status: "active")
        
        expect(described_class.pending).to contain_exactly(pending_deposit)
      end
    end

    describe ".active" do
      it "returns time deposits with active status" do
        pending_deposit = create(:time_deposit, status: "pending")
        active_deposit = create(:time_deposit, status: "active")
        
        expect(described_class.active).to contain_exactly(active_deposit)
      end
    end

    describe ".by_latest" do
      it "orders time deposits by created_at descending" do
        deposit1 = create(:time_deposit, created_at: 2.days.ago)
        deposit2 = create(:time_deposit, created_at: 1.day.ago)
        
        expect(described_class.by_latest).to eq([deposit2, deposit1])
      end
    end
  end

  describe "instance methods" do
    describe "#active?" do
      it "returns true when status is active" do
        deposit = described_class.new(status: "active")
        expect(deposit.active?).to be true
      end

      it "returns false when status is not active" do
        deposit = described_class.new(status: "pending")
        expect(deposit.active?).to be false
      end
    end
  end

  describe "class methods" do
    describe ".STATUSES" do
      it "defines expected statuses" do
        expect(described_class::STATUSES).to eq(%w[pending active matured closed])
      end
    end
  end
end