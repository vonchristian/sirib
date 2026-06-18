module Loans
  class ProductsController < ApplicationController
    layout "shell"
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = Lending::LoanProduct.order(:name)
    end

    def new
      @product = Lending::LoanProduct.new
    end

    def create
      @product = Lending::LoanProduct.new(product_params)
      if @product.save
        redirect_to loans_products_path, notice: "Loan product created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
    end

    def edit
    end

    def update
      if @product.update(product_params)
        redirect_to loans_products_path, notice: "Loan product updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy!
      redirect_to loans_products_path, notice: "Loan product deleted."
    rescue ActiveRecord::DeleteRestrictionError => e
      redirect_to loans_products_path, alert: e.message
    end

    private

    def set_product
      @product = Lending::LoanProduct.find(params[:id])
    end

    def product_params
      params.require(:loan_product).permit(:name, :description, :interest_rate, :interest_calculation, :max_term_months, :requires_collateral, :status,
        loan_charges_attributes: [:id, :name, :charge_type, :value, :_destroy])
    end
  end
end
