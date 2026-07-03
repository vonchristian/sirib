module Lending
  module LoanAgingHelper
    def group_color(group)
      colors = {
        "Current" => "#22c55e",
        "1-30 Days" => "#eab308",
        "31-60 Days" => "#f97316",
        "61-90 Days" => "#ef4444",
        "91-180 Days" => "#dc2626",
        "Over 180 Days" => "#991b1b"
      }
      colors[group.name] || "#6b7280"
    end

    def group_badge_class(group)
      case group.name
      when "Current"
        "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
      when /^1-30/
        "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"
      when /^31-60/
        "bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400"
      when /^61-90/
        "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400"
      when /^91-180/
        "bg-red-200 text-red-900 dark:bg-red-900/50 dark:text-red-300"
      when /Over 180/
        "bg-red-300 text-red-950 dark:bg-red-950/50 dark:text-red-200"
      else
        "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-300"
      end
    end
  end
end
