FactoryBot.define do
  factory :portal_announcement, class: "Portal::Announcement" do
    association :cooperative
    association :author, factory: :user
    title { "Test Announcement" }
    body { "This is a test announcement body." }
    status { "published" }
    published_at { Time.current }
  end
end