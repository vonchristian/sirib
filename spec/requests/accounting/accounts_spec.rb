require "rails_helper"

RSpec.describe "Accounting::Accounts" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let(:ledger) { create(:accounting_ledger, cooperative: cooperative, name: "General Ledger") }
  let(:account) { create(:accounting_account, ledger: ledger, cooperative: cooperative, name: "Cash on Hand") }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  def with_cooperative
    Current.set(cooperative: cooperative) { yield }
  end

  describe "GET /accounting/accounts/:id" do
    it "renders the show page" do
      get accounting_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(account.name))
      expect(response.body).to include(account.account_code)
    end

    it "includes account header with metadata" do
      get accounting_account_path(account)
      expect(response.body).to include(account.account_code)
      expect(response.body).to include(CGI.escapeHTML(account.ledger.name))
      expect(response.body).to include(account.account_type) # CSS capitalize class used
      expect(response.body).to include("Normal: Debit")
    end

    it "includes tab navigation" do
      get accounting_account_path(account)
      expect(response.body).to include("Overview")
      expect(response.body).to include("Transactions")
      expect(response.body).to include("Audit Trail")
    end

    it "includes balance snapshot section" do
      get accounting_account_path(account)
      expect(response.body).to include("Balance Snapshot")
    end

    it "includes account details section" do
      get accounting_account_path(account)
      expect(response.body).to include("Account Details")
    end

    it "includes filter panel" do
      get accounting_account_path(account)
      expect(response.body).to include("Filters")
    end

    it "shows ledger table with headers when account has entries" do
      with_cooperative do
        entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
        entry.amount_lines.first.update!(account: account, cooperative: cooperative)
        entry.amount_lines.last.update!(account: account, cooperative: cooperative)
      end

      get accounting_account_path(account)
      expect(response.body).to include("Debit")
      expect(response.body).to include("Credit")
      expect(response.body).to include("Running Balance")
    end

    it "shows empty state when account has no transactions" do
      get accounting_account_path(account)
      expect(response.body).to include("No ledger activity")
    end

    it "includes audit trail section" do
      get accounting_account_path(account)
      expect(response.body).to include("Audit Trail")
      expect(response.body).to include("Account ID")
    end

    it "shows table when account has entries" do
      with_cooperative do
        entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
        entry.amount_lines.first.update!(account: account, cooperative: cooperative)
        entry.amount_lines.last.update!(account: account, cooperative: cooperative)
      end

      get accounting_account_path(account)
      expect(response.body).to include("Debit")
      expect(response.body).to include("Credit")
    end

    context "with date filters" do
      it "returns ok with date range params" do
        with_cooperative do
          entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.zone.now)
          entry.amount_lines.first.update!(account: account, cooperative: cooperative)
        end

        get accounting_account_path(account, from_date: 1.month.ago.to_date, to_date: Date.current)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with quick range filter" do
      it "returns ok with year_to_date" do
        get accounting_account_path(account, quick_range: "year_to_date")
        expect(response).to have_http_status(:ok)
      end
    end

    context "with direction filter" do
      it "returns ok with debit direction" do
        with_cooperative do
          entry = create(:accounting_entry, cooperative: cooperative)
          debit_line = entry.amount_lines.where(amount_type: :debit).first
          debit_line&.update!(account: account, cooperative: cooperative)
        end

        get accounting_account_path(account, direction: "debit")
        expect(response).to have_http_status(:ok)
      end
    end

    context "with sort order" do
      it "supports descending order" do
        get accounting_account_path(account, sort: "desc")
        expect(response).to have_http_status(:ok)
      end

      it "supports ascending order" do
        get accounting_account_path(account, sort: "asc")
        expect(response).to have_http_status(:ok)
      end
    end

    it "returns 404 for non-existent account" do
      get accounting_account_path(id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /accounting/accounts/search" do
    before do
      ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    rescue ActiveRecord::StatementInvalid
      skip "pg_trgm extension not available"
    end

    it "returns search results when query is present" do
      create(:accounting_account, ledger: ledger, cooperative: cooperative, name: "Cash")
      get accounting_accounts_search_path, params: { q: "Cash" }
      expect(response).to have_http_status(:ok)
    end

    it "returns no results when query is blank" do
      get accounting_accounts_search_path, params: { q: "" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "authorization" do
    it "redirects unauthenticated users" do
      delete session_path
      get accounting_account_path(account)
      expect(response).to redirect_to(new_session_path)
    end
  end
end
