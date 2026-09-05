# Project-level constants. Centralizes values that appear in multiple
# views, mailers, and ops docs so a single edit propagates everywhere.
module Stockerly
  # The single inbox where ARCO requests and legal contact arrive. Bug
  # reports no longer route here: /report-bug was a hosted-beta surface and
  # was retired once ADR-0010 dropped that audience, because on someone
  # else's self-hosted instance it silently mailed this address.
  # Per LFPDPPP Art. 32, the published privacy notice MUST route
  # to a real human within 20 business days. The DNS alias for this
  # address is configured outside the repo (Resend forwarder → Adrian's
  # monitored inbox). When changing this constant, also confirm the new
  # alias roundtrips end-to-end.
  SUPPORT_EMAIL = "support@notdefined.dev"

  # Where a bug goes now. A public tracker is a channel the owner of any
  # instance can actually use, and read.
  ISSUES_URL = "https://github.com/rodacato/stockerly/issues"
end
