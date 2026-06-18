class AddApprovalWorkflowToVaultTransfers < ActiveRecord::Migration[7.2]
  def change
    add_column :treasury_vault_transfers, :status, :string, null: false, default: "pending"
    add_reference :treasury_vault_transfers, :approved_by, null: true, foreign_key: { to_table: :users }
    add_column :treasury_vault_transfers, :approved_at, :datetime, null: true
    add_reference :treasury_vault_transfers, :voucher, null: true, foreign_key: { to_table: :treasury_vouchers }
  end
end
