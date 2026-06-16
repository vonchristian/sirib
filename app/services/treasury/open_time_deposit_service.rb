module Treasury
  class OpenTimeDepositService < ActiveInteraction::Base
    object :depositor, class: Object
    object :product, class: Treasury::TimeDepositProduct
    integer :amount_cents
    string :amount_currency, default: "PHP"

    def execute
      deposit = build_deposit

      if deposit.invalid?
        errors.merge!(deposit.errors)
        return
      end

      if Money.new(amount_cents, amount_currency) < product.minimum_deposit
        errors.add(:amount_cents, "must be at least #{product.minimum_deposit.format}")
        return
      end

      Treasury::TimeDeposit.transaction do
        deposit.save!
        post_journal_entry!(deposit)
      end

      deposit
    end

    private

    def build_deposit
      Treasury::TimeDeposit.new(
        depositor: depositor,
        time_deposit_product: product,
        amount_cents: amount_cents,
        amount_currency: amount_currency,
        interest_rate: product.interest_rate,
        interest_earned_cents: interest_earned.cents,
        interest_earned_currency: amount_currency,
        matured_on: product.term_in_days.days.from_now.to_date,
        opened_at: Time.current,
        status: "active"
      )
    end

    def post_journal_entry!(deposit)
      cash_account = Accounting::Account.find_by!(account_code: "11110")
      time_deposit_account = Accounting::Account.find_by!(account_code: "21120")

      Accounting::PostEntryService.run!(
        description: "Time deposit ##{deposit.id} opened",
        reference_number: "TD-#{deposit.id}",
        posted_at: deposit.opened_at,
        debits: [{ account: cash_account, amount: deposit.amount_cents }],
        credits: [{ account: time_deposit_account, amount: deposit.amount_cents }]
      )
    end

    def interest_earned
      @interest_earned ||= begin
        interest = amount_cents * product.interest_rate * product.term_in_days / 365.0
        Money.new(interest.round, amount_currency)
      end
    end
  end
end
