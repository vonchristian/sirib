FactoryBot.define do
  factory :saved_filter do
    user
    name { "My Filter" }
    filters { { "start_date" => "2026-01-01", "end_date" => "2026-01-31" } }
    filter_type { "journal_entry" }
    is_shared { false }
    is_default { false }

    trait :shared do
      is_shared { true }
    end

    trait :default do
      is_default { true }
    end

    trait :trial_balance do
      filter_type { "trial_balance" }
    end
  end
end