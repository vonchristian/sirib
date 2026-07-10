require "rails_helper"

RSpec.describe Accounting::ChartOfAccountsService do
  subject(:service) { described_class.new(cooperative: cooperative) }

  let(:cooperative) { create(:cooperative) }

  before do
    Current.cooperative = cooperative
  end

  def with_cooperative
    Current.set(cooperative: cooperative) { yield }
  end

  describe "#search" do
    let!(:ledger) { create(:accounting_ledger, cooperative: cooperative, name: "Cash and Cash Equivalents", account_code: "11100") }
    let!(:account) { create(:accounting_account, cooperative: cooperative, ledger: ledger, name: "Cash on Hand", account_code: "11110") }

    it "returns ledgers matching by name" do
      result = service.search("Cash")
      expect(result[:ledgers]).to include(ledger)
    end

    it "returns accounts matching by name" do
      result = service.search("Cash")
      expect(result[:accounts]).to include(account)
    end

    it "returns ledgers matching by account_code" do
      result = service.search("11100")
      expect(result[:ledgers]).to include(ledger)
    end

    it "returns accounts matching by account_code" do
      result = service.search("11110")
      expect(result[:accounts]).to include(account)
    end

    it "returns empty arrays for blank query" do
      result = service.search("")
      expect(result[:ledgers]).to be_empty
      expect(result[:accounts]).to be_empty
    end

    it "returns empty arrays when no matches" do
      result = service.search("zzzzz")
      expect(result[:ledgers]).to be_empty
      expect(result[:accounts]).to be_empty
    end
  end

  describe "#tree_data" do
    let!(:root_ledger) { create(:accounting_ledger, cooperative: cooperative, name: "Assets", account_code: "10000") }
    let!(:child_ledger) { create(:accounting_ledger, cooperative: cooperative, parent: root_ledger, name: "Current Assets", account_code: "11000") }
    let!(:account) { create(:accounting_account, cooperative: cooperative, ledger: child_ledger, account_type: :asset) }

    it "returns root nodes" do
      tree = service.tree_data
      expect(tree.size).to eq(1)
      expect(tree.first[:ledger]).to eq(root_ledger)
    end

    it "includes children nodes" do
      tree = service.tree_data
      expect(tree.first[:children].size).to eq(1)
      expect(tree.first[:children].first[:ledger]).to eq(child_ledger)
    end

    it "includes account count" do
      tree = service.tree_data
      expect(tree.first[:account_count]).to eq(1)
      expect(tree.first[:children].first[:account_count]).to eq(1)
    end

    it "includes has_children flag" do
      tree = service.tree_data
      expect(tree.first[:has_children]).to be true
      expect(tree.first[:children].first[:has_children]).to be false
    end

    it "includes balance" do
      with_cooperative do
        AppendOnlyOverride.with_override(reason: "test setup") do
          entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.current)
          entry.amount_lines.first.update!(account: account, cooperative: cooperative, amount_cents: 5000)
          entry.amount_lines.last.update!(account: account, cooperative: cooperative, amount_cents: 5000)
        end
      end

      tree = service.tree_data
      expect(tree.first[:balance]).to be_a(Money)
    end
  end

  describe "#accounts_list" do
    let!(:ledger) { create(:accounting_ledger, cooperative: cooperative) }
    let!(:asset_account) { create(:accounting_account, cooperative: cooperative, ledger: ledger, account_type: :asset, name: "Cash") }
    let!(:liability_account) { create(:accounting_account, cooperative: cooperative, ledger: ledger, account_type: :liability, name: "Loan Payable") }

    it "returns all accounts when no filters" do
      accounts = service.accounts_list
      expect(accounts).to contain_exactly(asset_account, liability_account)
    end

    it "filters by account_type" do
      accounts = service.accounts_list(account_type: "asset")
      expect(accounts).to contain_exactly(asset_account)
    end

    it "filters by search" do
      accounts = service.accounts_list(search: "Cash")
      expect(accounts).to contain_exactly(asset_account)
    end

    it "filters by ledger_id" do
      other_ledger = create(:accounting_ledger, cooperative: cooperative)
      other_account = create(:accounting_account, cooperative: cooperative, ledger: other_ledger)
      accounts = service.accounts_list(ledger_id: ledger.id)
      expect(accounts).to contain_exactly(asset_account, liability_account)
    end

    it "orders by account_code" do
      accounts = service.accounts_list
      expect(accounts).to eq(accounts.sort_by(&:account_code))
    end
  end

  describe "#account_inspector" do
    let!(:ledger) { create(:accounting_ledger, cooperative: cooperative, name: "Cash") }
    let!(:parent_ledger) { create(:accounting_ledger, cooperative: cooperative, name: "Assets") }
    let!(:account) { create(:accounting_account, cooperative: cooperative, ledger: ledger) }

    before do
      ledger.update!(parent: parent_ledger)
    end

    it "returns inspector data with account" do
      inspector = service.account_inspector(account.id)
      expect(inspector[:account]).to eq(account)
    end

    it "includes ledger path" do
      inspector = service.account_inspector(account.id)
      expect(inspector[:ledger_path]).to include("Assets")
      expect(inspector[:ledger_path]).to include("Cash")
    end

    it "includes recent lines" do
      with_cooperative do
        AppendOnlyOverride.with_override(reason: "test setup") do
          entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.current)
          entry.amount_lines.first.update!(account: account, cooperative: cooperative)
          entry.amount_lines.last.update!(account: account, cooperative: cooperative)
        end
      end

      inspector = service.account_inspector(account.id)
      expect(inspector[:recent_lines].size).to eq(2)
    end

    it "includes debit and credit totals" do
      with_cooperative do
        AppendOnlyOverride.with_override(reason: "test setup") do
          entry = create(:accounting_entry, cooperative: cooperative, posted_at: Time.current)
          entry.amount_lines.first.update!(account: account, cooperative: cooperative, amount_type: "debit", amount_cents: 10000)
          entry.amount_lines.last.update!(account: account, cooperative: cooperative, amount_type: "credit", amount_cents: 4000)
        end
      end

      inspector = service.account_inspector(account.id)
      expect(inspector[:debit_total]).to eq(Money.new(10000, "PHP"))
      expect(inspector[:credit_total]).to eq(Money.new(4000, "PHP"))
    end

    it "raises not found for invalid id" do
      expect { service.account_inspector(999_999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
