require "rails_helper"

RSpec.describe "Members" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /members/new" do
    it "renders the registration form" do
      get new_member_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Register Member")
    end
  end

  describe "POST /members" do
    let(:valid_params) do
      {
        member: {
          first_name: "Juan",
          last_name: "Dela Cruz",
          birth_date: "1994-06-15",
          gender: "male",
          civil_status: "single",
          mobile_number: "09171234567",
          address_attributes: {
            house_street: "123 Rizal St",
            barangay: "Barangay 1",
            city: "Manila",
            province: "Metro Manila",
            region: "NCR"
          },
          identifications_attributes: {
            "0" => { id_type: "BIR", id_number: "BIR-123-456" }
          }
        }
      }
    end

    it "creates a new member" do
      expect {
        post members_path, params: valid_params
      }.to change(Membership::Member, :count).by(1)
        .and change(Membership::Address, :count).by(1)
        .and change(Membership::Identification, :count).by(1)
    end

    it "redirects to the member page" do
      post members_path, params: valid_params
      expect(response).to redirect_to(member_path(Membership::Member.last))
    end

    it "re-renders form with errors on invalid data" do
      post members_path, params: { member: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects member without BIR identification" do
      params = valid_params
      params[:member][:identifications_attributes]["0"][:id_type] = "Passport"
      post members_path, params: params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("must include at least one BIR identification")
    end
  end

  describe "GET /members" do
    it "renders the index page" do
      create(:member)
      get members_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /members/:id" do
    it "renders the member page" do
      member = create(:member)
      get member_path(member)
      expect(response).to have_http_status(:ok)
    end
  end
end
