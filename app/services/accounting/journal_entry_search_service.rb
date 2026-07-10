module Accounting
  class JournalEntrySearchService
    def initialize(query:, account_id: nil, member_id: nil, cooperative: nil)
      @query = query
      @account_id = account_id
      @member_id = member_id
      @cooperative = cooperative
    end

    def call
      return Accounting::Entry.none if query.blank?

      base = @cooperative ? Accounting::Entry.by_cooperative(@cooperative) : Accounting::Entry

      scope = if account_id.present?
        base.search(query).by_account(account_id)
      elsif member_id.present?
        base.search(query).by_member(member_id)
      else
        base.search(query)
      end

      scope.reorder(posted_at: :desc)
    end

    private

    attr_reader :query, :account_id, :member_id, :cooperative
  end
end
