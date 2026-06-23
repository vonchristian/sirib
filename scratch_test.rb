coop = Cooperative.first
exp_lines = Accounting::AmountLine.joins(:entry).where(cooperative_id: coop.id).where(
  "entries.reference_number LIKE 'SAL-%' OR entries.reference_number LIKE 'RNT-%' OR entries.reference_number LIKE 'UTL-%' OR entries.reference_number LIKE 'TEL-%'"
)

dr = exp_lines.debit.sum(:amount_cents) || 0
cr = exp_lines.credit.sum(:amount_cents) || 0
puts "Expense DR=#{dr} CR=#{cr} DIFF=#{dr - cr}"
puts "Count: #{exp_lines.count}"

# Check each type
["SAL", "RNT", "UTL", "TEL"].each do |type|
  lines = Accounting::AmountLine.joins(:entry).where(cooperative_id: coop.id).where("entries.reference_number LIKE ?", "#{type}-%")
  dr_t = lines.debit.sum(:amount_cents) || 0
  cr_t = lines.credit.sum(:amount_cents) || 0
  puts "  #{type}: DR=#{dr_t} CR=#{cr_t} DIFF=#{dr_t - cr_t}"
end

puts ""
all_dr = Accounting::AmountLine.joins(:entry).where(cooperative_id: coop.id).debit.sum(:amount_cents) || 0
all_cr = Accounting::AmountLine.joins(:entry).where(cooperative_id: coop.id).credit.sum(:amount_cents) || 0
puts "OVERALL: DR=#{all_dr} CR=#{all_cr} DIFF=#{all_dr - all_cr}"