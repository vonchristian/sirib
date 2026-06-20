module Accounting
  class EntryTemplate
    class ValidateService < ActiveInteraction::Base
      object :template, class: Accounting::EntryTemplate

      validate :must_have_at_least_two_lines
      validate :must_have_both_sides
      validate :fixed_amounts_must_balance
      validate :at_most_one_variable_per_side
      validate :fixed_lines_must_have_amount

      def execute
        template
      end

      private

      def must_have_at_least_two_lines
        errors.add(:base, "must have at least 2 lines") if all_lines.size < 2
      end

      def must_have_both_sides
        errors.add(:base, "must have at least one debit and one credit line") if debit_lines.empty? || credit_lines.empty?
      end

      def fixed_amounts_must_balance
        debit_fixed = fixed_lines.select(&:debit?).sum { |l| l.fixed_amount.to_d }
        credit_fixed = fixed_lines.select(&:credit?).sum { |l| l.fixed_amount.to_d }
        return if debit_fixed == credit_fixed

        errors.add(:base, "fixed amount debits (#{debit_fixed}) must equal fixed amount credits (#{credit_fixed})")
      end

      def at_most_one_variable_per_side
        if variable_lines.count { |l| l.debit? } > 1
          errors.add(:base, "debits can have at most one variable line")
        end
        if variable_lines.count { |l| l.credit? } > 1
          errors.add(:base, "credits can have at most one variable line")
        end
      end

      def fixed_lines_must_have_amount
        fixed_lines.each do |line|
          if line.fixed_amount.blank? || line.fixed_amount <= 0
            errors.add(:base, "fixed line ##{line.sequence_index} must have a positive amount")
          end
        end
      end

      def all_lines
        @all_lines ||= template.lines.to_a
      end

      def debit_lines
        all_lines.select(&:debit?)
      end

      def credit_lines
        all_lines.select(&:credit?)
      end

      def fixed_lines
        all_lines.select(&:fixed?)
      end

      def variable_lines
        all_lines.select(&:variable?)
      end
    end
  end
end
