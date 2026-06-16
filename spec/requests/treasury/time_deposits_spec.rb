require "rails_helper"

RSpec.describe "Treasury::TimeDeposits" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }

    Accounting::Account.find_or_create_by!(account_code: "11110") do |a|
      a.name = "Cash on Hand"
      a.account_type = "asset"
      a.ledger = Accounting::Ledger.find_or_create_by!(name: "Cash", account_type: "asset", account_code: "11100")
    end

    Accounting::Account.find_or_create_by!(account_code: "21120") do |a|
      a.name = "Time Deposits"
      a.account_type = "liability"
      a.ledger = Accounting::Ledger.find_or_create_by!(name: "Deposit Liabilities", account_type: "liability", account_code: "21100")
    end
  end

  describe "GET /treasury/time_deposits" do
    it "returns a successful response" do
      get treasury_time_deposits_path
      expect(response).to be_successful
    end
  end

  describe "GET /treasury/time_deposits/new" do
    it "returns a successful response" do
      get new_treasury_time_deposit_path
      expect(response).to be_successful
    end
  end

  describe "POST /treasury/time_deposits/preview" do
    let(:product) { create(:time_deposit_product) }

    it "returns a successful response with valid params" do
      post preview_treasury_time_deposits_path, params: { product_id: product.id, amount_cents: 10_000_00 }
      expect(response).to be_successful
    end
  end

  describe "POST /treasury/time_deposits" do
    let(:product) { create(:time_deposit_product) }

    it "creates a new time deposit and posts a journal entry" do
      expect {
        post treasury_time_deposits_path, params: {
          time_deposit: {
            time_deposit_product_id: product.id,
            amount_cents: 10_000_00,
            amount_currency: "PHP"
          }
        }
      }.to change(Treasury::TimeDeposit, :count).by(1)
        .and change(Accounting::Entry, :count).by(1)

      expect(response).to redirect_to(treasury_time_deposit_path(Treasury::TimeDeposit.last))
    end
  end

  describe "GET /treasury/time_deposits/:id" do
    it "returns a successful response" do
      deposit = create(:time_deposit, depositor: user)
      get treasury_time_deposit_path(deposit)
      expect(response).to be_successful
    end
  end
end
