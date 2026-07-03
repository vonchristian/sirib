require "rails_helper"

RSpec.describe "Lending::LoanAging" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let(:branch) { create(:branch, cooperative: cooperative) }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /lending/loan_aging" do
    it "renders the dashboard" do
      get lending_loan_aging_path
      expect(response).to have_http_status(:ok)
    end

    it "includes summary cards" do
      get lending_loan_aging_path
      expect(response.body).to include("Total Portfolio")
      expect(response.body).to include("Delinquent")
      expect(response.body).to include("PAR30")
    end

    context "with active loans" do
      let!(:delinquent_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "1-30 Days", min_days: 1, max_days: 30) }
      let!(:current_group) { create(:lending_loan_aging_group, cooperative: cooperative, name: "Current", min_days: 0, max_days: 0) }
      let!(:loan) { create(:lending_loan, cooperative: cooperative, status: "active", outstanding_principal_cents: 50_000_00) }

      before do
        create(:lending_loan_repayment_schedule, cooperative: cooperative,
          loan_application: loan.loan_application, sequence: 1,
          due_date: 15.days.ago, principal_cents: 10_000_00, interest_cents: 1_500_00)
        Lending::AgingCalculationService.call(loan: loan)
      end

      it "shows portfolio data" do
        get lending_loan_aging_path
        expect(response.body).to include("PHP 50,000")
      end
    end

    context "with filters" do
      it "filters by loan_aging_group_id" do
        group = create(:lending_loan_aging_group, cooperative: cooperative, name: "Over 180 Days", min_days: 181, max_days: nil)
        get lending_loan_aging_path, params: { loan_aging_group_id: group.id }
        expect(response).to have_http_status(:ok)
      end

      it "filters by min_dpd" do
        get lending_loan_aging_path, params: { min_dpd: 30 }
        expect(response).to have_http_status(:ok)
      end

      it "filters by max_dpd" do
        get lending_loan_aging_path, params: { max_dpd: 90 }
        expect(response).to have_http_status(:ok)
      end

      it "clears filters" do
        get lending_loan_aging_path, params: { loan_aging_group_id: "", min_dpd: "", max_dpd: "" }
        expect(response).to have_http_status(:ok)
      end
    end

    it "redirects unauthenticated user to login" do
      delete session_path
      get lending_loan_aging_path
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_session_path)
    end

    it "responds to turbo_stream" do
      get lending_loan_aging_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
