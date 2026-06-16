require "rails_helper"

RSpec.describe Member do
  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:birth_date) }
    it { is_expected.to validate_presence_of(:gender) }
    it { is_expected.to validate_presence_of(:civil_status) }
    it { is_expected.to validate_presence_of(:mobile_number) }
    it { is_expected.to validate_inclusion_of(:gender).in_array(%w[male female]) }
    it { is_expected.to validate_inclusion_of(:civil_status).in_array(%w[single married divorced widowed]) }

    context "when email is present" do
      subject { build(:member, email_address: "test@example.com") }
      it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:address).dependent(:destroy) }
    it { is_expected.to have_many(:identifications).dependent(:destroy) }
  end

  describe "BIR identification requirement" do
    it "is valid with a BIR identification" do
      member = build(:member)
      expect(member).to be_valid
    end

    it "is invalid without a BIR identification" do
      member = build(:member)
      member.identifications = [build(:member_identification, id_type: "Passport", id_number: "P123")]
      expect(member).not_to be_valid
      expect(member.errors[:identifications]).to include("must include at least one BIR identification")
    end
  end

  describe "#name" do
    it "returns the full name" do
      member = build(:member, first_name: "Juan", middle_name: "Santos", last_name: "Dela Cruz")
      expect(member.name).to eq("Juan Santos Dela Cruz")
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:member)).to be_valid
    end
  end
end
