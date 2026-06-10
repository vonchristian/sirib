module Accounting
  class CashAccount < ApplicationRecord
    self.table_name = "accounting_cash_accounts"

    belongs_to :user
    belongs_to :account

    validates :user_id, uniqueness: { scope: :account_id }
  end
end
