module External
  class BankAccount < ApplicationRecord
    self.table_name = "external_bank_accounts"

    belongs_to :bank, class_name: "External::Bank", foreign_key: :external_bank_id
    belongs_to :cash_on_hand_account, class_name: "Accounting::Account", foreign_key: :cash_on_hand_account_id, optional: true
    belongs_to :interest_income_account, class_name: "Accounting::Account", foreign_key: :interest_income_account_id, optional: true

    has_many :documents, class_name: "External::BankDocument", foreign_key: :external_bank_account_id, dependent: :destroy
    has_many :transactions, class_name: "External::BankTransaction", foreign_key: :external_bank_account_id, dependent: :destroy

    enum :status, { active: "active", inactive: "inactive" }, default: :active

    validates :account_name, presence: true
    validates :account_type, presence: true
    validates :currency, presence: true

    scope :active, -> { where(status: :active) }

    after_create :create_tracking_accounts, :create_interest_earned_template

    delegate :name, to: :bank, prefix: true

    def current_balance_money
      Money.new(current_balance_cents || 0, currency)
    end

    def last_transaction
      transactions.order(transaction_date: :desc, created_at: :desc).first
    end

    def update_balance!
      last_tx = last_transaction
      update!(
        current_balance: last_tx&.running_balance || 0,
        current_balance_cents: last_tx&.running_balance_cents || 0,
        last_synced_at: Time.current
      )
    end

    def create_tracking_accounts
      return unless bank.cash_on_hand_ledger

      transaction do
        cash_account = Accounting::Account.create!(
          name: "#{account_name} - #{account_number_display}",
          account_code: "#{bank.cash_on_hand_ledger.account_code}#{id.to_s.rjust(4, '0')}",
          account_type: :asset,
          ledger: bank.cash_on_hand_ledger
        )

        interest_account = Accounting::Account.create!(
          name: "#{account_name} - Interest Income",
          account_code: "#{bank.interest_income_ledger.account_code}#{id.to_s.rjust(4, '0')}",
          account_type: :revenue,
          ledger: bank.interest_income_ledger
        )

        update!(
          cash_on_hand_account_id: cash_account.id,
          interest_income_account_id: interest_account.id
        )
      end
    end

    private

    def create_interest_earned_template
      return unless cash_on_hand_account_id && interest_income_account_id

      Accounting::EntryTemplate.create!(
        name: "Interest Earned — #{account_name}",
        lines_attributes: {
          "0" => { account_id: cash_on_hand_account_id, direction: "debit", amount_mode: "variable", sequence_index: 1 },
          "1" => { account_id: interest_income_account_id, direction: "credit", amount_mode: "variable", sequence_index: 2 }
        }
      )
    end

    def account_number_display
      return "N/A" if account_number_encrypted.blank?

      raw = account_number_encrypted.to_s
      last4 = raw.last(4)
      "*" * [raw.length - 4, 0].max + last4
    end
  end
end