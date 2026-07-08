module Accounting
  module AccountsHelper
    def sort_link_helper(label, _column, params)
      new_sort = params[:sort] == "asc" ? "desc" : "asc"
      link_to label, url_for(params.permit(:id, :sort, :from_date, :to_date, :quick_range, :debit_only, :credit_only, :amount_min, :amount_max, :reference_number, :description, :entry_type, :source_module, :page).merge(sort: new_sort)),
          class: "hover:text-text-primary transition-colors inline-flex items-center gap-1"
    end

    def entry_type_class(type)
      "bg-surface-alt text-text-tertiary"
    end
  end
end
