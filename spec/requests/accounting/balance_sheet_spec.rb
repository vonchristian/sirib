require "rails_helper"

RSpec.describe "Accounting::BalanceSheet" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/balance_sheet" do
    it "renders the balance sheet" do
      get accounting_balance_sheet_path
      expect(response).to have_http_status(:ok)
    end

    it "accepts as_of_date parameter" do
      get accounting_balance_sheet_path, params: { as_of_date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
    end

    it "accepts comparison parameter" do
      get accounting_balance_sheet_path, params: { comparison: "prior_period" }
      expect(response).to have_http_status(:ok)
    end

    it "handles invalid date gracefully" do
      get accounting_balance_sheet_path, params: { as_of_date: "invalid" }
      expect(response).to have_http_status(:ok)
    end
  end
end