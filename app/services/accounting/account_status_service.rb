module Accounting
  class AccountStatusService
    def initialize(account:)
      @account = account
    end

    def deactivate!
      @account.update!(status: :inactive) if @account.active?
    end

    def activate!
      @account.update!(status: :active) if !@account.active?
    end

    def toggle_postable!
      @account.update!(postable: !@account.postable?)
    end

    def can_post?
      @account.active? && @account.postable?
    end

    def can_post!
      raise AccountNotPostableError.new("Account is not postable", account: @account) unless can_post?
    end

    def status_reason
      if !@account.active?
        "Account is inactive"
      elsif !@account.postable?
        "Account is marked as non-postable"
      else
        nil
      end
    end
  end
end
