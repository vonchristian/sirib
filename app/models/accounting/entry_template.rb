module Accounting
  class EntryTemplate < ApplicationRecord
    self.table_name = "entry_templates"

    belongs_to :entry, class_name: "Accounting::Entry", optional: true
    has_many :lines, class_name: "Accounting::EntryTemplateLine", dependent: :destroy

    validates :name, presence: true

    scope :active, -> { where(is_active: true) }

    accepts_nested_attributes_for :lines, allow_destroy: true, reject_if: :all_blank

    def execute!(amount:, user: nil)
      Accounting::EntryTemplate::ExecuteService.run!(template: self, amount: amount, user: user)
    end

    def preview(amount:)
      Accounting::EntryTemplate::ExecuteService.run(template: self, amount: amount)
    end

    def balanced?
      debit_sum = lines.where(direction: "debit").sum do |l|
        l.amount_mode == "fixed" ? (l.fixed_amount || 0) : 0
      end
      credit_sum = lines.where(direction: "credit").sum do |l|
        l.amount_mode == "fixed" ? (l.fixed_amount || 0) : 0
      end
      debit_sum == credit_sum
    end
  end
end
