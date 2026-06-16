require "rails_helper"

RSpec.describe "Treasury::TimeDepositProducts" do
  let(:user) { create(:user, password: "secret123") }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /treasury/time_deposit_products" do
    it "returns a successful response" do
      create(:time_deposit_product)
      get treasury_time_deposit_products_path
      expect(response).to be_successful
    end
  end

  describe "GET /treasury/time_deposit_products/new" do
    it "returns a successful response" do
      get new_treasury_time_deposit_product_path
      expect(response).to be_successful
    end
  end

  describe "POST /treasury/time_deposit_products" do
    it "creates a new time deposit product" do
      expect {
        post treasury_time_deposit_products_path, params: {
          time_deposit_product: attributes_for(:time_deposit_product)
        }
      }.to change(Treasury::TimeDepositProduct, :count).by(1)

      expect(response).to redirect_to(treasury_time_deposit_product_path(Treasury::TimeDepositProduct.last))
    end
  end

  describe "GET /treasury/time_deposit_products/:id" do
    it "returns a successful response" do
      product = create(:time_deposit_product)
      get treasury_time_deposit_product_path(product)
      expect(response).to be_successful
    end
  end

  describe "PATCH /treasury/time_deposit_products/:id" do
    it "updates the time deposit product" do
      product = create(:time_deposit_product)
      patch treasury_time_deposit_product_path(product), params: {
        time_deposit_product: { name: "Updated" }
      }
      expect(product.reload.name).to eq("Updated")
      expect(response).to redirect_to(treasury_time_deposit_product_path(product))
    end
  end

  describe "DELETE /treasury/time_deposit_products/:id" do
    it "destroys the time deposit product" do
      product = create(:time_deposit_product)
      expect {
        delete treasury_time_deposit_product_path(product)
      }.to change(Treasury::TimeDepositProduct, :count).by(-1)

      expect(response).to redirect_to(treasury_time_deposit_products_path)
    end
  end
end
