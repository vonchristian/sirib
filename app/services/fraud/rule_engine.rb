module Fraud
  class RuleEngine
    def self.evaluate(transaction: nil, account: nil, user: nil, cooperative: nil)
      new.evaluate(transaction:, account:, user:, cooperative:)
    end

    def evaluate(transaction: nil, account: nil, user: nil, cooperative: nil)
      flags = []
      rules = Fraud::Rule.where(active: true)

      if cooperative
        rules = rules.where(cooperative: cooperative)
      end

      rules.find_each do |rule|
        result = evaluate_rule(rule, transaction:, account:, user:)
        flags.concat(result) if result.any?
      end

      flags
    end

    private

    def evaluate_rule(rule, transaction: nil, account: nil, user: nil)
      rule_instance = Fraud::Rules::Registry.for(rule, transaction: transaction, account: account, user: user)
      result = rule_instance.call
      result ? create_incident(rule, rule_instance.description, severity: rule.severity) : []
    rescue ArgumentError => e
      Rails.logger.error "FraudRule[#{rule.id}] unknown rule type: #{e.message}"
      []
    end

    def create_incident(rule, description, severity: "medium")
      [ {
        rule_id: rule.id,
        rule_name: rule.name,
        description: description,
        severity: severity
      } ]
    end
  end
end
