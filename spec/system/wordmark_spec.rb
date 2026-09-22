require "rails_helper"

# The wordmark used to ship as two <img> files, so a chrome page requested
# 8,122 bytes over two requests to draw 4,061 of artwork, and neither file was
# precached — the same shape ADR-028 closed for icons. It is inline now: the
# disc takes the brand token, the word takes currentColor, and one source draws
# every contrast the two files used to.
#
# The letters stay outlined paths. Set as <text font-family="Plus Jakarta
# Sans">, a device without that font fell back to a wider one and the 174-wide
# viewBox cut the last letter.
RSpec.describe "The wordmark", type: :system, js: true do
  let(:partial) { Rails.root.join("app/views/shared/_logo.html.erb").read }
  let(:mail_file) { Rails.root.join("app/assets/images/logo_light.svg").read }

  it "ships inside the HTML rather than as a file that can fail on its own" do
    expect(partial).to include("<svg")
    expect(partial).not_to include("image_tag")
    expect(Rails.root.join("app/assets/images/logo_dark.svg")).not_to exist
  end

  it "takes the disc from the brand token and the word from the text colour" do
    expect(partial).to include('fill="var(--color-primary)"')
    expect(partial).to include('fill="currentColor"')
  end

  it "carries its letters as paths, so no font has to be installed" do
    [ partial, mail_file ].each do |source|
      expect(source).not_to include("<text")
      expect(source).not_to include("font-family")
    end
  end

  it "draws the whole word inside the viewBox" do
    visit login_path

    box = page.evaluate_script(<<~JS)
      (() => {
        const svg = document.querySelector("svg[aria-label='Stockerly']");
        const paths = Array.from(svg.querySelectorAll('path'));
        const right = Math.max(...paths.map(p => {
          const b = p.getBBox();
          return b.x + b.width;
        }));
        return { paths: paths.length, right: Math.round(right) };
      })()
    JS

    expect(box["paths"]).to eq(2)
    expect(box["right"]).to be <= 174
  end
end
