module Accounting
  class AccountNotPostableError < StandardError
    attr_reader :account

    def initialize(msg = "Account cannot accept postings", account: nil)
      super(msg)
      @account = account
    end
  end
end
