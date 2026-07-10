module Accounting
  ACCOUNT_TYPES = {
    asset: "asset",
    equity: "equity",
    liability: "liability",
    revenue: "revenue",
    expense: "expense"
  }.freeze

  class Error < StandardError; end
end
