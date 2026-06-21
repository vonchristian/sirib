module Treasury
  class SavingsProduct < ApplicationRecord
    self.table_name = "treasury_savings_products"
    include CooperativeScoped

    has_many :interest_rates, class_name: "Treasury::SavingsProductInterestRate", dependent: :destroy
    has_many :savings_accounts, class_name: "Treasury::SavingsAccount", dependent: :restrict_with_error
    accepts_nested_attributes_for :interest_rates, allow_destroy: true, reject_if: :all_blank

    belongs_to :liability_ledger, class_name: "Accounting::Ledger", optional: true
    belongs_to :interest_expense_ledger, class_name: "Accounting::Ledger", optional: true

    validates :name, presence: true
    validates :status, inclusion: { in: %w[active inactive] }

    scope :active, -> { where(status: "active") }
    scope :by_name, -> { order(name: :asc) }

    before_create :auto_create_ledgers

    def current_interest_rate
      interest_rates.find_by(current: true)
    end

    private

    def auto_create_ledgers
      self.liability_ledger ||= Accounting::Ledger.create!(
        name: "#{name} - Deposit Liabilities",
        account_type: :liability,
        account_code: next_code_for_type(:liability),
        cooperative: cooperative
      )

      self.interest_expense_ledger ||= Accounting::Ledger.create!(
        name: "#{name} - Interest Expense",
        account_type: :expense,
        account_code: next_code_for_type(:expense),
        cooperative: cooperative
      )
    end

    def next_code_for_type(account_type)
      max = Accounting::Ledger.where(account_type: account_type).maximum(:account_code)
      if max
        format('%05d', max.to_i + 1)
      else
        case account_type.to_s
        when "liability" then "21100"
        when "expense" then "61100"
        else "99999"
        end
      end
    end

    def next_account_code(ledger)
      max = ledger.accounts.pluck(:account_code).map(&:to_i).max
      if max
        format('%05d', max + 1)
      else
        "#{ledger.account_code}001"
      end
    end
  end
end
