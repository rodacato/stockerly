require "rails_helper"

# The wordmark ships as an <img>, and an SVG loaded that way cannot use the
# page's web fonts: the word was set as <text font-family="Plus Jakarta Sans">,
# so a device without that font fell back to a wider one and the 174-wide
# viewBox cut the last letter. The letters are outlined paths now, which is what
# this measures — a glyph count no font substitution can change.
RSpec.describe "The wordmark", type: :system, js: true do
  it "carries its letters as paths, so no font has to be installed" do
    %w[logo_light.svg logo_dark.svg].each do |file|
      svg = Rails.root.join("app/assets/images", file).read

      expect(svg).not_to include("<text")
      expect(svg).not_to include("font-family")
    end
  end

  it "draws the whole word inside the viewBox" do
    visit login_path
    svg = Rails.root.join("app/assets/images/logo_light.svg").read

    box = page.evaluate_script(<<~JS)
      (() => {
        const host = document.createElement('div');
        host.style.cssText = 'position:absolute;left:-9999px';
        host.innerHTML = #{svg.to_json};
        document.body.appendChild(host);
        const paths = Array.from(host.querySelectorAll('path'));
        const right = Math.max(...paths.map(p => p.getBBox().x + p.getBBox().width));
        host.remove();
        return { paths: paths.length, right: Math.round(right) };
      })()
    JS

    expect(box["paths"]).to eq(2)
    expect(box["right"]).to be <= 174
  end
end
