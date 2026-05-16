class LegalController < ApplicationController
  layout "legal"

  before_action { expires_in 1.day, public: true }

  def privacy
    @page_title = "Aviso de privacidad"
    @page_subtitle = "Conforme al Art. 16 LFPDPPP. Qué datos tratamos, cómo y por qué."
    @last_updated = "16 MAY 2026 · CDMX"
    @breadcrumbs = [ "Aviso de privacidad" ]
    @toc_sections = [
      { id: "responsable", icon: "person", title: "Identidad del responsable", active: true },
      { id: "datos", icon: "database", title: "Datos que recolectamos" },
      { id: "finalidades", icon: "insights", title: "Finalidades del tratamiento" },
      { id: "transferencias", icon: "swap_horiz", title: "Transferencias a terceros" },
      { id: "arco", icon: "person_check", title: "Derechos ARCO" },
      { id: "cambios", icon: "edit_note", title: "Cambios al aviso" },
      { id: "contacto", icon: "mail", title: "Contacto" }
    ]
  end

  def terms
    @page_title = "Terms of Service"
    @page_subtitle = "Please read these terms carefully before using Stockerly."
    @last_updated = "October 24, 2023"
    @breadcrumbs = [ "Terms of Service" ]
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
    @breadcrumbs = [ "Risk Disclosure" ]
    @toc_sections = [
      { id: "introduction", icon: "info", title: "Introduction", active: true },
      { id: "market-risk", icon: "trending_down", title: "Market Volatility" },
      { id: "leverage", icon: "account_balance_wallet", title: "Leverage & Margin" },
      { id: "technical", icon: "monitor_heart", title: "Technical Risks" },
      { id: "regulatory", icon: "gavel", title: "Regulatory Info" }
    ]
  end
end
