require "rails_helper"

RSpec.describe "Lumen first-boot entry", type: :system, js: true, setup_bypass: false do
  it "keeps setup readable at 320px in both modes" do
    page.current_window.resize_to(320, 900)
    visit setup_path
    expect(page).to have_button(I18n.t("setup.new.submit"))
    [ false, true ].each do |dark|
      page.execute_script("document.documentElement.classList.toggle('dark', #{dark})")
      page.evaluate_async_script(<<~JS)
        const done = arguments[0];
        requestAnimationFrame(() => requestAnimationFrame(() => {
          const finite = document.getAnimations().filter(animation => animation.effect.getComputedTiming().iterations !== Infinity);
          Promise.all(finite.map(animation => animation.finished.catch(() => {}))).then(() => done(true));
        }));
      JS
      expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
      if ENV["BRAND_VISUAL_EVIDENCE"] == "1"
        directory = Rails.root.join("tmp/brand-review/final")
        FileUtils.mkdir_p(directory)
        page.driver.browser.screenshot(path: directory.join("setup-320-#{dark ? 'dark' : 'light'}.png").to_s, full: true)
      end
    end
    find("input[name='email']").send_keys(:tab)
    expect(page).to have_css("input[name='password']:focus-visible")
    expect(page.evaluate_script("getComputedStyle(document.activeElement).outlineWidth")).to eq("2px")
    find("input[name='password']").send_keys(:tab)
    expect(page).to have_css("[data-password-visibility-target='button']:focus-visible")
    expect(page.evaluate_script("getComputedStyle(document.activeElement).outlineWidth")).to eq("2px")
  end
end
