module Management
  class Team < ApplicationRecord
    self.table_name = "management_teams"

    belongs_to :department, class_name: "Management::Department"

    validates :name, presence: true
  end
end
