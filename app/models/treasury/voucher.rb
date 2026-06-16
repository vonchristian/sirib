module Treasury
  class Voucher < ApplicationRecord
    self.table_name = "treasury_vouchers"

    belongs_to :cash_session, class_name: "Treasury::CashSession"
    belongs_to :cash_account, class_name: "Accounting::Account"
    belongs_to :entry, class_name: "Accounting::Entry", optional: true
    belongs_to :counterparty, polymorphic: true, optional: true
    belongs_to :transactable, polymorphic: true, optional: true

    validates :voucher_number, presence: true, uniqueness: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :category, presence: true
    validates :status, inclusion: { in: %w[pending posted cancelled] }

    scope :posted, -> { where(status: "posted") }
    scope :pending, -> { where(status: "pending") }
    scope :cancelled, -> { where(status: "cancelled") }
    scope :receipts, -> { where(type: "Treasury::CashReceiptVoucher") }
    scope :disbursements, -> { where(type: "Treasury::CashDisbursementVoucher") }
    scope :by_latest, -> { order(created_at: :desc) }

    before_validation :assign_voucher_number, on: :create

    def receipt?
      type == "Treasury::CashReceiptVoucher"
    end

    def disbursement?
      type == "Treasury::CashDisbursementVoucher"
    end

    def post_entry!(**)
      raise NotImplementedError, "Subclasses must implement #post_entry!"
    end

    def cancel!
      update!(status: "cancelled")
    end

    private

    def validate_posting!
      raise "Voucher already posted" if status == "posted"
      raise "Voucher is cancelled" if status == "cancelled"
      raise "Cash session is closed" if cash_session&.closed?
    end

    def assign_voucher_number
      return if voucher_number.present?

      prefix = receipt? ? "CRV" : "CDV"
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.voucher_number = "#{prefix}-#{date_part}-#{random_part}"
    end
  end
end
