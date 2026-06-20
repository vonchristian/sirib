require "rails_helper"

RSpec.describe External::ParseBankDocumentJob do
  let(:account) { create(:external_bank_account) }
  let(:document) { create(:external_bank_document, account: account) }

  describe "#perform" do
    context "with valid CSV" do
      before do
        file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.csv"), "text/csv")
        document.file.attach(file)
      end

      it "creates transactions from CSV" do
        expect {
          described_class.perform_now(document)
        }.to change(External::BankTransaction, :count).by(5)
      end

      it "marks document as parsed" do
        described_class.perform_now(document)
        expect(document.reload.processing_status).to eq("parsed")
      end

      it "stores transaction count in metadata" do
        described_class.perform_now(document)
        expect(document.reload.metadata["transaction_count"]).to eq(5)
      end

      it "updates the account balance" do
        described_class.perform_now(document)
        expect(account.reload.current_balance_cents).to eq(132_000_00)
      end

      it "is idempotent on re-run" do
        described_class.perform_now(document)
        expect {
          described_class.perform_now(document)
        }.not_to change(External::BankTransaction, :count)
      end
    end

    context "with invalid CSV" do
      before do
        document.file.attach(io: StringIO.new(%{"unclosed quote}), filename: "bad.csv", content_type: "text/csv")
      end

      it "marks document as failed" do
        described_class.perform_now(document)
        expect(document.reload.processing_status).to eq("failed")
      end

      it "stores error message" do
        described_class.perform_now(document)
        expect(document.reload.error_message).to be_present
      end
    end

    context "without file" do
      it "marks document as failed" do
        described_class.perform_now(document)
        expect(document.reload.processing_status).to eq("failed")
      end
    end
  end
end