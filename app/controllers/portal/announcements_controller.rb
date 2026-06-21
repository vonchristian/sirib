class Portal::AnnouncementsController < Portal::BaseController
  def index
    @announcements = announcements_scope.by_latest
    @pagy, @announcements = pagy(@announcements, limit: 20)
  end

  def show
    @announcement = announcements_scope.find(params[:id])
  end

  private

  def announcements_scope
    Portal::Announcement.published.for_cooperative(current_cooperative)
  end

  def current_cooperative
    Current.cooperative
  end
end