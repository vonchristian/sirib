require "rails_helper"

RSpec.describe "Sessions" do
  let(:user_agent) { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" }

  describe "GET /session/new" do
    it "renders the sign in page" do
      host! "main.lvh.me"
      get new_session_path, headers: { "HTTP_USER_AGENT" => user_agent }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /session" do
    let!(:user) { create(:user, password: "secret123") }

    context "with valid credentials" do
      it "signs the user in and redirects" do
        host! "main.lvh.me"
        post session_path, params: { email_address: user.email_address, password: "secret123" }, headers: { "HTTP_USER_AGENT" => user_agent }
        expect(response).to redirect_to(manager_dashboard_path)
        expect(cookies[:session_id]).to be_present
      end

      it "creates a session record" do
        host! "main.lvh.me"
        expect {
          post session_path, params: { email_address: user.email_address, password: "secret123" }, headers: { "HTTP_USER_AGENT" => user_agent }
        }.to change(Session, :count).by(1)
      end
    end

    context "with invalid credentials" do
      it "redirects with an alert" do
        host! "main.lvh.me"
        post session_path, params: { email_address: user.email_address, password: "wrong" }, headers: { "HTTP_USER_AGENT" => user_agent }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to be_present
      end

      it "does not create a session" do
        host! "main.lvh.me"
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong" }, headers: { "HTTP_USER_AGENT" => user_agent }
        }.not_to change(Session, :count)
      end
    end
  end

  describe "DELETE /session" do
    it "signs the user out" do
      host! "main.lvh.me"
      user = create(:user, password: "secret123")
      post session_path, params: { email_address: user.email_address, password: "secret123" }, headers: { "HTTP_USER_AGENT" => user_agent }
      delete session_path, headers: { "HTTP_USER_AGENT" => user_agent }
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the session record" do
      host! "main.lvh.me"
      user = create(:user, password: "secret123")
      post session_path, params: { email_address: user.email_address, password: "secret123" }, headers: { "HTTP_USER_AGENT" => user_agent }
      expect {
        delete session_path, headers: { "HTTP_USER_AGENT" => user_agent }
      }.to change(Session, :count).by(-1)
    end
  end
end
