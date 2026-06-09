require "rails_helper"

RSpec.describe Session do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:session)).to be_valid
    end
  end
end
