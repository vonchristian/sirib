module Management
  class Holiday < ApplicationRecord
    self.table_name = "management_holidays"
    include CooperativeScoped

    belongs_to :cooperative

    validates :date, :name, presence: true
    validates :date, uniqueness: { scope: :cooperative_id, message: "already a holiday for this cooperative" }

    scope :on_date, ->(date) { where(date: date) }
    scope :recurring, -> { where(recurring: true) }
    scope :between, ->(start_date, end_date) { where(date: start_date..end_date) }

    def self.holiday?(date, cooperative:)
      exists?(cooperative: cooperative, date: date) ||
        recurring.where(cooperative: cooperative)
          .where("EXTRACT(month FROM date) = ? AND EXTRACT(day FROM date) = ?", date.month, date.day)
          .exists?
    end
  end
end
