module Reporting
  class BalanceSheet < ApplicationRecord
    self.table_name = "reporting_balance_sheets"
    self.primary_key = "account_id"

    belongs_to :account, class_name: "Accounting::Account", foreign_key: :account_id

    monetize :balance_cents

    scope :by_cooperative, ->(coop) { where(cooperative_id: coop.id) }
    scope :by_type, ->(type) { where(account_type: type) }
    scope :with_balance, -> { where.not(balance_cents: 0) }

    def readonly?
      true
    end

    def self.refresh
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_balance_sheets")
    end
  end
end