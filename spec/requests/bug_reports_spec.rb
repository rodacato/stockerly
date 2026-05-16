require "rails_helper"

RSpec.describe "BugReports", type: :request do
  let(:user) { create(:user) }
  let(:valid_params) { { title: "La gráfica no carga", description: "Cuando abro /portfolio no aparece nada en la pantalla, hay error 500 en la consola." } }

  describe "GET /report-bug" do
    it "renders the form for a logged-in user" do
      login_as(user)
      get new_bug_report_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reportar un bug")
      expect(response.body).to include("Resumen")
      expect(response.body).to include("Detalles")
      expect(response.body).to include("Enviar reporte")
    end

    it "blocks anonymous users" do
      get new_bug_report_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /report-bug" do
    it "renders the success state and enqueues the mailer on valid submission" do
      login_as(user)

      expect {
        post bug_reports_path, params: valid_params
      }.to have_enqueued_mail(BugReportMailer, :notify)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Reporte enviado")
      expect(response.body).to include("Gracias")
    end

    it "rerenders the form with errors when title is missing" do
      login_as(user)
      post bug_reports_path, params: valid_params.merge(title: "")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Reportar un bug")
      expect(response.body).to include("obligatorio")
    end

    it "rerenders the form with errors when description is too short" do
      login_as(user)
      post bug_reports_path, params: valid_params.merge(description: "too short")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("obligatorio")
    end

    it "does not send mail when validation fails" do
      login_as(user)
      expect {
        post bug_reports_path, params: valid_params.merge(title: "")
      }.not_to have_enqueued_mail(BugReportMailer, :notify)
    end

    it "blocks anonymous users from posting" do
      post bug_reports_path, params: valid_params
      expect(response).to redirect_to(login_path)
    end
  end
end
