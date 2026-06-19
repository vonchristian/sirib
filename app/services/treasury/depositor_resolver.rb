module Treasury
  class DepositorResolver
    TYPE_MAP = {
      "Member" => Membership::Member,
      "User" => User
    }.freeze

    def self.resolve(type, id)
      return nil if type.blank? || id.blank?
      klass = TYPE_MAP[type]
      klass&.find_by(id: id)
    end

    def self.resolve!(type, id)
      klass = TYPE_MAP[type]
      raise ArgumentError, "Unknown depositor type: #{type}" unless klass
      klass.find(id)
    end
  end
end
