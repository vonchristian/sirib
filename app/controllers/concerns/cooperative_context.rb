module CooperativeContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_cooperative
    before_action :require_cooperative

    helper_method :current_cooperative
  end

  private

  def current_cooperative
    Current.cooperative
  end

  def set_current_cooperative
    return unless Current.user

    Current.cooperative = Current.user.cooperative
  end

  def require_cooperative
    return if current_cooperative.present?

    raise ActiveRecord::RecordNotFound
  end
end
