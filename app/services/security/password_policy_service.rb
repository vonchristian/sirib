module Security
  class PasswordPolicyService
    Result = Struct.new(:valid?, :errors, keyword_init: true)

    DEFAULT_POLICY = {
      min_length: 8,
      require_uppercase: true,
      require_lowercase: true,
      require_digits: true,
      require_symbols: false,
      max_failed_attempts: 10,
      lockout_duration: 30,
      password_expiry_days: 90,
      password_history_count: 5
    }.freeze

    PASSWORD_DISALLOWED_WORDS = %w[password admin user sirib cooperative bank].freeze

    def self.evaluate(password:, user: nil, cooperative: nil)
      new.evaluate(password:, user:, cooperative:)
    end

    def evaluate(password:, user: nil, cooperative: nil)
      errors = []
      policy = active_policy(cooperative)

      if password.length < policy[:min_length]
        errors << "Password must be at least #{policy[:min_length]} characters"
      end

      if policy[:require_uppercase] && password !~ /[A-Z]/
        errors << "Password must include an uppercase letter"
      end

      if policy[:require_lowercase] && password !~ /[a-z]/
        errors << "Password must include a lowercase letter"
      end

      if policy[:require_digits] && password !~ /\d/
        errors << "Password must include a digit"
      end

      if policy[:require_symbols] && password !~ /[^a-zA-Z0-9]/
        errors << "Password must include a symbol"
      end

      disallowed = PASSWORD_DISALLOWED_WORDS.find { |w| password.downcase.include?(w) }
      if disallowed
        errors << "Password cannot contain common words"
      end

      if password.length > 72
        errors << "Password is too long"
      end

      if user && policy[:password_history_count] > 0
        if Security::PasswordHistoryService.password_in_history?(user, password)
          errors << "Password has been used recently"
        end
      end

      Result.new(valid?: errors.empty?, errors: errors)
    end

    def self.active_policy(cooperative = nil)
      new.active_policy(cooperative)
    end

    def active_policy(cooperative = nil)
      if cooperative
        record = Security::PasswordPolicy.where(cooperative: cooperative, active: true).first
        return record_attributes(record) if record
      end

      DEFAULT_POLICY
    end

    private

    def record_attributes(record)
      {
        min_length: record.min_length || DEFAULT_POLICY[:min_length],
        require_uppercase: record.require_uppercase.nil? ? DEFAULT_POLICY[:require_uppercase] : record.require_uppercase,
        require_lowercase: record.require_lowercase.nil? ? DEFAULT_POLICY[:require_lowercase] : record.require_lowercase,
        require_digits: record.require_digits.nil? ? DEFAULT_POLICY[:require_digits] : record.require_digits,
        require_symbols: record.require_symbols.nil? ? DEFAULT_POLICY[:require_symbols] : record.require_symbols,
        max_failed_attempts: record.max_failed_attempts || DEFAULT_POLICY[:max_failed_attempts],
        lockout_duration: record.lockout_duration || DEFAULT_POLICY[:lockout_duration],
        password_expiry_days: record.password_expiry_days || DEFAULT_POLICY[:password_expiry_days],
        password_history_count: record.password_history_count || DEFAULT_POLICY[:password_history_count]
      }
    end
  end
end
