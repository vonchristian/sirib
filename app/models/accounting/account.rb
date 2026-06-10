module Accounting
  class Account < ApplicationRecord
    include PgSearch::Model
    self.table_name = "accounts"

    pg_search_scope :search, against: [:name, :account_code],
      using: { tsearch: { prefix: true }, trigram: { threshold: 0.3 } }

    NORMAL_CREDIT_BALANCE = {
      "asset" => false,
      "expense" => false,
      "liability" => true,
      "equity" => true,
      "revenue" => true
    }.freeze

    belongs_to :ledger
    has_many :amount_lines, dependent: :restrict_with_error
    has_many :running_balances, dependent: :restrict_with_error
    has_many :cash_account_assignments, class_name: "Accounting::CashAccount", dependent: :destroy

    has_many :debit_amount_lines, -> { where(amount_type: :debit) },
             class_name: "Accounting::AmountLine", inverse_of: :account
    has_many :credit_amount_lines, -> { where(amount_type: :credit) },
             class_name: "Accounting::AmountLine", inverse_of: :account

    enum :account_type, Accounting::ACCOUNT_TYPES

    validates :name, presence: true
    validates :account_code, presence: true, uniqueness: true
    validates :account_type, presence: true

    scope :contra, -> { where(contra: true) }
    scope :non_contra, -> { where(contra: false) }

    scope :cash_accounts_for, ->(user) {
      where(id: user.cash_accounts.select(:account_id))
    }

    def normal_credit_balance?
      NORMAL_CREDIT_BALANCE[account_type]
    end

    def balance(from_date: nil, to_date: nil, to_time: nil)
      cents = if normal_credit_balance? ^ contra
                credits_balance(from_date:, to_date:, to_time:) -
                  debits_balance(from_date:, to_date:, to_time:)
      else
                debits_balance(from_date:, to_date:, to_time:) -
                  credits_balance(from_date:, to_date:, to_time:)
      end

      Money.new(cents, "PHP")
    end

    def debits_balance(from_date: nil, to_date: nil, to_time: nil)
      amount_lines.debit.balance(from_date:, to_date:, to_time:)
    end

    def credits_balance(from_date: nil, to_date: nil, to_time: nil)
      amount_lines.credit.balance(from_date:, to_date:, to_time:)
    end

    def self.balance(from_date: nil, to_date: nil, to_time: nil)
      strategy = AccountBalance.resolve(from_date:, to_date:, to_time:)
      amounts = strategy.load_amounts

      total = Money.new(0, "PHP")
      find_each do |account|
        cents = if account.normal_credit_balance? ^ account.contra
                  (amounts[[ account.id, "credit" ]] || 0) - (amounts[[ account.id, "debit" ]] || 0)
        else
                  (amounts[[ account.id, "debit" ]] || 0) - (amounts[[ account.id, "credit" ]] || 0)
        end
        total += account.contra ? -Money.new(cents, "PHP") : Money.new(cents, "PHP")
      end
      total
    end

    def self.trial_balance
      asset_balance = where(account_type: :asset).balance
      liability_balance = where(account_type: :liability).balance
      equity_balance = where(account_type: :equity).balance
      revenue_balance = where(account_type: :revenue).balance
      expense_balance = where(account_type: :expense).balance

      asset_balance - (liability_balance + equity_balance + revenue_balance - expense_balance)
    end
  end
end
