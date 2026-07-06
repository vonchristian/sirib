module Equity
  class Product < ApplicationRecord
    self.table_name = "equity_products"
    include CooperativeScoped

    SHARE_TYPES = { common: 0, preferred: 1, other: 2 }.freeze

    has_many :share_capital_accounts, class_name: "Equity::Account", foreign_key: :share_product_id, dependent: :restrict_with_error
    belongs_to :equity_ledger, class_name: "Accounting::Ledger", optional: true

    validates :product_code, presence: true, uniqueness: { scope: :cooperative_id }
    validates :name, presence: true
    validates :status, inclusion: { in: %w[active inactive] }
    validates :price_per_share_cents, numericality: { greater_than: 0 }
    validates :minimum_required_shares, numericality: { greater_than: 0 }
    validates :maximum_allowed_shares, numericality: { greater_than: 0, allow_nil: true }
    validates :minimum_initial_purchase, numericality: { greater_than: 0 }
    validate :maximum_greater_than_minimum, if: -> { maximum_allowed_shares.present? }

    enum :share_type, SHARE_TYPES

    scope :active, -> { where(status: "active") }
    scope :by_name, -> { order(name: :asc) }

    before_create :auto_create_equity_ledger

    def active?
      status == "active"
    end

    def price_per_share
      Money.new(price_per_share_cents, "PHP")
    end

    private

    def maximum_greater_than_minimum
      if maximum_allowed_shares <= minimum_required_shares
        errors.add(:maximum_allowed_shares, "must be greater than minimum required shares")
      end
    end

    def auto_create_equity_ledger
      return if equity_ledger.present?

      self.equity_ledger = Accounting::Ledger.create!(
        name: "#{name} - Share Capital",
        account_type: :equity,
        account_code: next_code_for_type(:equity),
        cooperative: cooperative
      )
    end

    def next_code_for_type(account_type)
      max = Accounting::Ledger.where(account_type: account_type, cooperative: cooperative).maximum(:account_code)
      if max
        format("%05d", max.to_i + 1)
      else
        case account_type.to_s
        when "equity" then "31100"
        else "99999"
        end
      end
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
