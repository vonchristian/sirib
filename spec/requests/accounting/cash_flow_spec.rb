require "rails_helper"

RSpec.describe "Accounting::CashFlow" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/cash_flow" do
    it "renders the cash flow statement" do
      get accounting_cash_flow_path
      expect(response).to have_http_status(:ok)
    end

    it "accepts date parameters" do
      get accounting_cash_flow_path, params: { from_date: 1.month.ago.to_date.to_s, to_date: Date.current.to_s }
      expect(response).to have_http_status(:ok)
    end

    it "handles invalid date gracefully" do
      get accounting_cash_flow_path, params: { from_date: "invalid" }
      expect(response).to have_http_status(:ok)
    end
  end
end
