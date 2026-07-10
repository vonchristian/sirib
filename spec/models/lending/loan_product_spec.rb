require "rails_helper"

RSpec.describe Lending::LoanProduct do
  describe "associations" do
    it { is_expected.to have_many(:loan_applications).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:loans).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:loan_charges).dependent(:destroy) }
    it { is_expected.to have_many(:versions).class_name("Lending::LoanProductVersion") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:interest_rate).is_greater_than(0).is_less_than_or_equal_to(100) }
    it { is_expected.to validate_inclusion_of(:interest_calculation).in_array(%w[straight_line declining_balance]) }
    it { is_expected.to validate_numericality_of(:max_term_months).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active inactive]) }
  end

  describe "scopes" do
    let!(:active_product) { create(:lending_loan_product, status: "active") }
    let!(:inactive_product) { create(:lending_loan_product, status: "inactive") }

    it "scopes active" do
      expect(described_class.active).to contain_exactly(active_product)
    end
  end

  describe "#current_snapshot" do
    it "returns attributes without id, cooperative_id, timestamps, and version" do
      product = create(:lending_loan_product, name: "Test Product", interest_rate: 2.5)
      snapshot = product.current_snapshot

      expect(snapshot).to include(
        "name" => "Test Product",
        "interest_rate" => 2.5,
        "interest_calculation" => "declining_balance",
        "max_term_months" => 24,
        "status" => "active"
      )
      expect(snapshot).not_to include("id", "cooperative_id", "created_at", "updated_at", "version")
    end
  end

  describe "versioning" do
    it "starts with version 1" do
      product = create(:lending_loan_product)
      expect(product.version).to eq(1)
    end

    it "increments version on update" do
      product = create(:lending_loan_product)
      expect { product.update!(name: "Updated Name") }
        .to change { product.reload.version }.from(1).to(2)
    end

    it "creates a version record on update" do
      product = create(:lending_loan_product)
      expect { product.update!(name: "Updated Name") }
        .to change(Lending::LoanProductVersion, :count).by(1)
    end

    it "stores the updated snapshot in the version record" do
      product = create(:lending_loan_product, name: "Original Name")
      product.update!(name: "Updated Name")
      version = product.versions.last

      expect(version.version).to eq(2)
      expect(version.snapshot).to include("name" => "Updated Name")
    end

    it "does not create a version record on create" do
      expect { create(:lending_loan_product) }
        .not_to change(Lending::LoanProductVersion, :count)
    end

    it "stores change_reason in version record" do
      product = create(:lending_loan_product)
      product.update!(name: "Updated")

      version = product.versions.last
      expect(version.change_reason).to be_present
    end
  end

  describe "factory" do
    it "creates a valid record" do
      expect(build(:lending_loan_product)).to be_valid
    end
  end
end
