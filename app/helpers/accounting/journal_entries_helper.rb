module Accounting
  module JournalEntriesHelper
    def status_class(status)
      case status
      when "posted" then "bg-green-100 text-green-800"
      when "pending" then "bg-yellow-100 text-yellow-800"
      when "reversed" then "bg-red-100 text-red-800"
      else "bg-gray-100 text-gray-800"
      end
    end

    def entry_type_class(type)
      case type
      when "manual" then "bg-blue-100 text-blue-800"
      when "system" then "bg-purple-100 text-purple-800"
      when "interest" then "bg-amber-100 text-amber-800"
      when "fees" then "bg-orange-100 text-orange-800"
      when "reversal" then "bg-red-100 text-red-800"
      when "adjustment" then "bg-indigo-100 text-indigo-800"
      else "bg-gray-100 text-gray-800"
      end
    end
  end
end
