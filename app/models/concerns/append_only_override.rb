module AppendOnlyOverride
  def self.with_override(reason:, user: nil)
    raise ArgumentError, "reason is required" if reason.blank?

    ActiveRecord::Base.connection.execute("SELECT set_config('my.append_only_override', 'on', true)")
    yield
  end
end
