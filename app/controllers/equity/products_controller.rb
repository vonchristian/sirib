module Equity
  class ProductsController < ApplicationController
    layout "dashboard"
    before_action :set_product, only: [:show, :edit, :update, :destroy]

    def index
      @products = Equity::Product.by_name
    end

    def show
    end

    def new
      @product = Equity::Product.new
    end

    def edit
    end

    def create
      @product = Equity::Product.new(product_params)
      if @product.save
        redirect_to equity_product_path(@product), notice: "Share capital product created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @product.update(product_params)
        redirect_to equity_product_path(@product), notice: "Share capital product updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to equity_products_path, notice: "Share capital product removed."
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to equity_product_path(@product), alert: "Cannot delete product with existing accounts."
    end

    private

    def set_product
      @product = Equity::Product.find(params[:id])
    end

    def product_params
      params.require(:equity_product).permit(
        :product_code, :name, :description, :share_type, :status, :effective_date,
        :price_per_share_cents, :minimum_required_shares, :maximum_allowed_shares,
        :minimum_initial_purchase, :allow_fractional_shares, :redeemable,
        :dividend_eligible, :voting_rights
      )
    end
  end
end
