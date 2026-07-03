puts "  Creating loan aging groups..."

groups = [
  { name: "Current", min_days: 0, max_days: 0, display_order: 0 },
  { name: "1-30 Days", min_days: 1, max_days: 30, display_order: 1 },
  { name: "31-60 Days", min_days: 31, max_days: 60, display_order: 2 },
  { name: "61-90 Days", min_days: 61, max_days: 90, display_order: 3 },
  { name: "91-180 Days", min_days: 91, max_days: 180, display_order: 4 },
  { name: "Over 180 Days", min_days: 181, max_days: nil, display_order: 5 }
]

Cooperative.find_each do |coop|
  groups.each do |attrs|
    Lending::LoanAgingGroup.find_or_create_by!(
      cooperative: coop,
      name: attrs[:name]
    ) do |g|
      g.min_days = attrs[:min_days]
      g.max_days = attrs[:max_days]
      g.display_order = attrs[:display_order]
    end
  end
end

puts "  Created #{Lending::LoanAgingGroup.count} loan aging groups"
