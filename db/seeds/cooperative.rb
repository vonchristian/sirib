puts "Seeding cooperative..."

coop = Cooperative.first_or_initialize(name: "Main Cooperative")
if coop.new_record?
  coop.save!
end

cash_on_hand = Accounting::Account.find_by(account_code: "11110")
if cash_on_hand && coop.vault_account_id.nil?
  coop.update!(vault_account: cash_on_hand)
  puts "  → Vault account set to #{cash_on_hand.name} (#{cash_on_hand.account_code})"
end

puts "  → #{coop.name}"
