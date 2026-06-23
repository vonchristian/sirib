require "rails_helper"

RSpec.describe Accounting::AccountStatusService do
  describe "#can_post?" do
    it "returns true when account is active and postable" do
      account = build(:accounting_account, status: :active, postable: true)
      service = described_class.new(account: account)
      expect(service.can_post?).to be true
    end

    it "returns false when account is inactive" do
      account = build(:accounting_account, status: :inactive, postable: true)
      service = described_class.new(account: account)
      expect(service.can_post?).to be false
    end

    it "returns false when account is non-postable" do
      account = build(:accounting_account, status: :active, postable: false)
      service = described_class.new(account: account)
      expect(service.can_post?).to be false
    end

    it "returns false when account is inactive and non-postable" do
      account = build(:accounting_account, status: :inactive, postable: false)
      service = described_class.new(account: account)
      expect(service.can_post?).to be false
    end
  end

  describe "#can_post!" do
    it "does not raise when account can post" do
      account = build(:accounting_account, status: :active, postable: true)
      service = described_class.new(account: account)
      expect { service.can_post! }.not_to raise_error
    end

    it "raises AccountNotPostableError when account cannot post" do
      account = build(:accounting_account, status: :inactive, postable: false)
      service = described_class.new(account: account)
      expect { service.can_post! }.to raise_error(Accounting::AccountNotPostableError)
    end
  end

  describe "#status_reason" do
    it "returns nil when account can post" do
      account = build(:accounting_account, status: :active, postable: true)
      service = described_class.new(account: account)
      expect(service.status_reason).to be_nil
    end

    it "returns reason when inactive" do
      account = build(:accounting_account, status: :inactive, postable: true)
      service = described_class.new(account: account)
      expect(service.status_reason).to eq("Account is inactive")
    end

    it "returns reason when non-postable" do
      account = build(:accounting_account, status: :active, postable: false)
      service = described_class.new(account: account)
      expect(service.status_reason).to eq("Account is marked as non-postable")
    end
  end

  describe "#activate!" do
    it "updates status to active" do
      account = create(:accounting_account, status: :inactive)
      service = described_class.new(account: account)
      service.activate!
      expect(account.status).to eq("active")
    end

    it "does nothing if already active" do
      account = create(:accounting_account, status: :active)
      service = described_class.new(account: account)
      expect { service.activate! }.not_to change(account, :status)
    end
  end

  describe "#deactivate!" do
    it "updates status to inactive" do
      account = create(:accounting_account, status: :active)
      service = described_class.new(account: account)
      service.deactivate!
      expect(account.status).to eq("inactive")
    end

    it "does nothing if already inactive" do
      account = create(:accounting_account, status: :inactive)
      service = described_class.new(account: account)
      expect { service.deactivate! }.not_to change(account, :status)
    end
  end

  describe "#toggle_postable!" do
    it "toggles postable from true to false" do
      account = create(:accounting_account, postable: true)
      service = described_class.new(account: account)
      service.toggle_postable!
      expect(account.postable).to be false
    end

    it "toggles postable from false to true" do
      account = create(:accounting_account, postable: false)
      service = described_class.new(account: account)
      service.toggle_postable!
      expect(account.postable).to be true
    end
  end
end