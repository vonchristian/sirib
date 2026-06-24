require "rails_helper"

RSpec.describe "Loans::RestructureCases" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /loans/restructure_cases" do
    it "renders the index with cases" do
      create(:lending_loan_restructure_case, cooperative: cooperative)
      get loans_restructure_cases_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:lending_loan_restructure_case, cooperative: cooperative, status: "approved")
      get loans_restructure_cases_path, params: { status: "approved" }
      expect(response).to have_http_status(:ok)
    end

    it "filters by type" do
      create(:lending_loan_restructure_case, cooperative: cooperative, restructure_type: "refinance")
      get loans_restructure_cases_path, params: { type: "refinance" }
      expect(response).to have_http_status(:ok)
    end

    it "shows empty state when no cases exist" do
      get loans_restructure_cases_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No restructure cases found")
    end
  end

  describe "GET /loans/restructure_cases/:id" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative) }

    it "renders the show page" do
      get loans_restructure_case_path(restructure_case)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Restructure Case")
    end

    it "returns 404 for nonexistent case" do
      get loans_restructure_case_path(id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
