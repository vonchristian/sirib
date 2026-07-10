module AccountingHelpers
  def create_accounting_entry(overrides = {})
    account = overrides.delete(:account) || create(:accounting_account)
    entry = build(:accounting_entry, { create_lines: false }.merge(overrides))
    entry.amount_lines.build(amount_type: "debit", amount_cents: 1, account: account)
    entry.amount_lines.build(amount_type: "credit", amount_cents: 1, account: account)
    entry.save!
    entry
  end
end

RSpec.configure do |config|
  config.include AccountingHelpers
end
