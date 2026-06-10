class Role < ApplicationRecord
  VALID_NAMES = [
    "system_administrator",
    "manager",
    "teller",
    "loan_officer"
].freeze

  VALID_NAMES.each do |role_name|
    define_method("#{role_name}?") do
      name == role_name
    end
  end

  def self.predicate_methods
    VALID_NAMES.map { "#{_1}?" }.freeze
  end
end
