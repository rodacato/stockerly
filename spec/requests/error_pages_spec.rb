require "rails_helper"

RSpec.describe "Static error pages", type: :request do
  describe "429.html" do
    # Every `rate_limit` takes Rails 8.1's default `raise TooManyRequests`,
    # so this page is what a throttled reader actually gets.
    it "serves the too-many-requests page" do
      get "/429.html"

      expect(response).to have_http_status(:ok)

      body = response.body.dup.force_encoding(Encoding::UTF_8)
      expect(body).to include("Demasiados intentos")
      expect(body).to include("Espera un momento antes de volver a intentarlo.")
      expect(body).to include("stockerly")
    end

    it "offers no reload action, because retrying is what triggered it" do
      get "/429.html"

      body = response.body.dup.force_encoding(Encoding::UTF_8)
      expect(body).not_to include("location.reload()")
    end
  end
end
