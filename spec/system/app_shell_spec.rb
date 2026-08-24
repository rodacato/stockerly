require "rails_helper"

RSpec.describe "App shell", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "shell@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "shell@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders both nav variants so CSS decides which one shows" do
    visit dashboard_path

    expect(page).to have_css("aside nav[aria-label='Navegación principal']")
    expect(page).to have_css("nav.sticky.bottom-0[aria-label='Navegación principal']")
  end

  it "marks only the current destination" do
    visit assets_path

    current = page.all("a[aria-current='page']").map { |a| a[:href] }.uniq
    expect(current).to eq([ assets_path ])
  end

  it "keeps a tab lit across the screens it owns" do
    visit trades_path

    expect(page.all("a[aria-current='page']").map { |a| a[:href] }.uniq).to eq([ assets_path ])
  end

  it "labels the bell with the unread count so it is not just an icon" do
    create_list(:notification, 2, user: user, read: false)
    visit dashboard_path

    expect(page).to have_link(href: notifications_path, count: 2)
    expect(page.first("a[href='#{notifications_path}']")[:"aria-label"]).to eq("2 avisos sin leer")
  end

  it "falls back to the section name when a screen sets no title" do
    visit alerts_path

    expect(page).to have_css("header p", text: "Reglas")
  end
end
