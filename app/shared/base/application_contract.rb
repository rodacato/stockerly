# ADR-011 puts user-facing copy in `config/locales/es-MX.yml`, and a contract's
# failures are user-facing: the controllers hand them to the flash verbatim. The
# i18n backend is what lets a rule name its error (`key.failure(:asset_not_found)`)
# and the locale file carry the words, for dry-schema's own messages too.
class ApplicationContract < Dry::Validation::Contract
  config.messages.backend = :i18n
end
