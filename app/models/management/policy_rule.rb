module Management
  class PolicyRule < ApplicationRecord
    self.table_name = "management_policy_rules"
    include CooperativeScoped

    belongs_to :policy, class_name: "Management::Policy", touch: true

    validates :field, :operator, :value, :effect, presence: true

    enum :effect, { allow: "allow", deny: "deny", require_override: "require_override" }
  end
end
