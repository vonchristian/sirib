FactoryBot.define do
  factory :messaging_provider, class: "Messaging::Provider" do
    association :channel, factory: :messaging_channel
    sequence(:name) { |n| [ "sendgrid", "ses", "facebook" ][n % 3] }
    config { {} }
    enabled { true }
  end
end
