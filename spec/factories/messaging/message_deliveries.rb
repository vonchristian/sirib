FactoryBot.define do
  factory :messaging_message_delivery, class: "Messaging::MessageDelivery" do
    association :message, factory: :messaging_message
    association :channel, factory: :messaging_channel
    provider { nil }
    status { "queued" }
    attempts_count { 0 }
    last_error { nil }
    provider_message_id { nil }
    sent_at { nil }
    delivered_at { nil }
  end
end