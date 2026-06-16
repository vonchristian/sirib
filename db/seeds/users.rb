puts "Seeding users..."

user = User.find_or_create_by!(email_address: "admin@example.com") do |u|
  u.password = "password123"
  u.role = :manager
end

cash_account = Accounting::Account.find_by(account_code: "11110")
if cash_account
  Accounting::CashAccount.find_or_create_by!(user: user, account: cash_account)
end

puts "  \u2192 1 user with cash account link"
