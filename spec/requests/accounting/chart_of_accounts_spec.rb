require "rails_helper"

RSpec.describe "Accounting::ChartOfAccounts" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let(:root_ledger) { create(:accounting_ledger, cooperative: cooperative, name: "Assets", account_code: "10000") }
  let(:child_ledger) { create(:accounting_ledger, cooperative: cooperative, parent: root_ledger, name: "Cash", account_code: "11000") }
  let(:account) { create(:accounting_account, cooperative: cooperative, ledger: child_ledger, name: "Cash on Hand", account_code: "11110") }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/chart_of_accounts" do
    it "renders the workbench page" do
      get accounting_chart_of_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chart of Accounts")
    end

    it "includes search input" do
      get accounting_chart_of_accounts_path
      expect(response.body).to include("Search account name, code, or ledger")
    end

    it "includes filter bar" do
      get accounting_chart_of_accounts_path
      expect(response.body).to include("Filters")
    end

    it "does not include tree panel" do
      get accounting_chart_of_accounts_path
      expect(response.body).not_to include("Ledger Tree")
    end

    it "includes accounts sorted by code" do
      a2 = create(:accounting_account, cooperative: cooperative, ledger: child_ledger, name: "Z Account", account_code: "99999")
      a1 = create(:accounting_account, cooperative: cooperative, ledger: child_ledger, name: "A Account", account_code: "11111")
      get accounting_chart_of_accounts_path
      body = response.body
      expect(body.index(a1.account_code)).to be < body.index(a2.account_code)
    end

    it "includes accounts in table" do
      account
      get accounting_chart_of_accounts_path
      expect(response.body).to include(CGI.escapeHTML(account.name))
      expect(response.body).to include(account.account_code)
    end

    it "shows empty state when no accounts" do
      get accounting_chart_of_accounts_path
      expect(response.body).to include("No accounts found")
    end
  end

  describe "GET /accounting/chart_of_accounts/search" do
    before do
      ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    rescue ActiveRecord::StatementInvalid
      skip "pg_trgm extension not available"
    end

    it "returns search results as HTML" do
      account
      get accounting_search_chart_of_accounts_path, params: { q: "Cash" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(account.name))
    end

    it "returns no results for non-matching query" do
      get accounting_search_chart_of_accounts_path, params: { q: "zzzzz" }
      expect(response.body).to include("No results found")
    end

    it "returns empty for blank query" do
      get accounting_search_chart_of_accounts_path, params: { q: "" }
      expect(response.body).to include("No results found")
    end
  end

  describe "GET /accounting/chart_of_accounts/accounts" do
    it "returns accounts table partial" do
      account
      get accounting_accounts_chart_of_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(account.name))
    end

    it "filters by account_type" do
      account
      create(:accounting_account, cooperative: cooperative, ledger: child_ledger, account_type: :liability, name: "Loan Payable")
      get accounting_accounts_chart_of_accounts_path, params: { account_type: "liability" }
      expect(response.body).to include("Loan Payable")
      expect(response.body).not_to include(CGI.escapeHTML(account.name))
    end

    it "filters by ledger_id" do
      other_ledger = create(:accounting_ledger, cooperative: cooperative)
      other_account = create(:accounting_account, cooperative: cooperative, ledger: other_ledger, name: "Other")
      account
      get accounting_accounts_chart_of_accounts_path, params: { ledger_id: other_ledger.id }
      expect(response.body).to include("Other")
      expect(response.body).not_to include(CGI.escapeHTML(account.name))
    end

    it "filters by search" do
      account
      create(:accounting_account, cooperative: cooperative, ledger: child_ledger, name: "Different")
      get accounting_accounts_chart_of_accounts_path, params: { search: "Cash" }
      expect(response.body).to include(CGI.escapeHTML(account.name))
      expect(response.body).not_to include("Different")
    end

    it "shows empty state when no accounts match" do
      get accounting_accounts_chart_of_accounts_path, params: { account_type: "revenue" }
      expect(response.body).to include("No accounts found")
    end

    it "includes link to account show page" do
      account
      get accounting_accounts_chart_of_accounts_path
      expect(response.body).to include(accounting_account_path(account))
    end
  end

  describe "authorization" do
    it "redirects unauthenticated users" do
      delete session_path
      get accounting_chart_of_accounts_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
