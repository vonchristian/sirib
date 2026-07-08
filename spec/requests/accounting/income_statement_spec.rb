require "rails_helper"

RSpec.describe "Accounting::IncomeStatement" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/income_statement" do
    it "renders the income statement" do
      get accounting_income_statement_path
      expect(response).to have_http_status(:ok)
    end

    it "accepts comparison parameter" do
      get accounting_income_statement_path, params: { comparison: "prior_year" }
      expect(response).to have_http_status(:ok)
    end

    it "handles invalid date gracefully" do
      get accounting_income_statement_path, params: { as_of_date: "invalid" }
      expect(response).to have_http_status(:ok)
    end
  end
end
