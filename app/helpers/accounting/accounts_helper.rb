module Accounting
  module AccountsHelper
    def sort_link_helper(label, _column, params)
      new_sort = params[:sort] == "asc" ? "desc" : "asc"
      link_to label, url_for(params.permit(:id, :sort, :from_date, :to_date, :quick_range, :debit_only, :credit_only, :amount_min, :amount_max, :reference_number, :description, :entry_type, :source_module, :page).merge(sort: new_sort)),
          class: "hover:text-text-primary transition-colors inline-flex items-center gap-1"
    end

    def entry_type_class(type)
      case type
      when "manual_entry" then "bg-blue-500/10 text-blue-400"
      when "system_entry" then "bg-purple-500/10 text-purple-400"
      when "interest_entry" then "bg-amber-500/10 text-amber-400"
      when "fees_entry" then "bg-orange-500/10 text-orange-400"
      when "reversal_entry" then "bg-red-500/10 text-red-400"
      when "adjustment_entry" then "bg-indigo-500/10 text-indigo-400"
      else "bg-gray-500/10 text-gray-400"
      end
    end
  end
end
