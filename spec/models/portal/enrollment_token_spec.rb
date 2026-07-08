require "rails_helper"

RSpec.describe Portal::EnrollmentToken do
  describe "associations" do
    it { should belong_to(:member) }
  end

  describe "validations" do
    it { should validate_presence_of(:token) }
    it { should validate_presence_of(:expires_at) }
  end

  describe "scopes" do
    describe ".valid" do
      it "returns tokens where used_at is nil and expires_at > now" do
        member = create(:member)
        valid_token = create(:portal_enrollment_token, member: member, expires_at: 1.hour.from_now, used_at: nil)
        expired_token = create(:portal_enrollment_token, member: member, expires_at: 1.hour.ago, used_at: nil)
        used_token = create(:portal_enrollment_token, member: member, expires_at: 1.hour.from_now, used_at: Time.current)

        expect(described_class.valid).to include(valid_token)
        expect(described_class.valid).not_to include(expired_token)
        expect(described_class.valid).not_to include(used_token)
      end
    end
  end

  describe "#used?" do
    it "returns true when used_at is set" do
      token = build(:portal_enrollment_token, used_at: Time.current)
      expect(token.used?).to be true
    end

    it "returns false when used_at is nil" do
      token = build(:portal_enrollment_token, used_at: nil)
      expect(token.used?).to be false
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      token = build(:portal_enrollment_token, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      token = build(:portal_enrollment_token, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe "#use!" do
    it "sets used_at to current time" do
      token = create(:portal_enrollment_token, used_at: nil)
      expect(token.used_at).to be_nil

      token.use!

      expect(token.used_at).not_to be_nil
      expect(token.used_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "token generation" do
    it "generates a unique token on create" do
      token1 = create(:portal_enrollment_token)
      token2 = create(:portal_enrollment_token)

      expect(token1.token).not_to eq(token2.token)
      expect(token1.token).to match(/\A[a-f0-9]{48}\z/)
    end
  end
end
