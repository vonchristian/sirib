module CooperativeScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :cooperative

    before_validation :auto_set_cooperative, on: :create

    scope :by_cooperative, ->(coop) { where(cooperative_id: coop.id) }
  end

  private

  def auto_set_cooperative
    self.cooperative ||= Current.cooperative
  end
end
