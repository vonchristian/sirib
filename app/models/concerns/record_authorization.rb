module RecordAuthorization
  extend ActiveSupport::Concern

  included do
    scope :accessible_by, ->(user, action:, subject: nil) {
      return all if user.nil?

      if user.has_permission?(action, subject || name.demodulize.underscore)
        all
      else
        none
      end
    }
  end

  def authorize_to(user, action:, subject: nil)
    return true if user.nil?

    unless user.has_permission?(action, subject || self.class.name.demodulize.underscore)
      raise ActiveRecord::RecordNotSaved, "Not authorized to #{action} this #{self.class.name}"
    end

    true
  end

  def authorize_to!(user, action:, subject: nil)
    authorize_to(user, action: action, subject: subject)
  end
end
