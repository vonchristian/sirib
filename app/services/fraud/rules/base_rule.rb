module Fraud
  module Rules
    class BaseRule
      attr_reader :rule, :transaction, :account, :user

      def initialize(rule, transaction: nil, account: nil, user: nil)
        @rule = rule
        @transaction = transaction
        @account = account
        @user = user
      end

      def call
        raise NotImplementedError
      end

      def description
        raise NotImplementedError
      end
    end
  end
end
