module Treasury
  class CashSession < ApplicationRecord
    self.table_name = "treasury_cash_sessions"

    belongs_to :user
    belongs_to :cash_account, class_name: "Accounting::Account"
    has_many :vouchers, class_name: "Treasury::Voucher", foreign_key: :cash_session_id,
             dependent: :restrict_with_error

    validates :date, presence: true
    validates :status, inclusion: { in: %w[open closed] }
    validates :date, uniqueness: { scope: [:user_id, :cash_account_id],
              message: "already has a session for this cash account" }

    scope :open, -> { where(status: "open") }
    scope :closed, -> { where(status: "closed") }
    scope :for_date, ->(date) { where(date: date) }
    scope :by_latest, -> { order(date: :desc, created_at: :desc) }

    def self.for_today(user, cash_account: nil)
      cash_account ||= user.cash_accounts.includes(:account).first&.account
      return nil unless cash_account

      find_or_create_by!(user: user, cash_account: cash_account, date: Date.current) do |s|
        s.opened_at = Time.current
        s.status = "open"
        s.beginning_balance_cents = cash_account.balance.cents
      end
    end

    def close!(ending_balance: nil, notes: nil)
      update!(
        status: "closed",
        closed_at: Time.current,
        ending_balance_cents: ending_balance&.cents || cash_account.balance.cents,
        notes: notes
      )
    end

    def open?
      status == "open"
    end

    def closed?
      status == "closed"
    end

    def total_receipts
      vouchers.where(type: "Treasury::CashReceiptVoucher", status: "posted").sum(:amount_cents)
    end

    def total_disbursements
      vouchers.where(type: "Treasury::CashDisbursementVoucher", status: "posted").sum(:amount_cents)
    end

    def net_cash_flow
      total_receipts - total_disbursements
    end

    def computed_ending_balance
      beginning_balance_cents.to_i + net_cash_flow
    end
  end
end
