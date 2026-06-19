FactoryBot.define do
  factory :member, class: "Membership::Member" do
    first_name { "Juan" }
    middle_name { "Santos" }
    last_name { "Dela Cruz" }
    birth_date { 30.years.ago.to_date }
    gender { "male" }
    civil_status { "single" }
    mobile_number { "09171234567" }

    after(:build) do |member|
      member.build_address(
        house_street: "123 Rizal St",
        barangay: "Barangay 1",
        city: "Manila",
        province: "Metro Manila",
        region: "NCR"
      )
      member.identifications.build(id_type: "BIR", id_number: "BIR-123-456-789")
    end
  end
end
