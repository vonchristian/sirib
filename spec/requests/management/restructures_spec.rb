require "rails_helper"

RSpec.describe "Management::Restructures" do
  let(:cooperative) { create(:cooperative) }
  let(:branch) { create(:branch, cooperative: cooperative) }
  let(:user) { create(:user, password: "secret123", cooperative: cooperative) }
  let!(:role) { Management::Role.create!(cooperative: cooperative, name: "Manager", code: "test_manager", rank: 10) }
  let!(:permission) { Management::Permission.create!(cooperative: cooperative, action: "approve", subject: "loan_restructure") }
  let!(:role_permission) { Management::RolePermission.create!(role: role, permission: permission, cooperative: cooperative) }
  let!(:role_assignment) {
    Management::RoleAssignment.create!(
      user: user, role: role, branch: branch, cooperative: cooperative, active_from: Date.current
    )
  }

  before do
    host! "main.lvh.me"
    Current.cooperative = cooperative
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /management/restructures" do
    it "renders the index" do
      create(:lending_loan_restructure_case, cooperative: cooperative)
      get management_restructures_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      create(:lending_loan_restructure_case, cooperative: cooperative, status: "approved")
      get management_restructures_path, params: { status: "approved" }
      expect(response).to have_http_status(:ok)
    end

    it "shows stat counts" do
      create(:lending_loan_restructure_case, cooperative: cooperative, status: "submitted")
      create(:lending_loan_restructure_case, cooperative: cooperative, status: "approved")
      get management_restructures_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /management/restructures/:id" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative) }

    it "renders the show page" do
      get management_restructure_path(restructure_case)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for nonexistent case" do
      get management_restructure_path(id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /management/restructures/:id/approve" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, status: "submitted") }

    it "approves the case" do
      post approve_management_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_approved
      expect(response).to redirect_to(management_restructure_path(restructure_case))
    end
  end

  describe "POST /management/restructures/:id/reject" do
    let(:restructure_case) { create(:lending_loan_restructure_case, cooperative: cooperative, status: "submitted") }

    it "rejects the case" do
      post reject_management_restructure_path(restructure_case)
      expect(restructure_case.reload).to be_rejected
      expect(response).to redirect_to(management_restructure_path(restructure_case))
    end

    it "accepts a reason" do
      post reject_management_restructure_path(restructure_case), params: { reason: "Policy violation" }
      expect(restructure_case.reload).to be_rejected
      expect(flash[:notice]).to be_present
    end
  end
end
