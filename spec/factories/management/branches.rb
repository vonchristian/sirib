FactoryBot.define do
  factory :branch, class: "Management::Branch" do
    sequence(:code) { |n| "BR#{n.to_s.rjust(4, '0')}" }
    sequence(:name) { |n| "Branch #{n}" }
    status { :active }
    cooperative

    trait :inactive do
      status { :inactive }
    end
  end
end