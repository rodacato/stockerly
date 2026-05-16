class BugReportsController < AuthenticatedController
  BugReportInput = Struct.new(:title, :description, keyword_init: true)

  def new
    @bug_report = BugReportInput.new
  end

  def create
    result = Identity::UseCases::SendBugReport.call(
      user: current_user,
      params: bug_report_params.to_h
    )

    case result
    in Dry::Monads::Success(_attrs)
      @submitted = true
      @bug_report = BugReportInput.new
      render :new
    in Dry::Monads::Failure[ :validation, errors ]
      @bug_report = BugReportInput.new(**bug_report_params.to_h.symbolize_keys)
      @errors = errors
      render :new, status: :unprocessable_content
    else
      redirect_to new_bug_report_path, alert: "No se pudo enviar el reporte."
    end
  end

  private

  def bug_report_params
    params.permit(:title, :description)
  end
end
