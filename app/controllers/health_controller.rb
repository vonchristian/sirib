class HealthController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_cooperative

  def show
    checks = {
      database: database_healthy?,
      cache: cache_healthy?,
      queue: queue_healthy?
    }

    status = checks.values.all? ? :ok : :service_unavailable

    render json: {
      status: status == :ok ? "ok" : "degraded",
      timestamp: Time.current.iso8601,
      checks: checks
    }, status: status
  end

  private

  def database_healthy?
    ActiveRecord::Base.connection.execute("SELECT 1")
    true
  rescue => e
    false
  end

  def cache_healthy?
    Rails.cache.read("health_check") || Rails.cache.write("health_check", true, expires_in: 5.seconds)
    true
  rescue => e
    false
  end

  def queue_healthy?
    SolidQueue::Job.count
    true
  rescue => e
    false
  end
end
