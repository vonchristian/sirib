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
  end
end
