require "rails_helper"

RSpec.describe Treasury::SavingsAccount do
  describe "associations" do
    it { is_expected.to belong_to(:savings_product) }
    it { is_expected.to belong_to(:depositor) }
    it { is_expected.to belong_to(:liability_account).class_name("Accounting::Account").optional }
    it { is_expected.to belong_to(:interest_expense_account).class_name("Accounting::Account").optional }
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:account_type) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active closed]) }

    it "validates uniqueness of account_number" do
      create(:savings_account, account_number: "SA-UNIQUE")
      acc = build(:savings_account, account_number: "SA-UNIQUE")
      expect(acc).not_to be_valid
      expect(acc.errors[:account_number]).to be_present
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:savings_account)).to be_valid
    end
  end

  describe "#account_type enum" do
    it "defines personal and business" do
      expect(Treasury::SavingsAccount::ACCOUNT_TYPES).to eq(personal: 0, business: 1)
    end
  end

  describe "#account_number" do
    it "is auto-assigned on create" do
      account = create(:savings_account)
      expect(account.account_number).to match(/\ASA-\d{8}-[A-F0-9]{6}\z/)
    end
  end

  describe "#depositor_name" do
    it "delegates to the depositor" do
      member = build(:member, first_name: "Juan", middle_name: "Santos", last_name: "Dela Cruz")
      account = build(:savings_account, depositor: member)
      expect(account.depositor_name).to eq("Juan Santos Dela Cruz")
    end
  end

end
