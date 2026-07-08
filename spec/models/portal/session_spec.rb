require "rails_helper"

RSpec.describe Portal::Session do
  describe "associations" do
    it { should belong_to(:member) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns sessions where revoked_at is nil" do
        member = create(:member)
        active_session = create(:portal_session, member: member, revoked_at: nil)
        revoked_session = create(:portal_session, member: member, revoked_at: Time.current)

        expect(described_class.active).to include(active_session)
        expect(described_class.active).not_to include(revoked_session)
      end
    end
  end

  describe "#active?" do
    it "returns true when revoked_at is nil" do
      session = build(:portal_session, revoked_at: nil)
      expect(session.active?).to be true
    end

    it "returns false when revoked_at is set" do
      session = build(:portal_session, revoked_at: Time.current)
      expect(session.active?).to be false
    end
  end

  describe "#revoke!" do
    it "sets revoked_at to current time" do
      session = create(:portal_session, revoked_at: nil)
      expect(session.revoked_at).to be_nil

      session.revoke!

      expect(session.revoked_at).not_to be_nil
      expect(session.revoked_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#touch_activity!" do
    it "updates last_activity_at to current time" do
      old_time = 1.hour.ago
      session = create(:portal_session, last_activity_at: old_time)

      session.touch_activity!

      expect(session.last_activity_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#mfa_verified?" do
    context "when mfa_verified_at is nil" do
      it "returns false" do
        session = build(:portal_session, mfa_verified_at: nil)
        expect(session.mfa_verified?).to be false
      end
    end

    context "when mfa_verified_at is within STEP_UP_DURATION" do
      it "returns true" do
        session = build(:portal_session, mfa_verified_at: Time.current)
        expect(session.mfa_verified?).to be true
      end
    end

    context "when mfa_verified_at is older than STEP_UP_DURATION" do
      it "returns false" do
        session = build(:portal_session, mfa_verified_at: 20.minutes.ago)
        expect(session.mfa_verified?).to be false
      end
    end
  end

  describe "#verify_mfa!" do
    it "sets mfa_verified_at to current time" do
      session = create(:portal_session, mfa_verified_at: nil)
      session.verify_mfa!
      expect(session.mfa_verified_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#expire_mfa_verification!" do
    it "sets mfa_verified_at to nil" do
      session = create(:portal_session, mfa_verified_at: Time.current)
      session.expire_mfa_verification!
      expect(session.mfa_verified_at).to be_nil
    end
  end
end
