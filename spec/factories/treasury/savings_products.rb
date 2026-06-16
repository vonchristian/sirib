FactoryBot.define do
  factory :savings_product, class: "Treasury::SavingsProduct" do
    name { "Regular Savings" }
    description { "Standard savings account" }
    status { "active" }
  end
end
