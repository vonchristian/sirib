require "rails_helper"
require "ostruct"

RSpec.describe IdempotentService do
  let(:fake_service) do
    Class.new do
      def self.name
        "FakeIdempotentService"
      end
      include IdempotentService

      def perform(key: nil)
        with_idempotency(key: key) do
          OpenStruct.new(id: SecureRandom.uuid, saved: true)
        end
      end

      def perform_with_resource(key: nil)
        with_idempotency(key: key) do
          FactoryBot.create(:accounting_entry,
            posted_at: Time.current,
            description: "Idempotency test entry",
            source_module: "source_manual",
            created_by: nil)
        end
      end
    end
  end

  subject(:service) { fake_service.new }

  before do
    allow(Current).to receive(:cooperative).and_return(cooperative)
  end

  let(:cooperative) { create(:cooperative) }

  describe "#with_idempotency" do
    context "when no key is provided" do
      it "yields the block" do
        result = service.perform
        expect(result.saved).to be true
      end

      it "does not create an IdempotencyKey record" do
        expect { service.perform }.not_to change(IdempotencyKey, :count)
      end
    end

    context "when a key is provided" do
      let(:key) { SecureRandom.uuid }

      context "on first request" do
        it "yields the block" do
          result = service.perform_with_resource(key: key)
          expect(result).to be_a(Accounting::Entry)
        end

        it "creates an IdempotencyKey record" do
          expect { service.perform_with_resource(key: key) }.to change(IdempotencyKey, :count).by(1)
        end

        it "associates the key with the result" do
          result = service.perform_with_resource(key: key)
          record = IdempotencyKey.find_by(key: key)
          expect(record.resource).to eq(result)
        end

        it "sets the correct service name" do
          service.perform_with_resource(key: key)
          record = IdempotencyKey.find_by(key: key)
          expect(record.service).to eq(fake_service.name)
        end
      end

      context "on duplicate request" do
        let!(:existing_entry) { service.perform_with_resource(key: key) }

        it "returns the cached resource instead of yielding" do
          expect { |b| service.with_idempotency(key: key, &b) }.not_to yield_control
        end

        it "returns the same resource" do
          result = service.perform_with_resource(key: key)
          expect(result).to eq(existing_entry)
        end

        it "does not create a second IdempotencyKey record" do
          expect { service.perform_with_resource(key: key) }.not_to change(IdempotencyKey, :count)
        end
      end

      context "with an expired key" do
        it "yields the block again" do
          create(:idempotency_key, key: key, cooperative: cooperative, expires_at: 1.hour.ago, resource: nil)
          expect(IdempotencyKey.active.find_by(key: key)).to be_nil
          expect { |b| service.with_idempotency(key: key, &b) }.to yield_control
        end
      end
    end
  end
end
