module Reporting
  class TrialBalance < ApplicationRecord
    self.table_name = "reporting_trial_balances"
    self.primary_key = "account_id"

    belongs_to :account, class_name: "Accounting::Account", foreign_key: :account_id

    monetize :debit_cents
    monetize :credit_cents

    scope :by_cooperative, ->(coop) { where(cooperative_id: coop.id) }
    scope :by_type, ->(type) { where(account_type: type) }
    scope :with_balance, -> { where("debit_cents != 0 OR credit_cents != 0") }

    def readonly?
      true
    end

    def self.refresh
      connection.execute("REFRESH MATERIALIZED VIEW CONCURRENTLY reporting_trial_balances")
    end
  end
end