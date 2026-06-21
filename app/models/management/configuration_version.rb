module Management
  class ConfigurationVersion < ApplicationRecord
    self.table_name = "management_configuration_versions"
    include CooperativeScoped

    belongs_to :configuration, class_name: "Management::Configuration", touch: true
    belongs_to :changed_by, class_name: "User", optional: true

    validates :version, :value, presence: true
    validates :version, uniqueness: { scope: :configuration_id }
  end
end
