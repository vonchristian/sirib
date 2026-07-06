module Treasury
  class SavingsAccount < ApplicationRecord
    self.table_name = "treasury_savings_accounts"
    include CooperativeScoped

    ACCOUNT_TYPES = { personal: 0, business: 1 }.freeze
    STATUSES = %w[active closed].freeze

    attribute :status, default: "active"

    belongs_to :savings_product, class_name: "Treasury::SavingsProduct"
    belongs_to :liability_account, class_name: "Accounting::Account", optional: true
    belongs_to :interest_expense_account, class_name: "Accounting::Account", optional: true
    has_many :transactions, class_name: "Treasury::SavingsTransaction", dependent: :restrict_with_error

    validates :account_type, presence: true
    validates :status, inclusion: { in: STATUSES }
    validates :account_number, presence: true, uniqueness: { scope: :cooperative_id }

    enum :account_type, ACCOUNT_TYPES

    scope :active, -> { where(status: "active") }
    scope :by_latest, -> { order(created_at: :desc) }

    before_validation :assign_account_number, on: :create
    before_validation :set_opened_at, on: :create
    before_create :assign_accounts_from_product

    def active?
      status == "active"
    end

    def balance
      liability_account&.balance || Money.new(0, "PHP")
    end

    def depositor
      @depositor ||= Treasury::DepositorResolver.resolve(depositor_type, depositor_id)
    end

    def depositor=(record)
      self.depositor_type = record.class.model_name.name
      self.depositor_id = record.id
      @depositor = record
    end

    def depositor_name
      depositor.respond_to?(:name) ? depositor.name : depositor.to_s
    end

    def reload(*args)
      @depositor = nil
      super
    end

    private

    def assign_account_number
      return if account_number.present?
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.account_number = "SA-#{date_part}-#{random_part}"
    end

    def set_opened_at
      self.opened_at ||= Time.current
    end

    def assign_accounts_from_product
      return unless savings_product

      if savings_product.liability_ledger && liability_account.blank?
        self.liability_account = savings_product.liability_ledger.accounts.create(
          name: "#{savings_product.name} Savings - #{depositor_name}",
          account_type: :liability,
          account_code: next_account_code(savings_product.liability_ledger),
          cooperative: cooperative
        )
        unless liability_account.persisted?
          Rails.logger.error "[SavingsAccount] Failed to create liability account: #{liability_account.errors.full_messages.join(', ')}"
          errors.add(:base, "Liability account: #{liability_account.errors.full_messages.join(', ')}")
          throw :abort
        end
      end

      if savings_product.interest_expense_ledger
        self.interest_expense_account = savings_product.interest_expense_ledger.accounts.create(
          name: "#{savings_product.name} Interest Expense - #{depositor_name}",
          account_type: :expense,
          account_code: next_account_code(savings_product.interest_expense_ledger),
          cooperative: cooperative
        )
        unless interest_expense_account.persisted?
          Rails.logger.error "[SavingsAccount] Failed to create interest expense account: #{interest_expense_account.errors.full_messages.join(', ')}"
          errors.add(:base, "Interest expense account: #{interest_expense_account.errors.full_messages.join(', ')}")
          throw :abort
        end
      end
    end

    def next_account_code(ledger)
      all_codes = Accounting::Account.where(cooperative_id: cooperative_id).pluck(:account_code)
      max = all_codes.map(&:to_i).max
      result = if max
        format("%05d", max + 1)
      else
        "#{ledger.account_code}001"
      end
      result
    end
  end
end
