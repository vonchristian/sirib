require "rails_helper"

RSpec.describe IdempotencyKey, type: :model do
  subject(:idempotency_key) { build(:idempotency_key, cooperative: cooperative) }

  let(:cooperative) { create(:cooperative) }

  before do
    allow(Current).to receive(:cooperative).and_return(cooperative)
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:service) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:resource).optional }
  end

  describe "cooperative scoping" do
    it "requires a cooperative" do
      allow(Current).to receive(:cooperative).and_return(nil)
      record = build(:idempotency_key, cooperative: nil)
      record.valid?
      expect(record.errors[:cooperative]).to include("must exist")
    end

    it "enforces unique key per cooperative" do
      create(:idempotency_key, key: "uniq-key", cooperative: cooperative)
      dup = build(:idempotency_key, key: "uniq-key", cooperative: cooperative)
      expect(dup).not_to be_valid
      expect(dup.errors[:key]).to include("has already been taken")
    end

    it "allows same key across cooperatives" do
      another_coop = create(:cooperative, name: "Another Coop")
      create(:idempotency_key, key: "cross-key", cooperative: cooperative)
      expect {
        create(:idempotency_key, key: "cross-key", cooperative: another_coop)
      }.not_to raise_error
    end
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_key) { create(:idempotency_key, key: "active-key", cooperative: cooperative, expires_at: 1.hour.from_now) }
      let!(:expired_key) { create(:idempotency_key, key: "expired-key", cooperative: cooperative, expires_at: 1.hour.ago) }

      it "returns only non-expired keys" do
        expect(described_class.active).to include(active_key)
        expect(described_class.active).not_to include(expired_key)
      end
    end

    describe ".expired" do
      let!(:active_key) { create(:idempotency_key, key: "active-key", cooperative: cooperative, expires_at: 1.hour.from_now) }
      let!(:expired_key) { create(:idempotency_key, key: "expired-key", cooperative: cooperative, expires_at: 1.hour.ago) }

      it "returns only expired keys" do
        expect(described_class.expired).to include(expired_key)
        expect(described_class.expired).not_to include(active_key)
      end
    end
  end

  describe "unique index across cooperatives" do
    let(:another_coop) { create(:cooperative, name: "Another Coop") }
    let(:key) { "same-key" }

    before do
      create(:idempotency_key, key: key, cooperative: cooperative)
    end

    it "allows the same key in different cooperatives" do
      expect {
        create(:idempotency_key, key: key, cooperative: another_coop)
      }.not_to raise_error
    end

    it "prevents duplicate key in same cooperative" do
      expect {
        create(:idempotency_key, key: key, cooperative: cooperative)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
