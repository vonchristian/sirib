module Treasury
  class TimeDepositProductsController < ApplicationController
    layout "dashboard"

    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = Treasury::TimeDepositProduct.by_term
    end

    def show
    end

    def new
      @product = Treasury::TimeDepositProduct.new
    end

    def edit
    end

    def create
      @product = Treasury::TimeDepositProduct.new(product_params)

      if @product.save
        redirect_to treasury_time_deposit_product_path(@product), notice: "Time deposit product created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @product.update(product_params)
        redirect_to treasury_time_deposit_product_path(@product), notice: "Time deposit product updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to treasury_time_deposit_products_path, notice: "Time deposit product removed."
    end

    private

    def set_product
      @product = Treasury::TimeDepositProduct.find(params[:id])
    end

    def product_params
      params.require(:time_deposit_product).permit(:name, :description, :minimum_deposit_cents, :interest_rate, :term_in_days, :status)
    end
  end
end
