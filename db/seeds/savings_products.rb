# Savings products
liability_ledger = Accounting::Ledger.find_by(account_code: "21100")
expense_ledger = Accounting::Ledger.find_by(account_code: "60230") || Accounting::Ledger.where(account_type: :expense).first

savings_products = [
  { name: "Regular Savings", description: "Standard savings account with competitive interest" },
  { name: "Youth Savings", description: "Savings account for members under 18" },
  { name: "Business Savings", description: "High-yield savings for business accounts" },
]

savings_products.each do |attrs|
  product = Treasury::SavingsProduct.find_or_create_by!(name: attrs[:name]) do |p|
    p.description = attrs[:description]
    p.liability_ledger = liability_ledger
    p.interest_expense_ledger = expense_ledger
  end

  product.interest_rates.find_or_create_by!(current: true) do |ir|
    ir.rate = 0.0025
  end
end

puts "Seeded #{Treasury::SavingsProduct.count} savings products"
