class LegalController < ApplicationController
  layout "legal"

  before_action { expires_in 1.day, public: true }

  def privacy
    @page_title = "Aviso de privacidad"
    @page_subtitle = "Conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (DOF 20-mar-2025). Qué datos tratamos, cómo, por qué y por cuánto tiempo."
    @last_updated = "18 MAY 2026 · CDMX"
    @breadcrumbs = [ "Aviso de privacidad" ]
    @toc_sections = [
      { id: "responsable", icon: "person", title: "Identidad del responsable", active: true },
      { id: "datos", icon: "database", title: "Datos que recolectamos" },
      { id: "finalidades", icon: "insights", title: "Finalidades necesarias y voluntarias" },
      { id: "retencion", icon: "schedule", title: "Conservación de los datos" },
      { id: "remisiones", icon: "swap_horiz", title: "Remisiones y transferencias" },
      { id: "arco", icon: "person_check", title: "Derechos ARCO (20 días hábiles)" },
      { id: "autoridad", icon: "balance", title: "Autoridad de protección de datos" },
      { id: "cambios", icon: "edit_note", title: "Cambios al aviso" },
      { id: "contacto", icon: "mail", title: "Contacto" }
    ]
  end

  def terms
    @page_title = "Términos del servicio"
    @page_subtitle = "Reglas de uso de Stockerly. Léelos antes de aceptar al registrarte."
    @last_updated = "18 MAY 2026 · CDMX"
    @breadcrumbs = [ "Términos del servicio" ]
    @toc_sections = [
      { id: "responsable", icon: "person", title: "Identidad del responsable", active: true },
      { id: "servicio", icon: "info", title: "Naturaleza del servicio" },
      { id: "cuenta", icon: "manage_accounts", title: "Cuenta y uso permitido" },
      { id: "propiedad", icon: "copyright", title: "Propiedad intelectual y código abierto" },
      { id: "responsabilidad", icon: "gavel", title: "Limitación de responsabilidad" },
      { id: "jurisdiccion", icon: "balance", title: "Ley aplicable y jurisdicción" },
      { id: "cambios", icon: "edit_note", title: "Modificaciones" },
      { id: "contacto", icon: "mail", title: "Contacto" }
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
