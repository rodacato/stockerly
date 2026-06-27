class LegalController < ApplicationController
  layout "legal"

  LAST_UPDATED = "18 MAY 2026 · CDMX"

  # Per-page content. The view reads @page_title/@page_subtitle/@breadcrumbs/
  # @toc_sections; render_legal wires them so the three actions stay free of
  # duplicated assignment boilerplate.
  PAGES = {
    privacy: {
      title: "Aviso de privacidad",
      subtitle: "Conforme a la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (DOF 20-mar-2025). Qué datos tratamos, cómo, por qué y por cuánto tiempo.",
      breadcrumbs: [ "Aviso de privacidad" ],
      toc: [
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
    },
    terms: {
      title: "Términos del servicio",
      subtitle: "Reglas de uso de Stockerly. Léelos antes de aceptar al registrarte.",
      breadcrumbs: [ "Términos del servicio" ],
      toc: [
        { id: "responsable", icon: "person", title: "Identidad del responsable", active: true },
        { id: "servicio", icon: "info", title: "Naturaleza del servicio" },
        { id: "cuenta", icon: "manage_accounts", title: "Cuenta y uso permitido" },
        { id: "propiedad", icon: "copyright", title: "Propiedad intelectual y código abierto" },
        { id: "responsabilidad", icon: "gavel", title: "Limitación de responsabilidad" },
        { id: "jurisdiccion", icon: "balance", title: "Ley aplicable y jurisdicción" },
        { id: "cambios", icon: "edit_note", title: "Modificaciones" },
        { id: "contacto", icon: "mail", title: "Contacto" }
      ]
    },
    risk_disclosure: {
      title: "Advertencia de riesgo",
      subtitle: "Stockerly es informativo. Toda inversión conlleva riesgo de pérdida. Lee esto antes de basar decisiones en lo que muestra la plataforma.",
      breadcrumbs: [ "Advertencia de riesgo" ],
      toc: [
        { id: "introduccion", icon: "info", title: "Resumen del riesgo", active: true },
        { id: "servicio", icon: "visibility", title: "Qué es y qué no es Stockerly" },
        { id: "datos", icon: "data_alert", title: "Riesgos de los datos" },
        { id: "mercado", icon: "trending_down", title: "Riesgos de mercado" },
        { id: "asesoria", icon: "gavel", title: "No constituye asesoría" },
        { id: "verificacion", icon: "verified", title: "Verifica con tu broker" }
      ]
    }
  }.freeze

  before_action { expires_in 1.day, public: true }

  def privacy = render_legal(:privacy)
  def terms = render_legal(:terms)
  def risk_disclosure = render_legal(:risk_disclosure)

  private

  def render_legal(page)
    config = PAGES.fetch(page)
    @page_title = config[:title]
    @page_subtitle = config[:subtitle]
    @last_updated = LAST_UPDATED
    @breadcrumbs = config[:breadcrumbs]
    @toc_sections = config[:toc]
    render page
  end
end
