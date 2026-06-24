module Accounting
  class ChartOfAccountsService
    attr_reader :cooperative

    def initialize(cooperative:)
      @cooperative = cooperative
    end

    def search(query)
      return { ledgers: [], accounts: [] } if query.blank?

      ledgers = Accounting::Ledger.where(cooperative: cooperative)
        .where("name ILIKE :q OR account_code ILIKE :q", q: "%#{query}%")
        .order(:account_code)
        .limit(10)

      accounts = Accounting::Account.where(cooperative: cooperative)
        .where("name ILIKE :q OR account_code ILIKE :q", q: "%#{query}%")
        .includes(:ledger)
        .order(:account_code)
        .limit(20)

      { ledgers: ledgers, accounts: accounts }
    end

    def tree_data
      roots = Accounting::Ledger.where(cooperative: cooperative).roots.order(:account_code)
      roots.map { |ledger| build_tree_node(ledger) }
    end

    def accounts_list(ledger_id: nil, account_type: nil, search: nil, contra: nil, status: nil, non_postable: nil, page: 1)
      scope = Accounting::Account.where(cooperative: cooperative).includes(:ledger)

      if ledger_id.present?
        ledger = Accounting::Ledger.by_cooperative(cooperative).find(ledger_id)
        descendant_ids = ledger.subtree_ids
        scope = scope.where(ledger_id: descendant_ids)
      end

      scope = scope.where(account_type: account_type) if account_type.present?
      scope = scope.where(contra: contra) if contra.present?
      scope = scope.where(status: status) if status.present?
      scope = scope.where(postable: false) if non_postable == "true"

      if search.present?
        scope = scope.where("accounts.name ILIKE :q OR accounts.account_code ILIKE :q",
          q: "%#{search}%")
      end

      scope.order(:account_code)
    end

    def account_inspector(account_id)
      account = Accounting::Account.by_cooperative(cooperative).includes(:ledger).find(account_id)

      recent_lines = Accounting::AmountLine
        .by_cooperative(cooperative)
        .joins(:entry)
        .includes(entry: :created_by)
        .where(account_id: account_id)
        .order("entries.posted_at DESC", "entries.id DESC")
        .limit(10)

      debit_total = Money.new(0, "PHP")
      credit_total = Money.new(0, "PHP")

      recent_lines.each do |line|
        if line.debit?
          debit_total += Money.new(line.amount_cents, "PHP")
        else
          credit_total += Money.new(line.amount_cents, "PHP")
        end
      end

      status_service = AccountStatusService.new(account: account)

      {
        account: account,
        recent_lines: recent_lines,
        debit_total: debit_total,
        credit_total: credit_total,
        ledger_path: account.ledger.ancestors.to_a.push(account.ledger).map(&:name).join(" / "),
        status: account.status,
        postable: account.postable?,
        status_reason: status_service.status_reason,
        can_post: status_service.can_post?
      }
    end

    private

    def build_tree_node(ledger)
      accounts = Accounting::Account.where(cooperative: cooperative, ledger_id: ledger.subtree_ids)
      account_count = accounts.size

      total_cents = accounts.reduce(0) do |sum, account|
        if account.normal_credit_balance? ^ account.contra
          sum + account.credits_balance - account.debits_balance
        else
          sum + account.debits_balance - account.credits_balance
        end
      end

      {
        ledger: ledger,
        balance: Money.new(total_cents, "PHP"),
        account_count: account_count,
        children: ledger.children.order(:account_code).map { |child| build_tree_node(child) },
        has_children: ledger.children.any?
      }
    end
  end
end
