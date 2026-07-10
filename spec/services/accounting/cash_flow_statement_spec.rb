require "rails_helper"

RSpec.describe Accounting::CashFlowStatement do
  describe "#execute" do
    let(:user) { create(:user) }
    let(:asset_account) { create(:accounting_account, account_type: :asset) }
    let(:revenue_account) { create(:accounting_account, account_type: :revenue) }
    let(:expense_account) { create(:accounting_account, account_type: :expense) }

    it "returns a hash with sections, net_change, and cash totals" do
      create(:accounting_cash_account, user:, account: asset_account)
      create(:accounting_entry, posted_at: Time.current).tap do |entry|
        create(:accounting_amount_line, entry:, account: asset_account, amount_type: "debit", amount_cents: 10000)
        create(:accounting_amount_line, entry:, account: asset_account, amount_type: "credit", amount_cents: 1)
      end

      result = described_class.run!(
        from_date: 1.month.ago.to_date,
        to_date: Date.current,
        user:
      )

      expect(result).to have_key(:sections)
      expect(result).to have_key(:net_change)
      expect(result).to have_key(:cash_at_beginning)
      expect(result).to have_key(:cash_at_end)
    end
  end
end
