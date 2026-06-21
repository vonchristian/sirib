module Members
  class RecentActivityService
    LIMIT = 10

    def initialize(member)
      @member = member
    end

    def call(limit: LIMIT)
      activities = []

      savings_account_ids = Treasury::SavingsAccount.where(
        depositor_id: @member.id, depositor_type: "Member"
      ).pluck(:id)

      if savings_account_ids.any?
        Treasury::SavingsTransaction.where(savings_account_id: savings_account_ids, status: "completed")
          .by_latest
          .limit(limit)
          .includes(:savings_account)
          .each do |txn|
            activities << {
              date: txn.posted_at,
              module: "Savings",
              reference: txn.reference_number,
              description: "#{txn.deposit? ? "Deposit" : "Withdrawal"} - #{txn.savings_account.account_number}",
              amount: Money.new(txn.amount_cents, "PHP"),
              type: txn.deposit? ? :deposit : :withdrawal,
              sort_key: txn.posted_at
            }
          end
      end

      Lending::Loan.where(member: @member).pluck(:id).each do |loan_id|
        Lending::LoanPayment.where(loan_id: loan_id)
          .order(payment_date: :desc)
          .limit(limit)
          .includes(:loan)
          .each do |payment|
            activities << {
              date: payment.payment_date,
              module: "Loan",
              reference: payment.reference_number,
              description: "Loan Payment - #{payment.loan.reference_number}",
              amount: payment.amount,
              type: :payment,
              sort_key: payment.payment_date
            }
          end
      end

      member_equity_accounts = Equity::Account.where(member: @member).pluck(:id)
      if member_equity_accounts.any?
        Equity::Transaction.where(share_capital_account_id: member_equity_accounts, status: "completed")
          .by_latest
          .limit(limit)
          .includes(:share_capital_account)
          .each do |txn|
            activities << {
              date: txn.posted_at,
              module: "Share Capital",
              reference: txn.reference_number,
              description: "#{txn.purchase? ? "Purchase" : txn.transaction_type} - #{txn.share_capital_account.account_number}",
              amount: txn.total_amount,
              type: :purchase,
              sort_key: txn.posted_at
            }
          end
      end

      activities.sort_by { |a| a[:sort_key] }.reverse.first(limit)
    end
  end
end
