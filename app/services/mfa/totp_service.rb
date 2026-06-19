module Mfa
  class TotpService
    ISSUER = "Sirib"
    DRIFT_SECONDS = 30
    TRUST_DURATION = 30.days

    def self.generate_secret
      ROTP::Base32.random
    end

    def self.provisioning_uri(secret, email)
      totp = ROTP::TOTP.new(secret, issuer: ISSUER)
      totp.provisioning_uri(email)
    end

    def self.verify(secret, code)
      totp = ROTP::TOTP.new(secret, issuer: ISSUER)
      totp.verify(code, drift_behind: DRIFT_SECONDS, drift_ahead: DRIFT_SECONDS)
    end

    def self.generate_backup_codes(count = 10)
      codes = []
      digests = []
      count.times do
        code = SecureRandom.hex(4).scan(/.{4}/).join("-").upcase
        codes << code
        digests << BCrypt::Password.create(code)
      end
      { codes: codes, digests: digests }
    end

    def self.verify_backup_code(code, user)
      user.backup_codes.unused.find_each do |stored|
        next unless BCrypt::Password.new(stored.code_digest) == code
        stored.update!(used_at: Time.current)
        return true
      end
      false
    end

    def self.build_device_fingerprint(request)
      data = "#{request.user_agent}|#{request.remote_ip}"
      Digest::SHA256.hexdigest(data)
    end

    def self.compute_device_fingerprint(user_agent, ip_address)
      data = "#{user_agent}|#{ip_address}"
      Digest::SHA256.hexdigest(data)
    end

    def self.device_trusted?(user, fingerprint)
      return false if fingerprint.blank?
      Access::TrustedDevice.trusted?(user, fingerprint)
    end

    def self.trust_device!(user, fingerprint, ip_address: nil, user_agent: nil)
      Access::TrustedDevice.trust!(user, fingerprint, ip_address: ip_address, user_agent: user_agent)
    end

    def self.log_attempt(user, action:, success:, ip_address: nil, user_agent: nil, device_fingerprint: nil, failure_reason: nil, metadata: {})
      Access::MfaAttemptLog.log(user, action: action, success: success, ip_address: ip_address, user_agent: user_agent, device_fingerprint: device_fingerprint, failure_reason: failure_reason, metadata: metadata)
    end

    def self.rate_limited?(user, max_attempts: 5, within: 10.minutes)
      Access::MfaAttemptLog.rate_limited?(user, max_attempts: max_attempts, within: within)
    end
  end
end
