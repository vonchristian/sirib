require "rails_helper"

RSpec.describe "Management::EntryTemplates" do
  let(:user) { create(:user, password: "secret123") }
  let(:debit_account) { create(:accounting_account) }
  let(:credit_account) { create(:accounting_account) }

  before do
    host! "main.lvh.me"
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /management/entry_templates" do
    it "returns a successful response" do
      get management_entry_templates_path
      expect(response).to be_successful
    end

    it "lists templates" do
      create(:accounting_entry_template, name: "Interest Earned")
      get management_entry_templates_path
      expect(response.body).to include("Interest Earned")
    end
  end

  describe "GET /management/entry_templates/new" do
    it "returns a successful response" do
      get new_management_entry_template_path
      expect(response).to be_successful
    end
  end

  describe "POST /management/entry_templates" do
    it "creates a template" do
      post management_entry_templates_path, params: {
        accounting_entry_template: {
          name: "Test Template",
          lines_attributes: {
            "0" => { account_id: debit_account.id, direction: "debit", amount_mode: "variable", sequence_index: 1 },
            "1" => { account_id: credit_account.id, direction: "credit", amount_mode: "variable", sequence_index: 2 }
          }
        }
      }
      expect(response).to redirect_to(management_entry_template_path(Accounting::EntryTemplate.last))
      expect(Accounting::EntryTemplate.last.name).to eq("Test Template")
    end

    it "renders new on validation failure" do
      post management_entry_templates_path, params: { accounting_entry_template: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /management/entry_templates/:id" do
    it "returns a successful response" do
      template = create(:accounting_entry_template)
      get management_entry_template_path(template)
      expect(response).to be_successful
    end
  end

  describe "GET /management/entry_templates/:id/edit" do
    it "returns a successful response" do
      template = create(:accounting_entry_template)
      get edit_management_entry_template_path(template)
      expect(response).to be_successful
    end
  end

  describe "PATCH /management/entry_templates/:id" do
    it "updates the template" do
      template = create(:accounting_entry_template)
      patch management_entry_template_path(template), params: {
        accounting_entry_template: { name: "Updated Name" }
      }
      expect(template.reload.name).to eq("Updated Name")
      expect(response).to redirect_to(management_entry_template_path(template))
    end
  end

  describe "POST /management/entry_templates/:id/preview" do
    it "returns preview HTML" do
      template = create(:accounting_entry_template)
      post preview_management_entry_template_path(template), params: { amount: 10_000 }
      expect(response).to be_successful
    end
  end

  describe "POST /management/entry_templates/:id/execute" do
    it "creates a journal entry" do
      template = create(:accounting_entry_template)
      expect {
        post execute_management_entry_template_path(template), params: { amount: 10_000 }
      }.to change(Accounting::Entry, :count).by(1)
      expect(response).to redirect_to(management_entry_template_path(template))
    end
  end
end
