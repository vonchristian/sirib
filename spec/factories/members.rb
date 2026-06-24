FactoryBot.define do
  sequence(:member_id_number) { |n| "BIR-#{n.to_s.rjust(9, '0')}" }

  factory :member, class: "Membership::Member" do
    cooperative
    first_name { "Juan" }
    middle_name { "Santos" }
    last_name { "Dela Cruz" }
    birth_date { 30.years.ago.to_date }
    gender { "male" }
    civil_status { "single" }
    mobile_number { "09171234567" }

    after(:build) do |member|
      member.build_address(
        cooperative: member.cooperative,
        house_street: "123 Rizal St",
        barangay: "Barangay 1",
        city: "Manila",
        province: "Metro Manila",
        region: "NCR"
      )
      member.identifications.build(
        cooperative: member.cooperative,
        id_type: "BIR",
        id_number: generate(:member_id_number)
      )
    end
  end
end
