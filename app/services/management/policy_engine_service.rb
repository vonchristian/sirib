module Management
  class PolicyEngineService < ActiveInteraction::Base
    object :policy, class: "Management::Policy"
    hash :context, default: {}

    def execute
      results = policy.rules.map { |rule| evaluate_rule(rule, context) }
      violations = results.select { |r| r[:effect] == "deny" }
      overrides = results.select { |r| r[:effect] == "require_override" }

      {
        allowed: violations.empty?,
        violations: violations,
        requires_override: overrides.any?,
        override_reasons: overrides.map { |r| r[:reason] }
      }
    end

    private

    def evaluate_rule(rule, ctx)
      actual_value = ctx[rule.field.to_sym]
      return { effect: "allow", rule: rule } if actual_value.nil?

      matched = case rule.operator
      when "eq" then actual_value.to_s == rule.value
      when "neq" then actual_value.to_s != rule.value
      when "gt" then actual_value.to_f > rule.value.to_f
      when "gte" then actual_value.to_f >= rule.value.to_f
      when "lt" then actual_value.to_f < rule.value.to_f
      when "lte" then actual_value.to_f <= rule.value.to_f
      when "in" then rule.value.split(",").map(&:strip).include?(actual_value.to_s)
      when "between" then
        min, max = rule.value.split("..").map(&:to_f)
        actual_value.to_f.between?(min, max)
      else false
      end

      if matched
        { effect: rule.effect, reason: "#{rule.field} #{rule.operator} #{rule.value}", rule: rule }
      else
        { effect: "allow", rule: rule }
      end
    end
  end
end
