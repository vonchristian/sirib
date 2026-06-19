require "rails_helper"

RSpec.describe Identity::EnrollmentService do
  describe ".create_enrollment" do
    it "creates an enrollment token for the member" do
      member = create(:member)
      expect {
        described_class.create_enrollment(member)
      }.to change { Portal::EnrollmentToken.count }.by(1)

      token = member.portal_enrollment_tokens.last
      expect(token.expires_at).to be > Time.current
      expect(token.used_at).to be_nil
    end
  end

  describe ".find_member_by_token" do
    it "returns the member for a valid, unused, non-expired token" do
      member = create(:member)
      token = create(:portal_enrollment_token, member: member)

      found_member = described_class.find_member_by_token(token.token)

      expect(found_member).to eq(member)
    end

    it "returns nil for an expired token" do
      member = create(:member)
      token = create(:portal_enrollment_token, member: member, expires_at: 1.hour.ago)

      found_member = described_class.find_member_by_token(token.token)

      expect(found_member).to be_nil
    end

    it "returns nil for a used token" do
      member = create(:member)
      token = create(:portal_enrollment_token, member: member, used_at: Time.current)

      found_member = described_class.find_member_by_token(token.token)

      expect(found_member).to be_nil
    end

    it "returns nil for a non-existent token" do
      found_member = described_class.find_member_by_token("nonexistent")

      expect(found_member).to be_nil
    end
  end

  describe ".complete_enrollment" do
    let(:member) { create(:member, password: nil, otp_secret: nil, otp_enabled: false) }
    let(:password) { "Password123!" }
    let(:otp_secret) { Mfa::TotpService.generate_secret }

    context "with valid OTP code" do
      it "updates the member with password and OTP settings" do
        code = Mfa::TotpService.generate_current_code(otp_secret)

        result = described_class.complete_enrollment(
          member: member,
          password: password,
          otp_secret: otp_secret,
          otp_code: code
        )

        expect(result).to be true
        member.reload
        expect(member.password).not_to be_nil
        expect(member.otp_secret).to eq(otp_secret)
        expect(member.otp_enabled).to be true
        expect(member.otp_verified_at).not_to be_nil
        expect(member.portal_status).to eq("active")
      end

      it "marks enrollment tokens as used" do
        token = create(:portal_enrollment_token, member: member)
        code = Mfa::TotpService.generate_current_code(otp_secret)

        described_class.complete_enrollment(
          member: member,
          password: password,
          otp_secret: otp_secret,
          otp_code: code
        )

        token.reload
        expect(token.used_at).not_to be_nil
      end
    end

    context "with invalid OTP code" do
      it "returns false without updating the member" do
        member = create(:member, password: nil)

        result = described_class.complete_enrollment(
          member: member,
          password: password,
          otp_secret: otp_secret,
          otp_code: "000000"
        )

        expect(result).to be false
        member.reload
        expect(member.password).to be_nil
        expect(member.otp_secret).to be_nil
      end

      it "does not mark enrollment tokens as used" do
        token = create(:portal_enrollment_token, member: member)

        described_class.complete_enrollment(
          member: member,
          password: password,
          otp_secret: otp_secret,
          otp_code: "000000"
        )

        token.reload
        expect(token.used_at).to be_nil
      end
    end
  end

  describe "instance methods delegate to class methods" do
    it "#create_enrollment delegates to class method" do
      member = create(:member)
      expect(described_class).to receive(:create_enrollment).with(member).and_call_original

      described_class.new.create_enrollment(member)
    end

    it "#find_member_by_token delegates to class method" do
      token = "abc123"
      expect(described_class).to receive(:find_member_by_token).with(token).and_call_original

      described_class.new.find_member_by_token(token)
    end

    it "#complete_enrollment delegates to class method" do
      member = create(:member)
      expect(described_class).to receive(:complete_enrollment).with(member: member, password: "pass", otp_secret: "secret", otp_code: "123456").and_call_original

      described_class.new.complete_enrollment(member: member, password: "pass", otp_secret: "secret", otp_code: "123456")
    end
  end
end