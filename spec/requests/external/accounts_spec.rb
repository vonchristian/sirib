require "rails_helper"

RSpec.describe "External::Accounts" do
  let(:user) { create(:user, password: "secret123") }
  let(:bank) { create(:external_bank) }
  let(:account_params) do
    { account_name: "Operating Account", account_number_encrypted: "12345678", account_type: "checking", currency: "PHP" }
  end

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /external/banks/:bank_id/accounts" do
    it "returns a successful response" do
      get external_bank_accounts_path(bank)
      expect(response).to be_successful
    end

    it "lists accounts" do
      create(:external_bank_account, bank: bank, account_name: "Payroll")
      get external_bank_accounts_path(bank)
      expect(response.body).to include("Payroll")
    end
  end

  describe "GET /external/banks/:bank_id/accounts/new" do
    it "returns a successful response" do
      get new_external_bank_account_path(bank)
      expect(response).to be_successful
    end
  end

  describe "POST /external/banks/:bank_id/accounts" do
    it "creates an account" do
      expect {
        post external_bank_accounts_path(bank), params: { external_bank_account: account_params }
      }.to change(External::BankAccount, :count).by(1)

      expect(response).to redirect_to(external_bank_account_path(bank, External::BankAccount.last))
    end

    it "renders new on validation failure" do
      expect {
        post external_bank_accounts_path(bank), params: { external_bank_account: { account_name: "" } }
      }.not_to change(External::BankAccount, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /external/banks/:bank_id/accounts/:id" do
    it "returns a successful response" do
      account = create(:external_bank_account, bank: bank)
      get external_bank_account_path(bank, account)
      expect(response).to be_successful
    end

    it "shows recent transactions" do
      account = create(:external_bank_account, bank: bank)
      create(:external_bank_transaction, account: account, description: "ATM Withdrawal")

      get external_bank_account_path(bank, account)
      expect(response.body).to include("ATM Withdrawal")
    end
  end

  describe "GET /external/banks/:bank_id/accounts/:id/edit" do
    it "returns a successful response" do
      account = create(:external_bank_account, bank: bank)
      get edit_external_bank_account_path(bank, account)
      expect(response).to be_successful
    end
  end

  describe "PATCH /external/banks/:bank_id/accounts/:id" do
    it "updates the account" do
      account = create(:external_bank_account, bank: bank)
      patch external_bank_account_path(bank, account), params: { external_bank_account: { account_name: "Updated Name" } }
      expect(account.reload.account_name).to eq("Updated Name")
      expect(response).to redirect_to(external_bank_account_path(bank, account))
    end
  end

  describe "DELETE /external/banks/:bank_id/accounts/:id" do
    it "deactivates the account" do
      account = create(:external_bank_account, bank: bank, status: "active")
      delete external_bank_account_path(bank, account)
      expect(account.reload.status).to eq("inactive")
      expect(response).to redirect_to(external_bank_accounts_path(bank))
    end
  end
end
