module External
  class Bank < ApplicationRecord
    self.table_name = "external_banks"

    has_many :accounts, class_name: "External::BankAccount", foreign_key: :external_bank_id, dependent: :destroy
    belongs_to :cash_on_hand_ledger, class_name: "Accounting::Ledger", foreign_key: :cash_on_hand_ledger_id, optional: true
    belongs_to :interest_income_ledger, class_name: "Accounting::Ledger", foreign_key: :interest_income_ledger_id, optional: true

    enum :status, { active: "active", inactive: "inactive" }, default: :active

    validates :name, presence: true
    validates :country, presence: true

    scope :active, -> { where(status: :active) }

    after_create :create_tracking_accounts

    private

    def create_tracking_accounts
      cash_in_bank_ledger = Accounting::Ledger.find_by(account_code: "11000")

      return unless cash_in_bank_ledger

      transaction do
        cash_ledger = Accounting::Ledger.create!(
          name: "#{name} - Cash on Hand",
          account_code: "1#{code.presence || name.first(3).upcase}00",
          account_type: :asset,
          parent: cash_in_bank_ledger
        )

        interest_ledger = Accounting::Ledger.create!(
          name: "#{name} - Interest Income",
          account_code: "4#{code.presence || name.first(3).upcase}00",
          account_type: :revenue,
          parent: Accounting::Ledger.find_by(account_code: "41000")
        )

        update!(
          cash_on_hand_ledger_id: cash_ledger.id,
          interest_income_ledger_id: interest_ledger.id
        )
      end
    end
  end
end