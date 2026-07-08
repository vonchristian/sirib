module Equity
  class Account < ApplicationRecord
    self.table_name = "equity_accounts"
    include CooperativeScoped

    STATUSES = %w[active closed].freeze

    belongs_to :member, class_name: "Membership::Member"
    belongs_to :share_product, class_name: "Equity::Product"
    belongs_to :equity_account, class_name: "Accounting::Account", optional: true
    has_many :transactions, class_name: "Equity::Transaction", foreign_key: :share_capital_account_id, dependent: :restrict_with_error

    validates :account_number, presence: true, uniqueness: { scope: :cooperative_id }
    validates :status, inclusion: { in: STATUSES }
    validates :shares_owned, numericality: { greater_than_or_equal_to: 0 }
    validates :paid_up_shares, numericality: { greater_than_or_equal_to: 0 }

    scope :active, -> { where(status: "active") }
    scope :by_latest, -> { order(created_at: :desc) }

    before_validation :assign_account_number, on: :create
    before_validation :set_opened_at, on: :create
    before_create :assign_equity_account

    def active?
      status == "active"
    end

    def remaining_required_shares
      [ share_product.minimum_required_shares - shares_owned, 0 ].max
    end

    def progress_percentage
      return 100 if share_product.minimum_required_shares.zero?
      [ (shares_owned.to_f / share_product.minimum_required_shares * 100).round, 100 ].min
    end

    def current_share_value
      Money.new(shares_owned * share_product.price_per_share_cents, "PHP")
    end

    def paid_up_capital
      Money.new(paid_up_shares * share_product.price_per_share_cents, "PHP")
    end

    def remaining_amount_needed
      Money.new(remaining_required_shares * share_product.price_per_share_cents, "PHP")
    end

    def member_name
      member.name
    end

    private

    def assign_account_number
      return if account_number.present?
      date_part = Time.current.strftime("%Y%m%d")
      random_part = SecureRandom.hex(3).upcase
      self.account_number = "SC-#{date_part}-#{random_part}"
    end

    def set_opened_at
      self.opened_at ||= Time.current
    end

    def assign_equity_account
      return unless share_product&.equity_ledger
      return unless self.class.column_names.include?("equity_account_id")

      self.equity_account ||= share_product.equity_ledger.accounts.create!(
        name: "#{member_name} - #{share_product.name}",
        account_type: :equity,
        account_code: next_account_code(share_product.equity_ledger),
        cooperative: cooperative
      )
    end

    def next_account_code(_ledger)
      max = Accounting::Account.where(cooperative_id: cooperative_id).pluck(:account_code).map(&:to_i).max
      if max
        format("%05d", max + 1)
      else
        "00100"
      end
    end
  end
end
