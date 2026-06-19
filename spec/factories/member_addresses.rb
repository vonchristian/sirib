FactoryBot.define do
  factory :member_address, class: "Membership::Address" do
    member
    house_street { "123 Rizal St" }
    barangay { "Barangay 1" }
    city { "Manila" }
    province { "Metro Manila" }
    region { "NCR" }
    zip_code { "1000" }
  end
end
