require "rails_helper"

RSpec.describe "Treasury::SavingsAccounts" do
  let(:user) { create(:user, password: "secret123", role: :treasurer) }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }

    # Create ledgers and accounts needed for savings
    @cash_ledger = Accounting::Ledger.find_or_create_by!(account_code: "11100") { |l| l.name = "Cash"; l.account_type = "asset" }
    @cash_account = Accounting::Account.find_or_create_by!(account_code: "11110") do |a|
      a.name = "Cash on Hand"; a.account_type = "asset"; a.ledger = @cash_ledger
    end
    Accounting::CashAccount.find_or_create_by!(user: user, account: @cash_account)

    @liability_ledger = Accounting::Ledger.find_or_create_by!(account_code: "21100") { |l| l.name = "Deposit Liabilities"; l.account_type = "liability" }
    @expense_ledger = Accounting::Ledger.find_or_create_by!(account_code: "61100") { |l| l.name = "Interest Expense"; l.account_type = "expense" }
  end

  let!(:product) do
    create(:savings_product,
      liability_ledger: @liability_ledger,
      interest_expense_ledger: @expense_ledger)
  end

  let!(:member) { create(:member) }

  describe "GET /treasury/savings_accounts" do
    it "renders the index" do
      get treasury_savings_accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Savings Accounts")
    end
  end

  describe "GET /treasury/savings_accounts/new" do
    it "renders the form" do
      get new_treasury_savings_account_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Open Savings Account")
    end
  end

  describe "POST /treasury/savings_accounts" do
    it "creates a savings account and auto-assigns liability/expense accounts" do
      expect {
        post treasury_savings_accounts_path, params: {
          treasury_savings_account: {
            savings_product_id: product.id,
            depositor_id: member.id,
            account_type: "personal"
          }
        }
      }.to change(Treasury::SavingsAccount, :count).by(1)

      account = Treasury::SavingsAccount.last
      expect(account.account_number).to be_present
      expect(account.liability_account).to be_present
      expect(account.interest_expense_account).to be_present
      expect(account.liability_account.account_type).to eq("liability")
      expect(account.interest_expense_account.account_type).to eq("expense")
      expect(response).to redirect_to(treasury_savings_account_path(account))
    end

    it "re-renders form with errors on invalid data" do
      post treasury_savings_accounts_path, params: { treasury_savings_account: { savings_product_id: nil } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Open Savings Account")
    end
  end

  describe "GET /treasury/savings_accounts/:id" do
    it "shows account details and transaction history" do
      account = create(:savings_account, savings_product: product, depositor: member)
      get treasury_savings_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.account_number)
      expect(response.body).to include("Deposit")
      expect(response.body).to include("Withdraw")
    end
  end

  describe "Deposit flow" do
    let(:account) { create(:savings_account, savings_product: product, depositor: member) }

    before do
      # Assign liability account
      code = "#{@liability_ledger.account_code}001"
      liability = @liability_ledger.accounts.create!(
        account_code: code, name: "#{product.name} Savings", account_type: "liability")
      account.update!(liability_account: liability)
    end

    it "GET deposit renders the deposit form" do
      get deposit_treasury_savings_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Amount")
      expect(response.body).to include("Cash on Hand Account")
    end

    it "POST preview_deposit shows preview on valid input" do
      post preview_deposit_treasury_savings_account_path(account),
        params: { amount_cents: "5000", cash_account_id: @cash_account.id, notes: "Test deposit" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Confirm Deposit")
      expect(response.body).to include("5,000.00")
    end

    it "POST preview_deposit re-renders form on invalid amount" do
      post preview_deposit_treasury_savings_account_path(account),
        params: { amount_cents: "0", cash_account_id: @cash_account.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Amount")
    end

    it "POST confirm_deposit executes the deposit" do
      expect {
        post confirm_deposit_treasury_savings_account_path(account),
          params: { amount_cents: "5000", cash_account_id: @cash_account.id, notes: "Deposit test" }
      }.to change(Treasury::SavingsTransaction, :count).by(1)

      expect(response).to redirect_to(treasury_savings_account_path(account))
      expect(flash[:notice]).to include("Deposit")
    end
  end

  describe "Withdraw flow" do
    let(:account) { create(:savings_account, savings_product: product, depositor: member) }

    before do
      code = "#{@liability_ledger.account_code}001"
      liability = @liability_ledger.accounts.create!(
        account_code: code, name: "#{product.name} Savings", account_type: "liability")
      account.update!(liability_account: liability)

      # Seed a 5000 PHP balance via a deposit
      Treasury::SavingsTransactionService.run!(
        savings_account: account,
        transaction_type: "deposit",
        amount_cents: 500000,
        amount_currency: "PHP",
        cash_account: @cash_account,
        notes: "Initial deposit"
      )
    end

    it "GET withdraw renders the withdraw form" do
      get withdraw_treasury_savings_account_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Amount")
      expect(response.body).to include("Available:")
    end

    it "POST preview_withdraw shows preview on valid input" do
      post preview_withdraw_treasury_savings_account_path(account),
        params: { amount_cents: "3000", cash_account_id: @cash_account.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Confirm Withdrawal")
    end

    it "POST preview_withdraw rejects amount exceeding balance" do
      post preview_withdraw_treasury_savings_account_path(account),
        params: { amount_cents: "10000", cash_account_id: @cash_account.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Insufficient")
    end

    it "POST confirm_withdraw executes the withdrawal" do
      expect {
        post confirm_withdraw_treasury_savings_account_path(account),
          params: { amount_cents: "3000", cash_account_id: @cash_account.id, notes: "Withdraw test" }
      }.to change(Treasury::SavingsTransaction, :count).by(1)

      expect(response).to redirect_to(treasury_savings_account_path(account))
      expect(flash[:notice]).to include("Withdrawal")
    end
  end
end
