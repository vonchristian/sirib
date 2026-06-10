module Accounting
  class Ledger < ApplicationRecord
    self.table_name = "ledgers"

    has_ancestry

    has_many :accounts, dependent: :restrict_with_error
    has_many :running_balances, dependent: :restrict_with_error

    enum :account_type, Accounting::ACCOUNT_TYPES

    validates :name, presence: true
    validates :account_code, presence: true, uniqueness: true
    validates :account_type, presence: true

    scope :contra, -> { where(contra: true) }
    scope :non_contra, -> { where(contra: false) }

    scope :current_asset, -> {
      where(account_type: :asset, account_code: "11100"..."13000")
    }
    scope :non_current_asset, -> {
      where(account_type: :asset).where("account_code >= '13000'")
    }
    scope :current_liability, -> {
      where(account_type: :liability, account_code: "21100"..."22000")
    }
    scope :non_current_liability, -> {
      where(account_type: :liability).where("account_code >= '22000'")
    }
  end
end
