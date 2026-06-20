require "rails_helper"

RSpec.describe "External::Banks" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /external/banks" do
    it "returns a successful response" do
      get external_banks_path
      expect(response).to be_successful
    end

    it "lists banks" do
      create(:external_bank, name: "BDO")
      get external_banks_path
      expect(response.body).to include("BDO")
    end
  end

  describe "GET /external/banks/new" do
    it "returns a successful response" do
      get new_external_bank_path
      expect(response).to be_successful
    end
  end

  describe "POST /external/banks" do
    it "creates a bank" do
      expect {
        post external_banks_path, params: { external_bank: { name: "Metrobank", country: "Philippines" } }
      }.to change(External::Bank, :count).by(1)

      expect(response).to redirect_to(external_bank_path(External::Bank.last))
    end

    it "renders new on validation failure" do
      expect {
        post external_banks_path, params: { external_bank: { name: "" } }
      }.not_to change(External::Bank, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /external/banks/:id" do
    it "returns a successful response" do
      bank = create(:external_bank)
      get external_bank_path(bank)
      expect(response).to be_successful
    end
  end

  describe "GET /external/banks/:id/edit" do
    it "returns a successful response" do
      bank = create(:external_bank)
      get edit_external_bank_path(bank)
      expect(response).to be_successful
    end
  end

  describe "PATCH /external/banks/:id" do
    it "updates the bank" do
      bank = create(:external_bank)
      patch external_bank_path(bank), params: { external_bank: { name: "Updated Bank" } }
      expect(bank.reload.name).to eq("Updated Bank")
      expect(response).to redirect_to(external_bank_path(bank))
    end

    it "renders edit on validation failure" do
      bank = create(:external_bank)
      patch external_bank_path(bank), params: { external_bank: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /external/banks/:id" do
    it "deactivates the bank" do
      bank = create(:external_bank, status: "active")
      delete external_bank_path(bank)
      expect(bank.reload.status).to eq("inactive")
      expect(response).to redirect_to(external_banks_path)
    end
  end
end