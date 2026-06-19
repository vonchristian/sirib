require "rails_helper"

RSpec.describe Membership::Identification do
  describe "validations" do
    it { is_expected.to validate_presence_of(:id_type) }
    it { is_expected.to validate_presence_of(:id_number) }
    it { is_expected.to validate_inclusion_of(:id_type).in_array(Membership::Identification::ID_TYPES) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:member) }
  end

  describe "factory" do
    it "creates a valid record" do
      member = create(:member)
      identification = build(:member_identification, member: member)
      expect(identification).to be_valid
    end
  end
end
