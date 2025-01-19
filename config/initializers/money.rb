require "money-rails"

MoneyRails.configure do |config|
  config.default_currency = :eur
  config.no_cents_if_whole = false
  config.symbol = "€"

  # Use dots for decimal separator
  Money.locale_backend = nil  # Disable i18n localization
  Money.rounding_mode = BigDecimal::ROUND_HALF_UP
end
