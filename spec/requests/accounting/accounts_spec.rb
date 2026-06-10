require "rails_helper"

RSpec.describe "Accounting::Accounts" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/accounts/search" do
    it "returns search results when query is present" do
      create(:accounting_account, name: "Cash")
      get accounting_accounts_search_path, params: { q: "Cash" }
      expect(response).to have_http_status(:ok)
    end

    it "returns no results when query is blank" do
      get accounting_accounts_search_path, params: { q: "" }
      expect(response).to have_http_status(:ok)
    end
  end
end