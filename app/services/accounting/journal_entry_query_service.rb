module Accounting
  class JournalEntryQueryService
    def initialize(cooperative: Current.cooperative, start_date: nil, end_date: nil, branch_id: nil, account_id: nil,
                   entry_type: nil, status: nil, source_module: nil, amount_min: nil,
                   amount_max: nil, reference_number: nil, created_by_id: nil,
                   template_id: nil, has_attachments: nil, inter_branch: nil)
      @cooperative = cooperative
      @start_date = start_date
      @end_date = end_date
      @branch_id = branch_id
      @account_id = account_id
      @entry_type = entry_type
      @status = status
      @source_module = source_module
      @amount_min = amount_min
      @amount_max = amount_max
      @reference_number = reference_number
      @created_by_id = created_by_id
      @template_id = template_id
      @has_attachments = has_attachments
      @inter_branch = inter_branch
    end

    def call
      scope = Accounting::Entry.by_cooperative(@cooperative)

      scope = apply_date_filter(scope)
      scope = apply_branch_filter(scope)
      scope = apply_account_filter(scope)
      scope = apply_entry_type_filter(scope)
      scope = apply_status_filter(scope)
      scope = apply_source_module_filter(scope)
      scope = apply_amount_filter(scope)
      scope = apply_reference_number_filter(scope)
      scope = apply_created_by_filter(scope)
      scope = apply_template_filter(scope)
      scope = apply_has_attachments_filter(scope)
      scope = apply_inter_branch_filter(scope)

      scope.order(posted_at: :desc)
    end

    private

    attr_reader :cooperative, :start_date, :end_date, :branch_id, :account_id, :entry_type,
                :status, :source_module, :amount_min, :amount_max,
                :reference_number, :created_by_id, :template_id,
                :has_attachments, :inter_branch

    def apply_date_filter(scope)
      return scope unless start_date || end_date

      scope.date_range(start_date, end_date)
    end

    def apply_branch_filter(scope)
      return scope unless branch_id

      scope.by_branch(branch_id)
    end

    def apply_account_filter(scope)
      return scope unless account_id

      scope.by_account(account_id)
    end

    def apply_entry_type_filter(scope)
      return scope unless entry_type

      scope.by_entry_type(entry_type)
    end

    def apply_status_filter(scope)
      return scope unless status

      scope.by_status(status)
    end

    def apply_source_module_filter(scope)
      return scope unless source_module

      scope.by_source_module(source_module)
    end

    def apply_amount_filter(scope)
      return scope unless amount_min || amount_max

      scope.joins(:amount_lines)
           .group("entries.id")
           .having("SUM(amount_lines.amount_cents) >= ?", amount_min.to_i * 100)
           .having("SUM(amount_lines.amount_cents) <= ?", amount_max.to_i * 100)
    end

    def apply_reference_number_filter(scope)
      return scope unless reference_number

      scope.where("reference_number ILIKE ?", "%#{reference_number}%")
    end

    def apply_created_by_filter(scope)
      return scope unless created_by_id

      scope.by_created_by(created_by_id)
    end

    def apply_template_filter(scope)
      return scope unless template_id

      scope.where(template_id: template_id)
    end

    def apply_has_attachments_filter(scope)
      return scope if has_attachments.nil?

      scope.where(has_attachments: has_attachments)
    end

    def apply_inter_branch_filter(scope)
      return scope if inter_branch.nil?

      scope.where(inter_branch: inter_branch)
    end
  end
end
