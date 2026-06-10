require "rails_helper"

RSpec.describe "Sessions" do
  describe "GET /session/new" do
    it "renders the sign in page" do
      get new_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /session" do
    let!(:user) { create(:user, password: "secret123") }

    context "with valid credentials" do
      it "signs the user in and redirects" do
        post session_path, params: { email_address: user.email_address, password: "secret123" }
        expect(response).to redirect_to(root_path)
        expect(cookies[:session_id]).to be_present
      end

      it "creates a session record" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "secret123" }
        }.to change(Session, :count).by(1)
      end
    end

    context "with invalid credentials" do
      it "redirects with an alert" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to be_present
      end

      it "does not create a session" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong" }
        }.not_to change(Session, :count)
      end
    end
  end

  describe "DELETE /session" do
    it "signs the user out" do
      user = create(:user, password: "secret123")
      post session_path, params: { email_address: user.email_address, password: "secret123" }
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the session record" do
      user = create(:user, password: "secret123")
      post session_path, params: { email_address: user.email_address, password: "secret123" }
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end
  end
end