require "rails_helper"

RSpec.describe "Accounting::EntryTemplates", type: :request do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /accounting/entry_templates" do
    it "returns success" do
      get accounting_entry_templates_path
      expect(response).to have_http_status(:ok)
    end
  end
end
