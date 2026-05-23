# Project-level constants. Centralizes values that appear in multiple
# views, mailers, and ops docs so a single edit propagates everywhere.
module Stockerly
  # The single inbox where ARCO requests, bug reports, and beta-amigo
  # support arrive. Per LFPDPPP Art. 32, the published privacy notice
  # MUST route to a real human within 20 business days. The DNS alias
  # for this address is configured outside the repo (Resend forwarder
  # → Adrian's monitored inbox). When changing this constant, also
  # confirm the new alias roundtrips end-to-end (see
  # docs/ops/beta-support.md §"Support email routing").
  SUPPORT_EMAIL = "support@notdefined.dev"
end
