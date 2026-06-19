class Portal::Announcement < ApplicationRecord
  STATUSES = %w[draft published archived].freeze

  belongs_to :cooperative
  belongs_to :author, class_name: "User"

  validates :title, :body, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published").where(published_at: ..Time.current) }
  scope :by_latest, -> { order(published_at: :desc) }

  def self.for_cooperative(cooperative)
    where(cooperative_id: cooperative.id)
  end

  def self.published_for(cooperative)
    published.for_cooperative(cooperative)
  end

  def publish!
    update!(status: "published", published_at: Time.current)
  end

  def archive!
    update!(status: "archived")
  end
end