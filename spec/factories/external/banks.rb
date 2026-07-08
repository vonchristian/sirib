FactoryBot.define do
  factory :external_bank, class: "External::Bank" do
    name { "Test Bank" }
    code { "TBK" }
    country { "Philippines" }
    status { "active" }
  end
end
