require "rails_helper"

RSpec.describe "Accounting::Entries" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let(:ledger) { create(:accounting_ledger, cooperative: cooperative) }
  let(:account) { create(:accounting_account, cooperative: cooperative, ledger: ledger) }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/entries/new" do
    it "renders the new entry page" do
      get new_accounting_entry_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /accounting/entries" do
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
      expect(response).to redirect_to(accounting_journal_entry_path(Accounting::Entry.last))
    end

    it "updates running balances synchronously" do
      expect(Accounting::UpdateRunningBalances).to receive(:run!).with(entry: instance_of(Accounting::Entry))
      post accounting_entries_path, params: { entry: entry_params }
    end

    it "re-renders new on failure" do
      post accounting_entries_path, params: { entry: { description: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "with invalid amount_lines" do
      it "handles blank account_id" do
        params = entry_params.merge(amount_lines_attributes: [ { account_id: "", direction: "debit", amount_cents: "0" } ])
        post accounting_entries_path, params: { entry: params }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
