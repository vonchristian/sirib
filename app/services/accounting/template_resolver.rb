module Accounting
  class TemplateResolver
    def initialize(template, input = {})
      @template = template
      @input = input.with_indifferent_access
    end

    def resolve_lines
      @template.lines.by_sequence.includes(:account).map do |line|
        {
          account: line.account,
          direction: line.direction,
          amount_cents: line.resolve_amount_cents(@input[:amount] || @input["amount"] || 0)
        }
      end
    end

    def resolve_debits
      resolve_lines.select { |l| l[:direction] == "debit" }
    end

    def resolve_credits
      resolve_lines.select { |l| l[:direction] == "credit" }
    end
  end
end
