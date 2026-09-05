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
    policy.connect_src :self
    policy.frame_src   "https://www.tradingview-widget.com"
    # Two hosts, and only these two: s3 serves the embed script, and the iframe
    # it injects comes from tradingview-widget.com — a different registrable
    # domain, which *.tradingview.com never covered. The websockets live inside
    # that iframe, under its own origin, so connect_src needs nothing. All of it
    # goes if D66 is dropped (X17).
    policy.frame_ancestors :none
  end

  # Generate session nonces for permitted importmap and inline scripts.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]
end
