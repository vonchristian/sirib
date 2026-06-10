require "rails_helper"

RSpec.describe "Accounting::Entries" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/entries" do
    it "renders the index page" do
      get accounting_entries_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by search query" do
      create(:accounting_entry_with_debits_and_credits, description: "Special entry")
      get accounting_entries_path, params: { q: "Special" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by date range" do
      create(:accounting_entry_with_debits_and_credits, posted_at: 5.days.ago)
      get accounting_entries_path, params: { from_date: 3.days.ago.to_date.to_s, to_date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
    end

    it "responds with CSV" do
      create(:accounting_entry_with_debits_and_credits)
      get accounting_entries_path, params: { format: :csv }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include(".csv")
    end
  end

  describe "GET /accounting/entries/new" do
    it "renders the new entry page" do
      get new_accounting_entry_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /accounting/entries" do
    let(:account) { create(:accounting_account) }
    let(:entry_params) do
      {
        description: "Test entry",
        amount_lines_attributes: [
          { account_id: account.id, direction: "debit", amount_cents: "100.00" },
          { account_id: account.id, direction: "credit", amount_cents: "100.00" }
        ]
      }
    end

    it "creates an entry" do
      expect {
        post accounting_entries_path, params: { entry: entry_params }
      }.to change(Accounting::Entry, :count).by(1)
    end

    it "redirects to the entry on success" do
      post accounting_entries_path, params: { entry: entry_params }
      expect(response).to redirect_to(accounting_entry_path(Accounting::Entry.last))
    end

    it "enqueues running balance update job" do
      expect {
        post accounting_entries_path, params: { entry: entry_params }
      }.to have_enqueued_job(Accounting::UpdateRunningBalancesJob)
    end

    it "re-renders new on failure" do
      post accounting_entries_path, params: { entry: { description: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "with invalid amount_lines" do
      it "handles blank account_id" do
        params = entry_params.merge(amount_lines_attributes: [{ account_id: "", direction: "debit", amount_cents: "0" }])
        post accounting_entries_path, params: { entry: params }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /accounting/entries/:id" do
    it "shows the entry" do
      entry = create(:accounting_entry_with_debits_and_credits)
      get accounting_entry_path(entry)
      expect(response).to have_http_status(:ok)
    end
  end
end