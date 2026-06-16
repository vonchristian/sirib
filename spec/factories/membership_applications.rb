FactoryBot.define do
  factory :membership_application do
    cooperative { Cooperative.first_or_create!(name: "Test Cooperative") }
    first_name { "Juan" }
    last_name { "Dela Cruz" }
    birth_date { 30.years.ago.to_date }
    gender { "male" }
    civil_status { "single" }
    mobile_number { "09171234567" }
    house_street { "123 Rizal St" }
    barangay { "Barangay 1" }
    city { "Manila" }
    province { "Metro Manila" }
    region { "NCR" }
    sources_of_income { [{ "source_type" => "Employment", "monthly_income" => "50000" }] }
    identifications { [{ "id_type" => "BIR", "id_number" => "BIR-123-456" }] }
    signature_specimens { [
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    ] }
    profile_images { [
      "data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
    ] }
  end
end
