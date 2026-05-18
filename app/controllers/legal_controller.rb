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
    @page_title = "Advertencia de riesgo"
    @page_subtitle = "Stockerly es informativo. Toda inversión conlleva riesgo de pérdida. Lee esto antes de basar decisiones en lo que muestra la plataforma."
    @last_updated = "18 MAY 2026 · CDMX"
    @breadcrumbs = [ "Advertencia de riesgo" ]
    @toc_sections = [
      { id: "introduccion", icon: "info", title: "Resumen del riesgo", active: true },
      { id: "servicio", icon: "visibility", title: "Qué es y qué no es Stockerly" },
      { id: "datos", icon: "data_alert", title: "Riesgos de los datos" },
      { id: "mercado", icon: "trending_down", title: "Riesgos de mercado" },
      { id: "asesoria", icon: "gavel", title: "No constituye asesoría" },
      { id: "verificacion", icon: "verified", title: "Verifica con tu broker" }
    ]
  end
end
