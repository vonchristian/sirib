class SavedFilter < ApplicationRecord
  belongs_to :user
  belongs_to :cooperative, optional: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :filters, presence: true
  validates :filter_type, presence: true, inclusion: { in: %w[journal_entry trial_balance general_ledger] }

  scope :for_user, ->(user) { where(user: user).or(where(is_shared: true, cooperative: user.cooperative)) }
  scope :by_type, ->(type) { where(filter_type: type) }
  scope :defaults, -> { where(is_default: true) }
  scope :shared, -> { where(is_shared: true) }

  def apply
    filters.with_indifferent_access
  end

  def set_as_default!
    transaction do
      SavedFilter.where(user: user, filter_type: filter_type, is_default: true)
                 .where.not(id: id)
                 .update_all(is_default: false)
      update!(is_default: true)
    end
  end

  def self.valid_filters
    %i[
      start_date end_date branch_id account_id entry_type status
      source_module amount_min amount_max reference_number created_by_id
      template_id has_attachments inter_branch
    ]
  end

  def validate_filtersSchema
    invalid_keys = filters.keys - SavedFilter.valid_filters
    errors.add(:filters, "contains invalid keys: #{invalid_keys.join(', ')}") if invalid_keys.any?
  end
end