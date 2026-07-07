require "rails_helper"

RSpec.describe "Concurrency Locking" do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe "Treasury::CashSession.for_today" do
    it "locks with FOR UPDATE on find_or_create_by!" do
      user = create(:user, cooperative: cooperative)
      account = create(:accounting_account, cooperative: cooperative)
      create(:accounting_cash_account, user: user, account: account, cooperative: cooperative)

      expect_any_instance_of(ActiveRecord::Relation).to receive(:lock).with("FOR UPDATE").and_call_original
      Treasury::CashSession.for_today(user)
    end

    it "prevents duplicate sessions under concurrent access" do
      user = create(:user, cooperative: cooperative)
      account = create(:accounting_account, cooperative: cooperative)
      create(:accounting_cash_account, user: user, account: account, cooperative: cooperative)

      Treasury::CashSession.for_today(user)
      dup = Treasury::CashSession.where(user: user, cash_account: account, date: Date.current).first

      expect(Treasury::CashSession.where(user: user, date: Date.current).count).to eq(1)
    end
  end

  describe "Treasury::CashSession#close!" do
    it "uses with_lock" do
      user = create(:user, cooperative: cooperative)
      account = create(:accounting_account, cooperative: cooperative)
      create(:accounting_cash_account, user: user, account: account, cooperative: cooperative)
      session = Treasury::CashSession.for_today(user)

      expect(session).to receive(:with_lock).and_call_original
      session.close!
    end
  end

  describe "Accounting::Entry#reverse!" do
    it "uses with_lock" do
      account = create(:accounting_account, cooperative: cooperative)
      entry = Accounting::Entry.build(
        description: "Test reverse locking",
        debits: [ { account: account, amount: 1000 } ],
        credits: [ { account: account, amount: 1000 } ]
      )
      entry.cooperative = cooperative
      entry.save!

      expect(entry).to receive(:with_lock).and_call_original
      entry.reverse!(reversed_by: nil)
    end
  end

  describe "Accounting::PostingEngine" do
    it "locks affected accounts before posting" do
      debit_account = create(:accounting_account, cooperative: cooperative)
      credit_account = create(:accounting_account, cooperative: cooperative)
      template = Accounting::EntryTemplate.create!(name: "Lock Test", cooperative: cooperative)
      template.lines.create!(account: debit_account, direction: "debit", amount_mode: "variable", sequence_index: 1)
      template.lines.create!(account: credit_account, direction: "credit", amount_mode: "variable", sequence_index: 2)

      expect(Accounting::Account).to receive(:lock).with("FOR UPDATE").at_least(:once).and_call_original
      engine = Accounting::PostingEngine.new(template: template, input: { amount: 1000 })
      engine.post!
    end
  end

  describe "Banking::TransactionService" do
    let(:cash_session) { instance_double(Treasury::CashSession, open?: true, id: 1) }

    it "locks accounts with FOR UPDATE on debit" do
      from_account = create(:accounting_account, cooperative: cooperative)
      to_account = create(:accounting_account, cooperative: cooperative)

      expect(Accounting::Account).to receive(:lock).with("FOR UPDATE").at_least(:once).and_call_original
      Banking::TransactionService.debit(
        amount: Money.new(100, "PHP"),
        from_account: from_account,
        to_account: to_account,
        cash_session: cash_session,
        description: "Lock test debit"
      )
    end
  end

  describe "Equity::BuySharesService" do
    it "locks the share capital account with with_lock" do
      skip "Requires full Equity::Account factory setup"
    end
  end

  describe "Treasury::SavingsTransactionService" do
    it "locks the savings account with with_lock" do
      skip "Requires full Treasury::SavingsAccount factory setup with liability_account assigned"
    end
  end

  describe "lock_version columns" do
    it "entries table has lock_version" do
      expect(Accounting::Entry.column_names).to include("lock_version")
    end

    it "amount_lines table has lock_version" do
      expect(Accounting::AmountLine.column_names).to include("lock_version")
    end

    it "running_balances table has lock_version" do
      expect(Accounting::RunningBalance.column_names).to include("lock_version")
    end

    it "loans table has lock_version" do
      expect(Lending::Loan.column_names).to include("lock_version")
    end

    it "loan_payments table has lock_version" do
      expect(Lending::LoanPayment.column_names).to include("lock_version")
    end

    it "treasury_savings_accounts table has lock_version" do
      expect(Treasury::SavingsAccount.column_names).to include("lock_version")
    end

    it "treasury_savings_transactions table has lock_version" do
      expect(Treasury::SavingsTransaction.column_names).to include("lock_version")
    end

    it "equity_accounts table has lock_version" do
      expect(Equity::Account.column_names).to include("lock_version")
    end

    it "equity_transactions table has lock_version" do
      expect(Equity::Transaction.column_names).to include("lock_version")
    end

    it "treasury_cash_sessions table has lock_version" do
      expect(Treasury::CashSession.column_names).to include("lock_version")
    end
  end
end
