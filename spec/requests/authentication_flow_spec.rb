require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "protected pages" do
    it "redirects to sign in" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "stores return URL after authentication" do
      get dashboard_loans_path
      expect(session[:return_to_after_authenticating]).to eq(dashboard_loans_url)
    end
  end

  describe "after authentication" do
    let(:user) { create(:user, password: "secret123") }

    it "redirects to stored return URL" do
      get dashboard_loans_path
      post session_path, params: { email_address: user.email_address, password: "secret123" }
      expect(response).to redirect_to(dashboard_loans_path)
    end

    it "redirects to role dashboard when no stored URL" do
      post session_path, params: { email_address: user.email_address, password: "secret123" }
      expect(response).to redirect_to(manager_dashboard_path)
    end
  end
end
