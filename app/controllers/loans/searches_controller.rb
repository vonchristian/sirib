module Loans
  class SearchesController < ApplicationController
    layout false

    def members
      query = params[:q]
      @members = if query.present?
        Member.where("first_name ILIKE :q OR last_name ILIKE :q OR CONCAT(first_name, ' ', last_name) ILIKE :q OR mobile_number ILIKE :q",
                     q: "%#{query}%").order(:last_name).limit(15)
      else
        Member.none
      end

      render partial: "loans/searches/members", locals: { members: @members }
    end

    def loan_products
      query = params[:q]
      @loan_products = if query.present?
        Lending::LoanProduct.active.includes(:loan_charges).where("name ILIKE :q", q: "%#{query}%").order(:name).limit(15)
      else
        Lending::LoanProduct.none
      end

      render partial: "loans/searches/loan_products", locals: { loan_products: @loan_products }
    end
  end
end
