require "rails_helper"

RSpec.describe External::BankDocument do
  describe "associations" do
    it { is_expected.to belong_to(:account).class_name("External::BankAccount") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:document_type) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:external_bank_document)).to be_valid
    end
  end

  describe "scopes" do
    describe ".pending_processing" do
      it "returns documents with pending status" do
        pending_doc = create(:external_bank_document, processing_status: "pending")
        create(:external_bank_document, processing_status: "parsed")

        expect(described_class.pending_processing).to contain_exactly(pending_doc)
      end
    end

    describe ".failed" do
      it "returns documents with failed status" do
        failed_doc = create(:external_bank_document, processing_status: "failed")
        create(:external_bank_document, processing_status: "parsed")

        expect(described_class.failed).to contain_exactly(failed_doc)
      end
    end
  end

  describe "#period" do
    it "returns formatted period string" do
      doc = build(:external_bank_document, period_start: Date.new(2025, 1, 1), period_end: Date.new(2025, 1, 31))

      expect(doc.period).to eq("Jan 01, 2025 - Jan 31, 2025")
    end

    it "returns nil when dates are missing" do
      doc = build(:external_bank_document, period_start: nil, period_end: nil)

      expect(doc.period).to be_nil
    end
  end

  describe "state transitions" do
    it "marks as processing" do
      doc = create(:external_bank_document, processing_status: "pending")
      doc.mark_as_processing!
      expect(doc.reload.processing_status).to eq("processing")
    end

    it "marks as parsed" do
      doc = create(:external_bank_document, processing_status: "processing")
      doc.mark_as_parsed!
      expect(doc.reload.processing_status).to eq("parsed")
    end

    it "marks as failed with error message" do
      doc = create(:external_bank_document, processing_status: "processing")
      doc.mark_as_failed!("Invalid CSV format")
      expect(doc.reload.processing_status).to eq("failed")
      expect(doc.reload.error_message).to eq("Invalid CSV format")
    end
  end
end