require "rails_helper"

RSpec.describe ApproveMembershipApplication do
  describe ".call" do
    it "creates member, address, and identifications from application data" do
      app = create(:membership_application, status: "completed")

      expect {
        described_class.call(app)
      }.to change(Member, :count).by(1)
        .and change(MemberAddress, :count).by(1)
        .and change(MemberIdentification, :count).by(1)

      member = Member.last
      expect(member.first_name).to eq("Juan")
      expect(member.last_name).to eq("Dela Cruz")
      expect(member.address.city).to eq("Manila")
      expect(member.identifications.first.id_type).to eq("BIR")
      expect(app.reload.status).to eq("approved")
    end

    it "attaches all signature specimens and profile image" do
      app = create(:membership_application, status: "completed")

      member = described_class.call(app)

      expect(member.signatures).to be_attached
      expect(member.signatures.count).to eq(3)
      expect(member.profile_image).to be_attached
    end
  end
end
