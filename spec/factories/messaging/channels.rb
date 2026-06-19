FactoryBot.define do
  factory :messaging_channel, class: "Messaging::Channel" do
    sequence(:name) { |n| "channel_#{n}" }
    enabled { true }
  end
end