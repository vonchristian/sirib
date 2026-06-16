FactoryBot.define do
  factory :savings_account, class: "Treasury::SavingsAccount" do
    savings_product
    association :depositor, factory: :member
    account_type { :personal }
    status { "active" }
  end
end
