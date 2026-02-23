class LegalController < ApplicationController
  layout "legal"

  before_action { expires_in 1.day, public: true }

  def privacy
    @page_title = "Privacy Policy"
    @page_subtitle = "Ensuring your data is safe, transparently handled, and always yours."
    @last_updated = "October 24, 2023"
    @breadcrumbs = ["Privacy Policy"]
    @toc_sections = [
      { id: "introduction", icon: "info", title: "Introduction", active: true },
      { id: "collection", icon: "database", title: "Information Collection" },
      { id: "usage", icon: "insights", title: "Data Usage" },
      { id: "storage", icon: "shield_lock", title: "Storage & Protection" },
      { id: "rights", icon: "person_check", title: "User Rights" },
      { id: "cookies", icon: "cookie", title: "Cookies & Tracking" },
      { id: "contact", icon: "mail", title: "Contact Us" }
    ]
  end

  def terms
    @page_title = "Terms of Service"
    @page_subtitle = "Please read these terms carefully before using Stockerly."
    @last_updated = "October 24, 2023"
    @breadcrumbs = ["Terms of Service"]
    @toc_sections = [
      { id: "acceptance", icon: "check_circle", title: "Acceptance of Terms", active: true },
      { id: "accounts", icon: "person", title: "User Accounts" },
      { id: "platform-usage", icon: "terminal", title: "Platform Usage" },
      { id: "intellectual-property", icon: "copyright", title: "Intellectual Property" },
      { id: "liability", icon: "warning", title: "Limitations of Liability" },
      { id: "termination", icon: "cancel", title: "Termination" },
      { id: "contact", icon: "mail", title: "Contact Information" }
    ]
  end

  def risk_disclosure
    @page_title = "Risk Disclosure"
    @page_subtitle = "Important information about the risks associated with trading and investing."
    @last_updated = "October 24, 2023"
    @breadcrumbs = ["Risk Disclosure"]
    @toc_sections = [
      { id: "introduction", icon: "info", title: "Introduction", active: true },
      { id: "market-risk", icon: "trending_down", title: "Market Volatility" },
      { id: "leverage", icon: "account_balance_wallet", title: "Leverage & Margin" },
      { id: "technical", icon: "monitor_heart", title: "Technical Risks" },
      { id: "regulatory", icon: "gavel", title: "Regulatory Info" }
    ]
  end
end
