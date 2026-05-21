require "rails_helper"

RSpec.describe "Admin · Cuentas registradas", type: :system do
  before do
    driven_by :rack_test
    # The :setup_bypass spec helper seeds a sentinel User globally; clearing
    # keeps the population deterministic for header counts and filter assertions.
    User.where(email: "setup-bypass@test.local").destroy_all
  end

  let!(:admin) do
    create(:user, :admin, :email_verified, full_name: "Adrian Romero",
                                           email: "adrian@stockerly.mx",
                                           password: "password123",
                                           onboarded_at: Time.current)
  end
  let!(:admin_portfolio) { create(:portfolio, user: admin) }

  let!(:active_user) do
    create(:user, :email_verified, full_name: "Jimena Rocha", email: "jrocha@stockerly.mx")
  end
  let!(:suspended_user) do
    create(:user, :email_verified, :suspended, full_name: "Diego Fuentes", email: "diego@example.com")
  end
  let!(:unverified_user) do
    create(:user, full_name: "Carlos Mendoza", email: "carlos@example.com")
  end

  def sign_in_admin
    visit login_path
    fill_in "Correo electrónico", with: admin.email
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  before { sign_in_admin }

  it "renders the header band with count chip in es-MX" do
    visit admin_users_path

    expect(page).to have_content("Usuarios")
    expect(page).to have_content("Cuentas registradas")
    expect(page).to have_content("Gestiona usuarios, roles y estado de cuentas del beta cerrado.")
    expect(page).to have_content("4 usuarios")
    expect(page).to have_content("1 administrador")
  end

  it "lists each user with role and lifecycle status pills" do
    visit admin_users_path

    expect(page).to have_content("Adrian Romero")
    expect(page).to have_content("Jimena Rocha")
    expect(page).to have_content("Diego Fuentes")
    expect(page).to have_content("Carlos Mendoza")

    # role pills
    expect(page).to have_content("Admin")
    expect(page).to have_content("Usuario")

    # status pills
    expect(page).to have_content("Activo")
    expect(page).to have_content("Suspendido")
    expect(page).to have_content("Sin verificar")
  end

  it "filters by role" do
    visit admin_users_path(role: "admin")

    expect(page).to have_content("Adrian Romero")
    expect(page).not_to have_content("Jimena Rocha")
  end

  it "filters by status — suspendidos" do
    visit admin_users_path(status: "suspended")

    expect(page).to have_content("Diego Fuentes")
    expect(page).not_to have_content("Jimena Rocha")
    expect(page).not_to have_content("Carlos Mendoza")
  end

  it "filters by status — sin verificar" do
    visit admin_users_path(status: "unverified")

    expect(page).to have_content("Carlos Mendoza")
    expect(page).not_to have_content("Jimena Rocha")
  end

  it "filters by search query against full name" do
    visit admin_users_path(search: "Diego")

    expect(page).to have_content("Diego Fuentes")
    expect(page).not_to have_content("Jimena Rocha")
  end

  it "shows the Limpiar filtros affordance when a filter is active" do
    visit admin_users_path(role: "admin")
    expect(page).to have_link("Limpiar filtros", href: admin_users_path)
  end

  it "preserves the active role + status chips when the search form submits" do
    visit admin_users_path(role: "user", status: "suspended")
    # Hidden fields rendered alongside the search input — submitting the form
    # must carry role + status through (regression for #135 bot review).
    expect(page).to have_field("role", type: "hidden", with: "user")
    expect(page).to have_field("status", type: "hidden", with: "suspended")
  end

  it "suspends an active user via the overflow menu action" do
    visit admin_users_path
    page.driver.submit :patch, suspend_admin_user_path(active_user), {}
    expect(active_user.reload).to be_suspended
  end

  it "reactivates a suspended user via the overflow menu action" do
    visit admin_users_path
    page.driver.submit :patch, reactivate_admin_user_path(suspended_user), {}
    expect(suspended_user.reload).not_to be_suspended
  end

  it "shows the lone-admin row + count chip when no other users exist" do
    User.where.not(id: admin.id).destroy_all

    visit admin_users_path
    expect(page).to have_content("1 usuario")
    expect(page).to have_content("1 administrador")
    expect(page).to have_content("Adrian Romero")
  end

  it "renders the empty state copy file in es-MX" do
    # The truly-empty branch (User.count == 0) is unreachable from a signed-in
    # admin session, so we verify the empty-state partial copy directly.
    empty_state = Rails.root.join("app/views/admin/users/_empty_state.html.erb").read
    expect(empty_state).to include("Aún no hay usuarios registrados.")
    expect(empty_state).to include("Ir a invitaciones")
  end
end
