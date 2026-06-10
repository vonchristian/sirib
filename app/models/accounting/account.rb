module Accounting
  class Account < ApplicationRecord
    include PgSearch::Model
    self.table_name = "accounts"

    pg_search_scope :search, against: [ :name, :account_code ],
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
    has_many :cash_accounts, class_name: "Accounting::CashAccount", dependent: :destroy

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
      total = Money.new(0, "PHP")
      find_each { |a| total += a.balance(from_date:, to_date:, to_time:) }
      total
    end
  end
end
