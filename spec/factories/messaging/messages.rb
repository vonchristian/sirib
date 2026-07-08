FactoryBot.define do
  factory :messaging_message, class: "Messaging::Message" do
    sequence(:message_type) { |n| Messaging::MESSAGE_TYPES[n % Messaging::MESSAGE_TYPES.size] }
    recipient_type { "Membership::Member" }
    recipient_id { SecureRandom.uuid }
    payload { { subject: "Test Subject", body: "Test body content" } }
    status { "pending" }
    scheduled_at { nil }
  end
end
