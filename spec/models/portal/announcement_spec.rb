require "rails_helper"

RSpec.describe Portal::Announcement do
  describe "associations" do
    it { should belong_to(:cooperative) }
    it { should belong_to(:author).class_name("User") }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:body) }
    it { should validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "scopes" do
    describe ".published" do
      it "returns announcements with status published and published_at in the past" do
        published = create(:portal_announcement, status: "published", published_at: Time.current)
        draft = create(:portal_announcement, status: "draft", published_at: Time.current)
        future_published = create(:portal_announcement, status: "published", published_at: 1.day.from_now)

        expect(described_class.published).to include(published)
        expect(described_class.published).not_to include(draft)
        expect(described_class.published).not_to include(future_published)
      end
    end

    describe ".by_latest" do
      it "orders by published_at descending" do
        older = create(:portal_announcement, published_at: 1.day.ago)
        newer = create(:portal_announcement, published_at: Time.current)

        expect(described_class.by_latest.first).to eq(newer)
        expect(described_class.by_latest.last).to eq(older)
      end
    end

    describe ".for_cooperative" do
      it "returns announcements for the specified cooperative" do
        coop1 = create(:cooperative)
        coop2 = create(:cooperative)
        announcement1 = create(:portal_announcement, cooperative: coop1)
        announcement2 = create(:portal_announcement, cooperative: coop2)

        expect(described_class.for_cooperative(coop1)).to include(announcement1)
        expect(described_class.for_cooperative(coop1)).not_to include(announcement2)
      end
    end

    describe ".published_for" do
      it "combines published and for_cooperative scopes" do
        coop = create(:cooperative)
        announcement = create(:portal_announcement, cooperative: coop, status: "published", published_at: Time.current)
        wrong_coop = create(:portal_announcement, status: "published", published_at: Time.current)

        result = described_class.published_for(coop)
        expect(result).to include(announcement)
        expect(result).not_to include(wrong_coop)
      end
    end
  end

  describe "#publish!" do
    it "sets status to published and sets published_at" do
      announcement = build(:portal_announcement, status: "draft", published_at: nil)

      announcement.publish!

      expect(announcement.status).to eq("published")
      expect(announcement.published_at).not_to be_nil
      expect(announcement.published_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#archive!" do
    it "sets status to archived" do
      announcement = build(:portal_announcement, status: "published")

      announcement.archive!

      expect(announcement.status).to eq("archived")
    end
  end
end