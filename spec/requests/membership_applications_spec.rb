require "rails_helper"

RSpec.describe "MembershipApplications" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /membership_applications/new" do
    it "creates a draft application and redirects to edit" do
      expect {
        get new_membership_application_path
      }.to change(MembershipApplication, :count).by(1)

      app = MembershipApplication.last
      expect(app.status).to eq("draft")
      expect(response).to redirect_to(edit_membership_application_path(app.uuid))
    end
  end

  describe "GET /membership_applications/:uuid/edit" do
    it "renders the form for an existing application" do
      app = create(:membership_application)
      get edit_membership_application_path(app.uuid)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Personal Details")
    end

    it "renders the specified step when ?step=N is given" do
      app = create(:membership_application)
      get edit_membership_application_path(app.uuid, step: "identifications")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Step 3: Identifications")
    end

    it "falls back to the saved current_step when no ?step param" do
      app = create(:membership_application, current_step: 3)
      get edit_membership_application_path(app.uuid)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Step 4: Signature Specimens")
    end
  end

  describe "PATCH /membership_applications/:uuid" do
    it "updates the application and saves progress" do
      app = create(:membership_application, first_name: nil)
      patch membership_application_path(app.uuid), params: {
        membership_application: { first_name: "Pedro" }
      }
      expect(response).to redirect_to(edit_membership_application_path(app.uuid, step: "personal_details"))
      expect(app.reload.first_name).to eq("Pedro")
    end
  end

  describe "GET /membership_applications" do
    it "renders the index" do
      create(:membership_application)
      get membership_applications_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /membership_applications/:uuid" do
    it "renders the show page" do
      app = create(:membership_application)
      get membership_application_path(app.uuid)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /membership_applications/:uuid/download_pdf" do
    it "returns a PDF file" do
      app = create(:membership_application)
      get download_pdf_membership_application_path(app.uuid)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
      expect(response.header["Content-Disposition"]).to include("membership_application_")
    end
  end

  describe "POST /membership_applications/:uuid/approve" do
    it "approves a complete application and creates a member" do
      app = create(:membership_application, status: "completed")

      expect {
        post approve_membership_application_path(app.uuid)
      }.to change(Member, :count).by(1)
        .and change(MemberAddress, :count).by(1)
        .and change(MemberIdentification, :count).by(1)

      expect(app.reload.status).to eq("approved")
      expect(response).to redirect_to(member_path(Member.last))
    end

    it "rejects incomplete applications" do
      app = create(:membership_application, status: "draft", first_name: nil)
      post approve_membership_application_path(app.uuid)
      expect(response).to redirect_to(membership_application_path(app.uuid))
      expect(flash[:alert]).to be_present
    end
  end
end
