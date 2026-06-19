FactoryBot.define do
  factory :messaging_provider_webhook, class: "Messaging::ProviderWebhook" do
    association :provider, factory: :messaging_provider
    sequence(:event_type) { |n| ["delivered", "failed", "bounced"][n % 3] }
    payload { {} }
    processed_at { nil }
  end
end