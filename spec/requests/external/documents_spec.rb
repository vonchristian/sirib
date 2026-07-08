require "rails_helper"

RSpec.describe "External::Documents" do
  let(:user) { create(:user, password: "secret123") }
  let(:bank) { create(:external_bank) }
  let(:account) { create(:external_bank_account, bank: bank) }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /external/banks/:bank_id/accounts/:account_id/documents" do
    it "returns a successful response" do
      get external_bank_account_documents_path(bank, account)
      expect(response).to be_successful
    end

    it "lists documents" do
      doc = create(:external_bank_document, account: account)
      doc.file.attach(io: StringIO.new("date,amount\n2025-01-01,1000"), filename: "statement.csv", content_type: "text/csv")
      get external_bank_account_documents_path(bank, account)
      expect(response.body).to include("statement.csv")
    end
  end

  describe "GET /external/banks/:bank_id/accounts/:account_id/documents/new" do
    it "returns a successful response" do
      get new_external_bank_account_document_path(bank, account)
      expect(response).to be_successful
    end
  end

  describe "POST /external/banks/:bank_id/accounts/:account_id/documents" do
    it "creates a document with file" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.csv"), "text/csv")

      expect {
        post external_bank_account_documents_path(bank, account), params: {
          external_bank_document: {
            file: file,
            document_type: "statement",
            period_start: Date.current.beginning_of_month,
            period_end: Date.current
          }
        }
      }.to change(External::BankDocument, :count).by(1)

      expect(response).to redirect_to(external_bank_account_documents_path(bank, account))
    end

    it "enqueues parse job" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.csv"), "text/csv")

      expect {
        post external_bank_account_documents_path(bank, account), params: {
          external_bank_document: {
            file: file,
            document_type: "statement",
            period_start: Date.current.beginning_of_month,
            period_end: Date.current
          }
        }
      }.to have_enqueued_job(External::ParseBankDocumentJob)
    end

    it "renders new on validation failure" do
      expect {
        post external_bank_account_documents_path(bank, account), params: {
          external_bank_document: { document_type: "" }
        }
      }.not_to change(External::BankDocument, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /external/banks/:bank_id/accounts/:account_id/documents/:id" do
    it "returns a successful response" do
      doc = create(:external_bank_document, account: account)
      get external_bank_account_document_path(bank, account, doc)
      expect(response).to be_successful
    end
  end

  describe "DELETE /external/banks/:bank_id/accounts/:account_id/documents/:id" do
    it "deletes the document" do
      doc = create(:external_bank_document, account: account, processing_status: "pending")
      expect {
        delete external_bank_account_document_path(bank, account, doc)
      }.to change(External::BankDocument, :count).by(-1)

      expect(response).to redirect_to(external_bank_account_documents_path(bank, account))
    end
  end
end
