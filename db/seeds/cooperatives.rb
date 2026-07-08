puts "\n=== Creating Cooperatives ==="

COOPERATIVES = [
  { name: "Main Cooperative",        address: "123 Main Street, Makati City",              contact_number: "+63-2-555-0001", registration_number: "COOP-REG-001" },
  { name: "Masaganang Ani",          address: "456 Rizal Street, Cabanatuan City",          contact_number: "+63-44-555-0002", registration_number: "COOP-REG-002" },
  { name: "Samahang Magsasaka",      address: "789 Mabini Street, Lingayen",               contact_number: "+63-75-555-0003", registration_number: "COOP-REG-003" },
  { name: "Tulay ng Pag-asa",        address: "321 Colon Street, Cebu City",               contact_number: "+63-32-555-0004", registration_number: "COOP-REG-004" },
  { name: "Kasaganaan Cooperative",  address: "654 Torres Street, Davao City",             contact_number: "+63-82-555-0005", registration_number: "COOP-REG-005" },
  { name: "Bagong Bukas",            address: "987 Pagsanjan Road, Santa Cruz, Laguna",    contact_number: "+63-49-555-0006", registration_number: "COOP-REG-006" },
  { name: "Sama-sama Cooperative",   address: "147 Laurel Street, Batangas City",          contact_number: "+63-43-555-0007", registration_number: "COOP-REG-007" },
  { name: "Liwanag Cooperative",     address: "258 Roxas Street, San Fernando, Pampanga",  contact_number: "+63-45-555-0008", registration_number: "COOP-REG-008" },
  { name: "Pagkakaisa Cooperative",  address: "369 Delgado Street, Iloilo City",           contact_number: "+63-33-555-0009", registration_number: "COOP-REG-009" },
  { name: "Asenso Cooperative",      address: "741 Velez Street, Cagayan de Oro City",    contact_number: "+63-88-555-0010", registration_number: "COOP-REG-010" }
]

COOPERATIVES.each_with_index do |attrs, i|
  coop = Cooperative.find_or_initialize_by(name: attrs[:name])
  if coop.persisted?
    puts "  ✓ #{coop.name} (already exists)"
    next
  end

  coop.assign_attributes(
    name: attrs[:name],
    address: attrs[:address],
    contact_number: attrs[:contact_number],
    registration_number: attrs[:registration_number],
    status: "active"
  )
  coop.save!

  puts "  ✓ #{coop.name}"
end

puts "\n  Total cooperatives: #{Cooperative.count}"
