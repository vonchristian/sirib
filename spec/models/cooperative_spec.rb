require "rails_helper"

RSpec.describe Cooperative, type: :model do
  subject(:cooperative) { build(:cooperative) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
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

  describe "#deactivate! / #activate!" do
    let(:cooperative) { create(:cooperative) }

    it "deactivates the cooperative" do
      cooperative.deactivate!
      expect(cooperative.reload.status).to eq("inactive")
    end

    it "reactivates the cooperative" do
      cooperative.deactivate!
      cooperative.activate!
      expect(cooperative.reload.status).to eq("active")
    end
  end
end
