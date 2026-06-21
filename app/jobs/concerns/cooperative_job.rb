module CooperativeJob
  extend ActiveSupport::Concern

  included do
    around_perform :set_current_cooperative
  end

  class_methods do
    def perform_later(*args, cooperative: nil, **kwargs)
      if cooperative
        kwargs[:cooperative_id] = cooperative.is_a?(Cooperative) ? cooperative.id : cooperative
      end
      super(*args, **kwargs)
    end
  end

  private

  def set_current_cooperative
    coop = resolve_cooperative
    Current.cooperative = coop if coop
    yield
  ensure
    Current.cooperative = nil
  end

  def resolve_cooperative
    cooperative_id = arguments.last.is_a?(Hash) ? arguments.last[:cooperative_id] : nil
    return nil unless cooperative_id

    @_cooperative ||= Cooperative.active.find_by(id: cooperative_id)
  end
end
