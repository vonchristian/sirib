require "rails_helper"

RSpec.describe "Passwords" do
  describe "GET /passwords/new" do
    it "renders the forgot password page" do
      get new_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    context "when user exists" do
      let!(:user) { create(:user) }

      it "sends reset instructions" do
        post passwords_path, params: { email_address: user.email_address }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end

      it "enqueues a password reset email" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)
      end
    end

    context "when user does not exist" do
      it "redirects with a notice" do
        post passwords_path, params: { email_address: "nonexistent@example.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end

      it "does not enqueue an email" do
        expect {
          post passwords_path, params: { email_address: "nonexistent@example.com" }
        }.not_to have_enqueued_mail(PasswordsMailer, :reset)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    context "with valid token" do
      it "renders the reset password page" do
        user = create(:user)
        token = user.generate_password_reset_token
        get edit_password_path(token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid token" do
      it "redirects with an alert" do
        get edit_password_path("invalid-token")
        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /passwords/:token" do
    context "with valid token and matching passwords" do
      it "resets the password" do
        user = create(:user)
        token = user.generate_password_reset_token
        patch password_path(token), params: { password: "newpass123", password_confirmation: "newpass123" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with mismatched passwords" do
      it "redirects with an alert" do
        user = create(:user)
        token = user.generate_password_reset_token
        patch password_path(token), params: { password: "newpass123", password_confirmation: "different" }
        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to be_present
      end
    end
  end
end