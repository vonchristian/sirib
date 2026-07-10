module Fraud
  module Rules
    class Registry
      MAPPING = {
        "large_amount"         => "Fraud::Rules::AmountThreshold",
        "unusual_frequency"    => "Fraud::Rules::VelocityCheck",
        "rapid_transfers"      => "Fraud::Rules::VelocityCheck",
        "dormant_account"      => "Fraud::Rules::DormantAccountCheck",
        "night_transactions"   => "Fraud::Rules::NightTransactionCheck",
        "duplicate_transaction" => "Fraud::Rules::DuplicateCheck",
        "multiple_ips"         => "Fraud::Rules::MultipleIpCheck"
    }.freeze

      def self.for(rule, **context)
        class_name = MAPPING[rule.rule_type]
        raise ArgumentError, "Unknown rule type: #{rule.rule_type}" unless class_name
        klass = class_name.constantize
        klass.new(rule, **context)
      end
    end
  end
end
