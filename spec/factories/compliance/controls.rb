FactoryBot.define do
  factory :compliance_control, class: 'Compliance::Control' do
    name { "MyString" }
    description { "MyText" }
    category { "MyString" }
    frequency { "MyString" }
    active { false }
    config { "" }
    cooperative { nil }
  end
end
