require "rails_helper"

RSpec.describe IdempotencyKeysCleanupJob, type: :job do
  let(:cooperative) { create(:cooperative) }

  before do
    allow(Current).to receive(:cooperative).and_return(cooperative)
    create(:idempotency_key, key: "fresh", cooperative: cooperative, expires_at: 1.hour.from_now)
    create(:idempotency_key, key: "stale-a", cooperative: cooperative, expires_at: 1.hour.ago)
    create(:idempotency_key, key: "stale-b", cooperative: cooperative, expires_at: 2.hours.ago)
  end

  describe "#perform" do
    it "deletes expired idempotency keys" do
      expect { described_class.perform_now }.to change(IdempotencyKey, :count).by(-2)
    end

    it "keeps active (non-expired) keys" do
      described_class.perform_now
      expect(IdempotencyKey.pluck(:key)).to contain_exactly("fresh")
    end

    it "destroys expired records permanently" do
      described_class.perform_now
      expect(IdempotencyKey.where(key: %w[stale-a stale-b])).to be_empty
    end
  end
end
