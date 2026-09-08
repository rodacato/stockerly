require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  subject(:directives) do
    get privacy_path
    response.headers["content-security-policy"].split(";").map(&:strip)
  end

  def directive(name)
    directives.find { |d| d.start_with?("#{name} ") }
  end

  it "lets the stylesheet links in the layout head load" do
    expect(directive("style-src")).to include("https://fonts.googleapis.com")
  end

  it "lets the font files those stylesheets point at load" do
    expect(directive("font-src")).to include("https://fonts.gstatic.com")
  end

  # The service worker re-fetches both hosts to fill its font cache, and a
  # fetch() from a worker answers to connect-src. Drop these and Material
  # Symbols renders as ligature text wherever the font cache is cold.
  it "lets the service worker re-fetch both font hosts" do
    expect(directive("connect-src")).to include("https://fonts.googleapis.com")
    expect(directive("connect-src")).to include("https://fonts.gstatic.com")
  end
end
