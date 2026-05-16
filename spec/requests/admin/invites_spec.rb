require "rails_helper"

RSpec.describe "Admin::Invites", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user)  { create(:user) }

  describe "GET /admin/invites" do
    it "renders the page for an admin" do
      login_as(admin)
      get admin_invites_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Códigos de invitación")
    end

    it "lists existing invite codes with their status" do
      available = create(:invite_code, created_by_user: admin, note: "Pablo")
      _redeemed = create(:invite_code, :used, created_by_user: admin)

      login_as(admin)
      get admin_invites_path

      expect(response.body).to include(available.formatted_code)
      expect(response.body).to include("Pablo")
      expect(response.body).to include("Disponible")
      expect(response.body).to include("Canjeado")
    end

    it "renders an empty state when no codes exist" do
      login_as(admin)
      get admin_invites_path

      expect(response.body).to include("Aún no hay códigos generados.")
    end

    it "blocks non-admin users" do
      login_as(user)
      get admin_invites_path

      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include("/admin/invites")
    end

    it "blocks anonymous users" do
      get admin_invites_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "POST /admin/invites" do
    it "creates a new invite code with an optional note" do
      login_as(admin)

      expect {
        post admin_invites_path, params: { note: "amigo Juan" }
      }.to change(InviteCode, :count).by(1)

      created = InviteCode.last
      expect(created.note).to eq("amigo Juan")
      expect(created.created_by_user).to eq(admin)
      expect(response).to redirect_to(admin_invites_path)

      follow_redirect!
      expect(response.body).to include("Código generado.")
      expect(response.body).to include(created.formatted_code)
    end

    it "creates without a note when blank" do
      login_as(admin)
      post admin_invites_path, params: { note: "" }
      expect(InviteCode.last.note).to be_nil
    end

    it "blocks non-admin users from creating" do
      login_as(user)
      expect {
        post admin_invites_path
      }.not_to change(InviteCode, :count)

      expect(response).to have_http_status(:redirect)
      expect(response.location).not_to include("/admin/invites")
    end
  end
end
