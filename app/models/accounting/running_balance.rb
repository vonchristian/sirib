module Accounting
  class RunningBalance < ApplicationRecord
    self.table_name = "running_balances"
    include CooperativeScoped

    monetize :balance_cents

    belongs_to :account, optional: true
    belongs_to :ledger

    validates :as_of_date, presence: true
    validates :balance_cents, presence: true,
              numericality: { allow_nil: false }
    validates :account_id, presence: true, if: :account_balance?
    validate :account_or_ledger_balance

    scope :as_of, ->(date) { where(as_of_date: date) }
    scope :on_or_before, ->(date) { where(as_of_date: ..date) }

    scope :account_balances, -> { where.not(account_id: nil) }
    scope :ledger_balances, -> { where(account_id: nil) }

    def self.latest_for_account(account_id, date: Date.current)
      account_balances
        .where(account_id: account_id)
        .on_or_before(date)
        .order(as_of_date: :desc)
        .first
    end

    def self.latest_for_ledger(ledger_id, date: Date.current)
      ledger_balances
        .where(ledger_id: ledger_id)
        .on_or_before(date)
        .order(as_of_date: :desc)
        .first
    end

    def account_balance?
      account_id.present?
    end

    def ledger_balance?
      account_id.blank?
    end

    private

    def account_or_ledger_balance
      if account_id.blank? && ledger_id.blank?
        errors.add(:base, "must belong to either an account or a ledger")
      end
    end
  end
end
