module Accounting
  class ValidationEngine
    ValidationError = Class.new(StandardError)

    def self.validate!(entry)
      amount_lines = entry.amount_lines
      raise ValidationError, "Entry must have at least one line" if amount_lines.empty?
      raise ValidationError, "Entry must have at least one debit line" if amount_lines.select(&:debit?).empty?
      raise ValidationError, "Entry must have at least one credit line" if amount_lines.select(&:credit?).empty?

      debit_total = amount_lines.select(&:debit?).sum(&:amount_cents)
      credit_total = amount_lines.select(&:credit?).sum(&:amount_cents)
      raise ValidationError, "Entry is unbalanced: debits (#{debit_total}) != credits (#{credit_total})" unless debit_total == credit_total

      amount_lines.each do |line|
        raise ValidationError, "Line amount must be positive" unless line.amount_cents.to_i > 0
        raise ValidationError, "Line must have an account" if line.account.blank?
      end

      true
    end

    def self.balanced?(entry)
      debit_total = entry.amount_lines.select(&:debit?).sum(&:amount_cents)
      credit_total = entry.amount_lines.select(&:credit?).sum(&:amount_cents)
      debit_total == credit_total
    end
  end
end
