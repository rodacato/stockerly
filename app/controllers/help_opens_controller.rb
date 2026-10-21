class HelpOpensController < AuthenticatedController
  FIGURES = %w[veredicto patrimonio vs_cetes earnings maturity target].freeze

  def create
    return head :unprocessable_content unless FIGURES.include?(params[:figure])

    AppOpen.record(path: "help:#{params[:figure]}")
    head :no_content
  end
end
