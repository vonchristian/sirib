MoneyRails.configure do |config|
  config.default_currency = :php
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  config.locale_backend = nil
  config.default_format = {
    no_cents_if_whole: false,
    symbol: "₱",
    decimal_mark: ".",
    thousands_separator: ","
  }
end
