# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :https
    policy.object_src  :none
    policy.script_src  :self, "https://s3.tradingview.com"
    policy.style_src   :self, "https://fonts.googleapis.com", :unsafe_inline
    policy.connect_src :self, "https://*.tradingview.com", "wss://*.tradingview.com"
    policy.frame_src   "https://*.tradingview.com"
    # The tradingview.com allowances are kept for D66's opt-in chart toggle, not
    # by omission; nothing loads them today, and they go if D66 is dropped (X17).
    policy.frame_ancestors :none
  end

  # Generate session nonces for permitted importmap and inline scripts.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
