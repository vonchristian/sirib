require "rails_helper"

RSpec.describe "External::Reconciliation" do
  let(:user) { create(:user, password: "secret123") }
  let(:bank) { create(:external_bank) }
  let(:account) { create(:external_bank_account, bank: bank) }

  before do
    post session_path, params: { email_address: user.email_address, password: "secret123" }
  end

  describe "GET /external/banks/:bank_id/accounts/:account_id/reconciliation" do
    it "returns a successful response" do
      get external_bank_account_reconciliation_path(bank, account)
      expect(response).to be_successful
    end

    it "shows unreconciled transactions" do
      tx = create(:external_bank_transaction, account: account, description: "Salary")
      get external_bank_account_reconciliation_path(bank, account)
      expect(response.body).to include("Salary")
    end

    it "loads journal entries" do
      get external_bank_account_reconciliation_path(bank, account)
      expect(response.body).to include("Journal Entries")
    end

    context "with selected transaction" do
      it "shows match panel" do
        tx = create(:external_bank_transaction, account: account)
        get external_bank_account_reconciliation_path(bank, account, transaction_id: tx.id)
        expect(response.body).to include("Matching Transaction")
      end
    end

    context "with unreconciled filter" do
      it "filters to unreconciled transactions" do
        reconciled_tx = create(:external_bank_transaction, account: account, description: "Reconciled transfer")
        create(:external_bank_transaction_allocation, bank_transaction: reconciled_tx, status: "confirmed")
        create(:external_bank_transaction, account: account, description: "Unreconciled payment")

        get external_bank_account_reconciliation_path(bank, account, unreconciled: "1")
        expect(response.body).not_to include("Reconciled transfer")
      end
    end
  end

  describe "POST /external/banks/:bank_id/accounts/:account_id/reconciliation/allocate" do
    it "creates an allocation" do
      tx = create(:external_bank_transaction, account: account, amount_cents: 1000_00)
      entry = create(:accounting_entry)

      expect {
        post allocate_external_bank_account_reconciliation_path(bank, account),
             params: { transaction_id: tx.id, journal_entry_id: entry.id, allocated_amount_cents: tx.amount_cents }
      }.to change(External::BankTransactionAllocation, :count).by(1)

      expect(response).to redirect_to(external_bank_account_reconciliation_path(bank, account, transaction_id: tx.id))
    end

    it "allows partial allocation" do
      tx = create(:external_bank_transaction, account: account, amount_cents: 1000_00)
      entry = create(:accounting_entry)

      post allocate_external_bank_account_reconciliation_path(bank, account),
           params: { transaction_id: tx.id, journal_entry_id: entry.id, allocated_amount_cents: 500_00 }

      expect(tx.allocations.sum(:allocated_amount_cents)).to eq(500_00)
    end

    it "enqueues audit job" do
      tx = create(:external_bank_transaction, account: account, amount_cents: 1000_00)
      entry = create(:accounting_entry)

      expect {
        post allocate_external_bank_account_reconciliation_path(bank, account),
             params: { transaction_id: tx.id, journal_entry_id: entry.id, allocated_amount_cents: 500_00 }
      }.to have_enqueued_job(External::ReconciliationAuditJob)
    end
  end

  describe "POST /external/banks/:bank_id/accounts/:account_id/reconciliation/confirm_allocation" do
    it "confirms a suggested allocation" do
      allocation = create(:external_bank_transaction_allocation, status: "suggested")

      post confirm_allocation_external_bank_account_reconciliation_path(bank, account),
           params: { allocation_id: allocation.id }

      expect(allocation.reload.status).to eq("confirmed")
      expect(response).to redirect_to(external_bank_account_reconciliation_path(bank, account, transaction_id: allocation.external_bank_transaction_id))
    end
  end

  describe "POST /external/banks/:bank_id/accounts/:account_id/reconciliation/reject_allocation" do
    it "rejects a suggested allocation" do
      allocation = create(:external_bank_transaction_allocation, status: "suggested")

      post reject_allocation_external_bank_account_reconciliation_path(bank, account),
           params: { allocation_id: allocation.id }

      expect(allocation.reload.status).to eq("rejected")
      expect(response).to redirect_to(external_bank_account_reconciliation_path(bank, account, transaction_id: allocation.external_bank_transaction_id))
    end
  end
end
