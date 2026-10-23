class HelpOpensController < AuthenticatedController
  FIGURES = %w[veredicto patrimonio vs_cetes earnings maturity target allocation contribution plan macro volatilidad].freeze

  def create
    return head :unprocessable_content unless FIGURES.include?(params[:figure])

    Usage.opened("help:#{params[:figure]}")
    head :no_content
  end
end
