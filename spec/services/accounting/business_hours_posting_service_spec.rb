require "rails_helper"

RSpec.describe Accounting::BusinessHoursPostingService do
  let(:cooperative) { create(:cooperative) }

  around do |example|
    Current.set(cooperative: cooperative) { example.run }
  end

  describe ".post" do
    let(:asset_account) { create(:accounting_account, account_type: :asset, cooperative: cooperative) }
    let(:liability_account) { create(:accounting_account, account_type: :liability, cooperative: cooperative) }

    it "posts immediately when post_immediately: true" do
      result = described_class.post(
        cooperative: cooperative,
        description: "Test",
        post_immediately: true,
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_posted
    end

    it "defers posting when post_immediately: false" do
      result = described_class.post(
        cooperative: cooperative,
        description: "Test",
        post_immediately: false,
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_pending
    end

    it "checks business hours when post_immediately is nil" do
      allow_any_instance_of(Management::BusinessDayService).to receive(:within_business_hours?).and_return(false)

      result = described_class.post(
        cooperative: cooperative,
        description: "Test",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_pending
    end

    it "posts immediately during business hours when post_immediately is nil" do
      allow_any_instance_of(Management::BusinessDayService).to receive(:within_business_hours?).and_return(true)

      result = described_class.post(
        cooperative: cooperative,
        description: "Test",
        debits: [ { account: asset_account, amount: 10000 } ],
        credits: [ { account: liability_account, amount: 10000 } ]
      )
      expect(result).to be_posted
    end
  end
end
