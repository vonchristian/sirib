module Management
  class Policy < ApplicationRecord
    self.table_name = "management_policies"

    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :approved_by, class_name: "User", optional: true
    belongs_to :target_entity, polymorphic: true, optional: true

    has_many :rules, class_name: "Management::PolicyRule", dependent: :destroy

    validates :name, :code, :category, presence: true
    validates :code, uniqueness: true

    enum :status, { draft: "draft", active: "active", inactive: "inactive" }

    scope :active, -> { where(status: :active) }
    scope :by_category, -> { order(category: :asc) }

    accepts_nested_attributes_for :rules, allow_destroy: true
  end
end
