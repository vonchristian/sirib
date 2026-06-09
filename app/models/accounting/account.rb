module Accounting
  class Account < ApplicationRecord
    self.table_name = "accounts"

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

    has_many :debit_amount_lines, -> { where(amount_type: :debit) },
             class_name: "Accounting::AmountLine", inverse_of: :account
    has_many :credit_amount_lines, -> { where(amount_type: :credit) },
             class_name: "Accounting::AmountLine", inverse_of: :account

    enum :account_type, {
      asset: "asset",
      equity: "equity",
      liability: "liability",
      revenue: "revenue",
      expense: "expense"
    }

    validates :name, presence: true
    validates :account_code, presence: true, uniqueness: true
    validates :account_type, presence: true

    scope :contra, -> { where(contra: true) }
    scope :non_contra, -> { where(contra: false) }

    def normal_credit_balance?
      NORMAL_CREDIT_BALANCE[account_type]
    end

    def balance(from_date: nil, to_date: nil)
      cents = if normal_credit_balance? ^ contra
                credits_balance(from_date: from_date, to_date: to_date) -
                  debits_balance(from_date: from_date, to_date: to_date)
              else
                debits_balance(from_date: from_date, to_date: to_date) -
                  credits_balance(from_date: from_date, to_date: to_date)
              end
      Money.new(cents, "PHP")
    end

    def credits_balance(from_date: nil, to_date: nil)
      scope = credit_amount_lines
      scope = scope.joins(:entry).where(entries: { posted_at: from_date.. }) if from_date
      scope = scope.joins(:entry).where(entries: { posted_at: ..to_date }) if to_date
      scope.sum(:amount_cents)
    end

    def debits_balance(from_date: nil, to_date: nil)
      scope = debit_amount_lines
      scope = scope.joins(:entry).where(entries: { posted_at: from_date.. }) if from_date
      scope = scope.joins(:entry).where(entries: { posted_at: ..to_date }) if to_date
      scope.sum(:amount_cents)
    end

    def self.balance(from_date: nil, to_date: nil)
      total = Money.new(0, "PHP")
      all.find_each do |account|
        if account.contra
          total -= account.balance(from_date: from_date, to_date: to_date)
        else
          total += account.balance(from_date: from_date, to_date: to_date)
        end
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
