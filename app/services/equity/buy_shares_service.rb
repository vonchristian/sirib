module Equity
  class BuySharesService < ActiveInteraction::Base
    include IdempotentService

    object :share_capital_account, class: Equity::Account
    integer :shares
    object :cash_account, class: Accounting::Account
    object :cash_session, class: Treasury::CashSession, default: nil
    integer :posted_by_id
    string :notes, default: nil
    string :idempotency_key, default: nil

    # Lock ordering: Equity Account/Equity Product (4) — see app/docs/prds/concurrency_locking.prd
    def execute
      with_idempotency(key: idempotency_key) do
        product = share_capital_account.share_product

        errors.add(:shares, "must be greater than zero") and return unless shares.positive?
        errors.add(:base, "Share capital account is not active") and return unless share_capital_account.active?
        errors.add(:base, "Product is not active") and return unless product.active?
        errors.add(:base, "Share product has no equity ledger") and return unless product.equity_ledger
        errors.add(:base, "Share capital account has no equity account") and return unless share_capital_account.equity_account

        validate_purchase_limits!(product)

        total_amount_cents = shares * product.price_per_share_cents

        share_capital_account.with_lock do
          entry = post_journal_entry!(product, total_amount_cents)

          txn = Equity::Transaction.create!(
            share_capital_account: share_capital_account,
            transaction_type: :purchase,
            shares: shares,
            price_per_share_cents: product.price_per_share_cents,
            total_amount_cents: total_amount_cents,
            cash_account: cash_account,
            entry: entry,
            posted_by_id: posted_by_id,
            notes: notes,
            status: "completed",
            posted_at: Time.current
          )

          create_cash_session_voucher!(entry, txn, total_amount_cents) if cash_session

          share_capital_account.update!(
            shares_owned: share_capital_account.shares_owned + shares,
            paid_up_shares: share_capital_account.paid_up_shares + shares
          )

          txn
        end
      end
    end

    private

    def validate_purchase_limits!(product)
      new_total = share_capital_account.shares_owned + shares

      if product.maximum_allowed_shares && new_total > product.maximum_allowed_shares
        errors.add(:shares, "would exceed maximum allowed shares of #{product.maximum_allowed_shares}")
      end

      if share_capital_account.shares_owned.zero? && shares < product.minimum_initial_purchase
        errors.add(:shares, "minimum initial purchase is #{product.minimum_initial_purchase} shares")
      end
    end

    def post_journal_entry!(product, total_amount_cents)
      Accounting::BusinessHoursPostingService.post(
        cooperative: share_capital_account.cooperative,
        description: "Share capital purchase - #{share_capital_account.account_number}",
        reference_number: "SC-#{share_capital_account.account_number}-#{SecureRandom.uuid}",
        posted_at: Time.current,
        debits: [ { account: cash_account, amount: total_amount_cents } ],
        credits: [ { account: share_capital_account.equity_account, amount: total_amount_cents } ]
      )
    end

    def create_cash_session_voucher!(entry, txn, total_amount_cents)
      voucher = cash_session.vouchers.create!(
        type: "Treasury::CashReceiptVoucher",
        cash_account: cash_account,
        amount_cents: total_amount_cents,
        amount_currency: "PHP",
        category: "share_capital_purchase",
        description: "Share capital purchase — #{share_capital_account.account_number}",
        counterparty: share_capital_account.member,
        transactable: txn,
        entry: entry,
        status: "posted",
        posted_at: Time.current
      )
    end
  end
end
