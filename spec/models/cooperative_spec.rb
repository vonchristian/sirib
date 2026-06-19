require "rails_helper"

RSpec.describe Cooperative, type: :model do
  subject(:cooperative) { build(:cooperative) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates schema_name subdomain presence" do
      coop = described_class.new(name: nil, schema_name: nil, subdomain: nil)
      coop.valid?
      expect(coop.errors[:schema_name]).to include("can't be blank")
      expect(coop.errors[:subdomain]).to include("can't be blank")
    end

    it "validates schema_name uniqueness" do
      create(:cooperative, schema_name: "tenant_unique")
      coop = build(:cooperative, schema_name: "tenant_unique")
      coop.valid?
      expect(coop.errors[:schema_name]).to include("has already been taken")
    end

    it "validates subdomain uniqueness" do
      create(:cooperative, subdomain: "unique-coop")
      coop = build(:cooperative, subdomain: "unique-coop")
      coop.valid?
      expect(coop.errors[:subdomain]).to include("has already been taken")
    end

    it "validates schema_name format" do
      cooperative.schema_name = "Invalid Schema!"
      expect(cooperative).not_to be_valid
      expect(cooperative.errors[:schema_name]).to be_present
    end

    it "validates subdomain format" do
      cooperative.subdomain = "Invalid Subdomain!"
      expect(cooperative).not_to be_valid
      expect(cooperative.errors[:subdomain]).to be_present
    end

    it "rejects invalid status values" do
      expect { cooperative.status = "invalid" }.to raise_error(ArgumentError)
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:destroy) }
    it { is_expected.to have_many(:branches).dependent(:destroy) }
    it { is_expected.to have_many(:membership_applications).dependent(:destroy) }
    it { is_expected.to belong_to(:vault_account).optional }
  end

  describe "scopes" do
    let!(:active_coop) { create(:cooperative, status: "active") }
    let!(:inactive_coop) { create(:cooperative, status: "inactive") }

    describe ".active" do
      it "returns only active cooperatives" do
        expect(described_class.active).to include(active_coop)
        expect(described_class.active).not_to include(inactive_coop)
      end
    end
  end

  describe "callbacks" do
    context "on create" do
      it "auto-generates schema_name from name" do
        coop = create(:cooperative, name: "Test Coop", schema_name: nil, subdomain: "test-coop")
        expect(coop.schema_name).to be_present
      end

      it "auto-generates subdomain from name" do
        coop = create(:cooperative, name: "Test Coop", schema_name: "test_coop", subdomain: nil)
        expect(coop.subdomain).to be_present
      end

      it "handles duplicate schema names" do
        create(:cooperative, name: "Test Coop", schema_name: "tenant_test_coop", subdomain: "test-coop")
        coop2 = build(:cooperative, name: "Test Coop", schema_name: nil, subdomain: "test-coop-2")
        coop2.save!
        expect(coop2.schema_name).not_to eq("tenant_test_coop")
      end
    end
  end

  describe "#provision!" do
    let(:cooperative) { create(:cooperative, schema_name: "provision_spec_coop", status: "inactive") }

    after do
      Tenant::SchemaManager.drop_schema(cooperative.schema_name)
    end

    it "creates schema and seeds data" do
      cooperative.provision!
      expect(cooperative.reload).to be_status_active
      expect(cooperative.provisioned_at).to be_present
    end
  end

  describe "#deactivate! / #activate!" do
    let(:cooperative) { create(:cooperative) }

    it "deactivates the cooperative" do
      cooperative.deactivate!
      expect(cooperative.reload).to be_status_inactive
    end

    it "reactivates the cooperative" do
      cooperative.deactivate!
      cooperative.activate!
      expect(cooperative.reload).to be_status_active
    end
  end
end
