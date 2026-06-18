class MemberTransactionService < ActiveInteraction::Base
  object :member
  object :cash_session, class: Treasury::CashSession
  object :cash_account, class: Accounting::Account
  array :items
  integer :posted_by_id
  string :notes, default: nil

  def execute
    errors.add(:base, "No items to process") and return if items.blank?
    errors.add(:base, "No cash session available") and return unless cash_session

    total_cents = items.sum { |i| i[:amount_cents] }

    ActiveRecord::Base.transaction do
      entry = create_journal_entry!(total_cents)
      voucher = create_voucher!(entry, total_cents)
      process_items!(entry)
    end
  end

  private

  def create_journal_entry!(total_cents)
    debits = [{ account: cash_account, amount: total_cents }]
    credits = items.map { |i| { account: i[:credit_account], amount: i[:amount_cents] } }

    Accounting::PostEntryService.run!(
      description: "Member transaction — #{member.name}",
      reference_number: "MTX-#{Time.current.strftime("%Y%m%d")}-#{SecureRandom.hex(3).upcase}",
      posted_at: Time.current,
      debits: debits,
      credits: credits
    )
  end

  def create_voucher!(entry, total_cents)
    cash_session.vouchers.create!(
      type: "Treasury::CashReceiptVoucher",
      cash_account: cash_account,
      amount_cents: total_cents,
      amount_currency: "PHP",
      category: "member_transaction",
      description: "Member transaction — #{member.name}",
      counterparty: member,
      entry: entry,
      status: "posted",
      posted_at: Time.current
    )
  end

  def process_items!(entry)
    items.each do |item|
      case item[:type]
      when :savings_deposit
        process_savings_deposit!(item, entry)
      when :loan_payment
        process_loan_payment!(item, entry)
      when :share_purchase
        process_share_purchase!(item, entry)
      end
    end
  end

  def process_savings_deposit!(item, entry)
    item[:account].transactions.create!(
      transaction_type: :deposit,
      amount_cents: item[:amount_cents],
      amount_currency: "PHP",
      cash_account: cash_account,
      entry: entry,
      notes: notes,
      status: "completed",
      posted_at: Time.current
    )
  end

  def process_loan_payment!(item, entry)
    loan = item[:account]
    amount_cents = item[:amount_cents]

    allocation = PaymentAllocator.call(
      loan: loan,
      amount_cents: amount_cents,
      payment_date: Date.current
    )

    payment = loan.loan_payments.create!(
      amount_cents: amount_cents,
      principal_cents: allocation[:principal_cents],
      interest_cents: allocation[:interest_cents],
      penalty_cents: allocation[:penalty_cents],
      payment_date: Date.current,
      entry: entry
    )

    new_outstanding = loan.outstanding_principal_cents - payment.principal_cents
    loan.update!(outstanding_principal_cents: [new_outstanding, 0].max)
    loan.update!(status: "paid") if loan.outstanding_principal_cents <= 0
  end

  def process_share_purchase!(item, entry)
    account = item[:account]
    product = account.share_product
    amount_cents = item[:amount_cents]
    price_cents = product.price_per_share_cents
    shares = amount_cents / price_cents

    return if shares.zero?

    Equity::Transaction.create!(
      share_capital_account: account,
      transaction_type: :purchase,
      shares: shares,
      price_per_share_cents: price_cents,
      total_amount_cents: shares * price_cents,
      cash_account: cash_account,
      entry: entry,
      posted_by_id: posted_by_id,
      notes: notes,
      status: "completed",
      posted_at: Time.current
    )

    account.update!(
      shares_owned: account.shares_owned + shares,
      paid_up_shares: account.paid_up_shares + shares
    )
  end
end
