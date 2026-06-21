module Treasury
  class SearchesController < ApplicationController
    layout false

    def members
      query = params[:q]
      @members = if query.present?
        Membership::Member
          .order(:last_name)
          .search(query)
          .limit(15)
      else
        Membership::Member.none
      end
      render partial: "treasury/searches/members", locals: { members: @members }
    end

    def savings_accounts
      query = params[:q]
      @accounts = if query.present?
        Treasury::SavingsAccount
          .includes(:savings_product)
          .joins("LEFT JOIN members ON members.id = treasury_savings_accounts.depositor_id AND treasury_savings_accounts.depositor_type = 'Member'")
          .joins(:savings_product)
          .where(
            "treasury_savings_accounts.account_number ILIKE :q OR " \
            "members.first_name ILIKE :q OR members.last_name ILIKE :q OR " \
            "CONCAT(members.first_name, ' ', members.last_name) ILIKE :q OR " \
            "treasury_savings_products.name ILIKE :q",
            q: "%#{Treasury::SavingsAccount.sanitize_sql_like(query)}%"
          )
          .order(created_at: :desc)
          .limit(15)
      else
        Treasury::SavingsAccount.none
      end
      render partial: "treasury/searches/savings_accounts", locals: { accounts: @accounts }
    end
  end
end
