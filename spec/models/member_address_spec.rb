require "rails_helper"

RSpec.describe MemberAddress do
  describe "validations" do
    it { is_expected.to validate_presence_of(:house_street) }
    it { is_expected.to validate_presence_of(:barangay) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:province) }
    it { is_expected.to validate_presence_of(:region) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:member) }
  end

  describe "factory" do
    it "creates a valid record" do
      member = create(:member)
      address = build(:member_address, member: member)
      expect(address).to be_valid
    end
  end
end
