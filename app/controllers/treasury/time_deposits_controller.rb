module Treasury
  class TimeDepositsController < ApplicationController
    layout "shell"

    before_action :set_products, only: [:new, :preview]

    def index
      @deposits = Treasury::TimeDeposit.where(depositor_id: Current.user.id, depositor_type: "User").by_latest
    end

    def new
      @deposit = Treasury::TimeDeposit.new
    end

    def preview
      @product = Treasury::TimeDepositProduct.find(params[:product_id])
      @amount = parse_amount(params[:amount_cents], params[:amount_currency])

      unless @amount.cents.positive?
        flash.now[:alert] = "Amount must be greater than zero."
        render :new, status: :unprocessable_entity
        return
      end

      if @amount < @product.minimum_deposit
        flash.now[:alert] = "Minimum deposit is #{@product.minimum_deposit.format}."
        render :new, status: :unprocessable_entity
        return
      end

      @matured_on = @product.term_in_days.days.from_now.to_date
      @interest_earned = calculate_interest(@amount, @product.interest_rate, @product.term_in_days)
    end

    def create
      @product = Treasury::TimeDepositProduct.find(params[:time_deposit][:time_deposit_product_id])
      @amount = parse_amount(params[:time_deposit][:amount_cents], params[:time_deposit][:amount_currency])

      outcome = Treasury::OpenTimeDepositService.run(
        depositor: Current.user,
        product: @product,
        amount_cents: @amount.cents,
        amount_currency: @amount.currency.to_s
      )

      if outcome.valid?
        redirect_to treasury_time_deposit_path(outcome.result), notice: "Time deposit opened."
      else
        set_products
        @deposit = Treasury::TimeDeposit.new(
          time_deposit_product: @product,
          amount_cents: @amount.cents,
          amount_currency: @amount.currency.to_s,
          interest_rate: @product.interest_rate
        )
        outcome.errors.each { |e| @deposit.errors.add(e.attribute, e.message) }
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @deposit = Treasury::TimeDeposit.find(params[:id])
    end

    private

    def set_products
      @products = Treasury::TimeDepositProduct.active.by_term
    end

    def parse_amount(raw_cents, currency)
      cents = (raw_cents.to_f * 100).round
      Money.new(cents, currency || "PHP")
    end

    def calculate_interest(amount, rate, term_in_days)
      interest = amount.cents * rate * term_in_days / 365.0
      Money.new(interest.round, amount.currency)
    end
  end
end
