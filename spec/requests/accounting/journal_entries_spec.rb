require "rails_helper"

RSpec.describe "Accounting::JournalEntries", type: :request do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/journal_entries" do
    it "returns success" do
      get accounting_journal_entries_path
      expect(response).to have_http_status(:ok)
    end

    it "lists journal entries" do
      create(:accounting_entry)
      get accounting_journal_entries_path
      expect(response.body).to include("Journal Entries")
    end
  end

  describe "GET /accounting/journal_entries/new" do
    it "returns success" do
      get new_accounting_journal_entry_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /accounting/journal_entries/:id" do
    it "shows the entry" do
      entry = create(:accounting_entry)
      get accounting_journal_entry_path(entry)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(entry.reference_number)
    end
  end

  describe "POST /accounting/journal_entries/preview" do
    it "returns error for missing template" do
      post preview_accounting_journal_entries_path,
        params: { template_id: 0, amount: 1000 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /accounting/journal_entries" do
    it "redirects with error for missing template" do
      post accounting_journal_entries_path,
        params: { template_id: 0, amount: 5000 }
      expect(response).to have_http_status(:not_found)
    end
  end
end
