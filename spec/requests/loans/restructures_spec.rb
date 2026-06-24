require "rails_helper"

RSpec.describe "Loans::Restructures" do
  let(:cooperative) { create(:cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let(:loan) { create(:lending_loan, cooperative: cooperative, status: "active", restructures_count: 0, max_restructures: 2) }

  before do
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /loans/restructures/new" do
    it "renders the new form" do
      get new_loans_restructure_path(loan_id: loan.id, type: "modification")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Modification Restructure")
    end

    it "rejects invalid types" do
      get new_loans_restructure_path(loan_id: loan.id, type: "invalid")
      expect(response).to redirect_to(restructure_loans_loan_path(loan))
      expect(flash[:alert]).to be_present
    end

    it "returns 404 for nonexistent loan" do
      get new_loans_restructure_path(loan_id: 999_999, type: "modification")
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /loans/restructures" do
    let(:valid_params) do
      {
        lending_loan_restructure_case: {
          restructure_type: "modification",
          notes: "Test restructure",
          proposed_changes: { interest_rate: "1.0", term_months: "18" }
        },
        loan_id: loan.id
      }
    end

    it "creates a restructure case" do
      expect {
        post loans_restructures_path, params: valid_params
      }.to change(Lending::LoanRestructureCase, :count).by(1)
    end

    it "redirects to show page" do
      post loans_restructures_path, params: valid_params
      expect(response).to redirect_to(loans_restructure_path(Lending::LoanRestructureCase.last))
    end

    it "re-renders form on invalid params" do
      post loans_restructures_path, params: { lending_loan_restructure_case: { restructure_type: "", notes: "" }, loan_id: loan.id }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "when loan cannot be restructured" do
      let(:loan) { create(:lending_loan, cooperative: cooperative, status: "paid", restructures_count: 0, max_restructures: 2) }

      it "shows an error" do
        post loans_restructures_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "GET /loans/restructures/:id" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan) }

    it "renders the show page" do
      get loans_restructure_path(restructure_case)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Restructure Case")
    end

    it "returns 404 for nonexistent case" do
      get loans_restructure_path(id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /loans/restructures/:id/submit" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan, status: "draft") }

    it "submits the case" do
      post submit_loans_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_submitted
      expect(response).to redirect_to(loans_restructure_path(restructure_case))
    end
  end

  describe "POST /loans/restructures/:id/approve" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan, status: "submitted") }

    it "approves the case" do
      post approve_loans_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_approved
      expect(response).to redirect_to(loans_restructure_path(restructure_case))
    end
  end

  describe "POST /loans/restructures/:id/reject" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan, status: "submitted") }

    it "rejects the case" do
      post reject_loans_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_rejected
      expect(response).to redirect_to(loans_restructure_path(restructure_case))
    end

    it "accepts a reason" do
      post reject_loans_restructure_path(restructure_case), params: { reason: "Insufficient collateral" }
      expect(restructure_case.reload).to be_rejected
      expect(flash[:notice]).to be_present
    end
  end

  describe "POST /loans/restructures/:id/execute" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan, status: "approved", restructure_type: "modification") }

    it "executes the case" do
      post execute_loans_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_executed
      expect(response).to redirect_to(loans_restructure_path(restructure_case))
    end

    context "when case is not approved" do
      let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, loan: loan, status: "draft") }

      it "redirects with alert" do
        post execute_loans_restructure_path(restructure_case)
        expect(response).to redirect_to(loans_restructure_path(restructure_case))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "POST /loans/restructures/simulate" do
    it "returns HTML simulation" do
      post simulate_loans_restructures_path(loan_id: loan.id, type: "modification",
        lending_loan_restructure_case: { proposed_changes: { interest_rate: "1.0", term_months: "18" } })
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON simulation" do
      post simulate_loans_restructures_path(loan_id: loan.id, type: "modification",
        lending_loan_restructure_case: { proposed_changes: { interest_rate: "1.0", term_months: "18" } },
        format: :json)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end

    context "with invalid loan" do
      it "returns error" do
        post simulate_loans_restructures_path(loan_id: 999_999, type: "modification",
          lending_loan_restructure_case: { proposed_changes: {} })
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
