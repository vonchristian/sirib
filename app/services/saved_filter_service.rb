class SavedFilterService
  def initialize(user:)
    @user = user
  end

  def create!(name:, filters:, filter_type: "journal_entry", is_shared: false, set_default: false)
    filter = SavedFilter.new(
      user: user,
      name: name,
      filters: filters,
      filter_type: filter_type,
      is_shared: is_shared,
      cooperative: user.cooperative
    )

    filter.validate_filtersSchema!
    filter.save!
    filter.set_as_default! if set_default

    filter
  end

  def update!(filter_id:, **attributes)
    filter = SavedFilter.find(filter_id)
    raise ArgumentError, "Not authorized to update this filter" unless filter.user == user || user.manager?

    filter.assign_attributes(attributes)
    filter.validate_filtersSchema! if attributes[:filters]
    filter.save!
    filter
  end

  def destroy!(filter_id)
    filter = SavedFilter.find(filter_id)
    raise ArgumentError, "Not authorized to delete this filter" unless filter.user == user || user.manager?

    filter.destroy!
  end

  def list(filter_type: nil)
    scope = SavedFilter.for_user(user)
    scope = scope.by_type(filter_type) if filter_type.present?
    scope.order(is_default: :desc, name: :asc)
  end

  def get_default(filter_type:)
    SavedFilter.defaults.by_type(filter_type).for_user(user).first
  end

  def apply_saved_filter(filter_id)
    filter = SavedFilter.find(filter_id)
    raise ArgumentError, "Not authorized to use this filter" unless filter.user == user || filter.is_shared?

    filter.apply
  end

  def share_filter!(filter_id, role_restriction: nil)
    filter = SavedFilter.find(filter_id)
    raise ArgumentError, "Not authorized to share this filter" unless filter.user == user || user.admin?

    filter.update!(is_shared: true, role_restriction: role_restriction)
  end

  def unshare_filter!(filter_id)
    filter = SavedFilter.find(filter_id)
    raise ArgumentError, "Not authorized to unshare this filter" unless filter.user == user || user.admin?

    filter.update!(is_shared: false, role_restriction: nil)
  end

  private

  attr_reader :user
end
