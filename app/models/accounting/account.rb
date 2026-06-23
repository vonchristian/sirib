module Accounting
  class Account < ApplicationRecord
    include PgSearch::Model
    self.table_name = "accounts"
    include CooperativeScoped

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

    attribute :account_type, :string
    attribute :status, :string, default: "active"
    attribute :postable, :boolean, default: true

    enum :account_type, { asset: "asset", equity: "equity", liability: "liability", revenue: "revenue", expense: "expense" }, validate: false
    enum :status, { active: "active", inactive: "inactive" }, default: :active, validate: false

    validates :name, presence: true
    validates :account_code, presence: true, uniqueness: { scope: :cooperative_id }
    validates :account_type, presence: true

    scope :contra, -> { where(contra: true) }
    scope :non_contra, -> { where(contra: false) }
    scope :postable, -> { where(postable: true) }
    scope :non_postable, -> { where(postable: false) }

    scope :cash_accounts_for, ->(user) {
      where(id: user.cash_accounts.select(:account_id))
    }

    def normal_credit_balance?
      NORMAL_CREDIT_BALANCE[account_type]
    end

    def postable?
      postable
    end

    def active?
      status == "active"
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
