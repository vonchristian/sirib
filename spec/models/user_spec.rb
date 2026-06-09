require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to have_secure_password }

    it "validates presence of email_address" do
      user.password = "password123"
      user.email_address = ""
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("can't be blank")
    end

    it "validates uniqueness of email_address" do
      create(:user, email_address: "test@example.com")
      user = build(:user, email_address: "test@example.com", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("has already been taken")
    end

    it "validates uniqueness is case-insensitive" do
      create(:user, email_address: "test@example.com")
      user = build(:user, email_address: "TEST@example.com", password: "password123")
      expect(user).not_to be_valid
      expect(user.errors[:email_address]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "normalizations" do
    it "strips and downcases email before saving" do
      user = create(:user, email_address: "  USER@Example.COM  ")
      expect(user.email_address).to eq("user@example.com")
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:user)).to be_valid
    end
  end
end
