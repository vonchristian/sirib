module Management
  class SystemHealthService < ActiveInteraction::Base
    def execute
      snapshots = []

      snapshots << record_metric("transaction_throughput", compute_throughput, "tps")
      snapshots << record_metric("queue_depth", compute_queue_depth, "jobs")
      snapshots << record_metric("posting_latency_ms", compute_latency, "ms")
      snapshots << record_metric("error_rate", compute_error_rate, "percent")

      snapshots
    end

    private

    def record_metric(name, value, unit)
      status = case name
      when "error_rate" then value > 5 ? "critical" : value > 1 ? "warning" : "healthy"
      when "queue_depth" then value > 100 ? "critical" : value > 20 ? "warning" : "healthy"
      when "posting_latency_ms" then value > 5000 ? "critical" : value > 1000 ? "warning" : "healthy"
      else "healthy"
      end

      Management::SystemHealthSnapshot.create!(
        metric_name: name,
        value: value,
        unit: unit,
        status: status,
        captured_at: Time.current
      )
    end

    def compute_throughput
      entries_today = Accounting::Entry.where("created_at >= ?", Time.current.beginning_of_day).count
      (entries_today.to_f / (Time.current - Time.current.beginning_of_day) * 3600).round(2) rescue 0
    end

    def compute_queue_depth
      SolidQueue::Job.where(finished_at: nil).count rescue 0
    end

    def compute_latency
      latencies = Accounting::Entry.where("created_at >= ?", 1.hour.ago)
        .pluck(:created_at, :posted_at)
        .map { |c, p| ((p || c) - c) * 1000 }
      return 0 if latencies.empty?
      (latencies.sum / latencies.size).round(2)
    end

    def compute_error_rate
      total = Accounting::Entry.where("created_at >= ?", 1.hour.ago).count
      return 0 if total.zero?
      failed = Accounting::Entry.where("created_at >= ?", 1.hour.ago)
        .where(posted_at: nil).count
      ((failed.to_f / total) * 100).round(2)
    end
  end
end
