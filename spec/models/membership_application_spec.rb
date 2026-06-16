require "rails_helper"

RSpec.describe MembershipApplication do
  describe "validations" do
    subject { build(:membership_application) }

    it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft completed approved rejected]) }
  end

  describe "callbacks" do
    it "assigns a UUID before validation on create" do
      app = MembershipApplication.new(cooperative: create(:cooperative))
      app.validate
      expect(app.uuid).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:cooperative) }
  end

  describe "#assign_uuid" do
    it "assigns a UUID on create" do
      app = create(:membership_application)
      expect(app.uuid).to be_present
      expect(app.uuid).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe "#complete?" do
    it "returns true when all steps are valid" do
      app = build(:membership_application)
      expect(app).to be_complete
    end

    it "returns false when personal details are missing" do
      app = build(:membership_application, first_name: nil)
      expect(app).not_to be_complete
    end

    it "returns false when address is missing" do
      app = build(:membership_application, house_street: nil)
      expect(app).not_to be_complete
    end

    it "returns false when no identifications" do
      app = build(:membership_application, identifications: [])
      expect(app).not_to be_complete
    end

    it "returns false when fewer than 3 signature specimens" do
      app = build(:membership_application, signature_specimens: [])
      expect(app).not_to be_complete
    end

    it "returns true with 3 or more signature specimens" do
      app = build(:membership_application, signature_specimens: %w[a b c d])
      expect(app).to be_complete
    end

    it "returns false when no profile images" do
      app = build(:membership_application, profile_images: [])
      expect(app).not_to be_complete
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:membership_application)).to be_valid
    end
  end
end
