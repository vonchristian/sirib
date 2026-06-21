module Accounting
  class JournalEntrySearchService
    def initialize(query:, account_id: nil, member_id: nil)
      @query = query
      @account_id = account_id
      @member_id = member_id
    end

    def call
      return Accounting::Entry.none if query.blank?

      scope = if account_id.present?
        Accounting::Entry.search(query).by_account(account_id)
      elsif member_id.present?
        Accounting::Entry.search(query).by_member(member_id)
      else
        Accounting::Entry.search(query)
      end

      scope.order(posted_at: :desc)
    end

    private

    attr_reader :query, :account_id, :member_id
  end
end
