module Management
  class Configuration < ApplicationRecord
    self.table_name = "management_configurations"
    include CooperativeScoped

    belongs_to :configurable, polymorphic: true, optional: true
    belongs_to :changed_by, class_name: "User", optional: true
    belongs_to :approved_by, class_name: "User", optional: true

    has_many :versions, -> { order(version: :desc) }, class_name: "Management::ConfigurationVersion", foreign_key: :configuration_id, dependent: :destroy

    validates :key, :value, presence: true
    validates :key, uniqueness: { scope: [:configurable_type, :configurable_id, :cooperative_id] }

    enum :status, { draft: "draft", active: "active", archived: "archived" }
  end
end
