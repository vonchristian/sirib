require "rails_helper"

RSpec.describe BusinessEventLogger do
  let(:resource) { double("Resource", class: double(name: "Loan"), id: 42) }

  describe ".log" do
    it "logs a structured business event" do
      expected_info = {
        event: "business",
        service: "LendingService",
        action: "loan_disbursed",
        resource_type: "Loan",
        resource_id: 42
      }

      expect(Rails.logger).to receive(:info).with(hash_including(expected_info))
      described_class.log(service: "LendingService", action: "loan_disbursed", resource: resource)
    end

    it "includes metadata in the log output" do
      expect(Rails.logger).to receive(:info).with(hash_including(
        metadata: { amount: 100_000, currency: "PHP" }
      ))
      described_class.log(
        service: "LendingService",
        action: "loan_disbursed",
        resource: resource,
        metadata: { amount: 100_000, currency: "PHP" }
      )
    end

    it "handles logging failures gracefully" do
      allow(Rails.logger).to receive(:info).and_raise("disk full")

      expect(Rails.logger).to receive(:error).with(hash_including(
        event: "business_logging_error",
        error_message: "disk full"
      ))
      described_class.log(service: "Test", action: "test", resource: resource)
    end
  end
end
