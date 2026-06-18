module Treasury
  class SavingsProductsController < ApplicationController
    layout "shell"
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = Treasury::SavingsProduct.by_name
    end

    def show
    end

    def new
      @product = Treasury::SavingsProduct.new
      @product.interest_rates.build
    end

    def edit
      @product.interest_rates.build if @product.interest_rates.empty?
    end

    def create
      @product = Treasury::SavingsProduct.new(product_params)
      if @product.save
        redirect_to treasury_savings_product_path(@product), notice: "Savings product created."
      else
        @product.interest_rates.build if @product.interest_rates.empty?
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @product.update(product_params)
        redirect_to treasury_savings_product_path(@product), notice: "Savings product updated."
      else
        @product.interest_rates.build if @product.interest_rates.empty?
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to treasury_savings_products_path, notice: "Savings product removed."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to treasury_savings_product_path(@product), alert: "Cannot delete product with existing accounts."
    end

    private

    def set_product
      @product = Treasury::SavingsProduct.find(params[:id])
    end

    def product_params
      params.require(:treasury_savings_product).permit(:name, :description, :status,
        interest_rates_attributes: [:id, :rate, :current, :_destroy])
    end
  end
end
