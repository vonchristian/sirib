module Treasury
  class VaultTransfer < ApplicationRecord
    self.table_name = "treasury_vault_transfers"
    include CooperativeScoped

    belongs_to :cash_session, class_name: "Treasury::CashSession"
    belongs_to :approved_by, class_name: "User", optional: true
    belongs_to :voucher, class_name: "Treasury::Voucher", optional: true

    enum :direction, { to_teller: "to_teller", to_vault: "to_vault" }, validate: true
    enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true

    validates :amount_cents, presence: true, numericality: { greater_than: 0 }

    scope :awaiting, -> { where(status: :pending) }

    def approve!(approver:)
      raise "Already #{status}" unless pending?

      ActiveRecord::Base.transaction do
        voucher = build_voucher!
        voucher.save!
        post_voucher_entry!(voucher)
        update!(status: :approved, approved_by: approver, approved_at: Time.current, voucher: voucher)
      end

      reload
    end

    def reject!(approver:)
      raise "Already #{status}" unless pending?
      update!(status: :rejected, approved_by: approver, approved_at: Time.current)
    end

    private

    def build_voucher!
      attrs = {
        cash_session: cash_session,
        cash_account: cash_session.cash_account,
        amount_cents: amount_cents,
        amount_currency: "PHP",
        description: description.presence || (to_teller? ? "Cash received from vault" : "Cash returned to vault")
      }

      if to_teller?
        cash_session.vouchers.new(
          type: "Treasury::CashReceiptVoucher",
          category: "vault_transfer_in",
          **attrs
        )
      else
        cash_session.vouchers.new(
          type: "Treasury::CashDisbursementVoucher",
          category: "vault_transfer_out",
          **attrs
        )
      end
    end

    def post_voucher_entry!(voucher)
      vault_account = Cooperative.first&.vault_account
      raise "Vault account not configured" unless vault_account

      if to_teller?
        voucher.post_entry!(credit_account: vault_account)
      else
        voucher.post_entry!(debit_account: vault_account)
      end
    end
  end
end
