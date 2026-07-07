FactoryBot.define do
  factory :management_holiday, class: "Management::Holiday" do
    cooperative
    date { Date.new(2026, 12, 25) }
    name { "Christmas Day" }
    recurring { false }
  end
end
