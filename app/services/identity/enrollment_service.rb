module Identity
  class EnrollmentService
    def self.create_enrollment(member)
      new.create_enrollment(member)
    end

    def self.find_member_by_token(token)
      new.find_member_by_token(token)
    end

    def self.complete_enrollment(member:, password:, otp_secret:, otp_code:)
      new.complete_enrollment(member: member, password: password, otp_secret: otp_secret, otp_code: otp_code)
    end

    def create_enrollment(member)
      member.portal_enrollment_tokens.create!
    end

    def find_member_by_token(token)
      enrollment = Portal::EnrollmentToken.valid.find_by(token: token)
      return nil unless enrollment
      enrollment.member
    end

    def complete_enrollment(member:, password:, otp_secret:, otp_code:)
      unless Mfa::TotpService.verify(otp_secret, otp_code)
        return false
      end

      member.update!(
        password: password,
        otp_secret: otp_secret,
        otp_enabled: true,
        otp_verified_at: Time.current,
        portal_status: "active"
      )

      member.portal_enrollment_tokens.valid.find_each(&:use!)
      true
    end
  end
end
