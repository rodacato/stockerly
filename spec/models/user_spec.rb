require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires full_name" do
      user.full_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include("can't be blank")
    end

    it "requires full_name of at least 2 characters" do
      user.full_name = "A"
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include("is too short (minimum is 2 characters)")
    end

    it "requires email" do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires unique email (case-insensitive)" do
      create(:user, email: "test@example.com")
      user.email = "TEST@example.com"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "requires valid email format" do
      user.email = "not-an-email"
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "requires password of at least 8 characters" do
      user.password = "short"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
    end
  end

  describe "callbacks" do
    it "downcases and strips email before validation" do
      user.email = "  USER@EXAMPLE.COM  "
      user.save!
      expect(user.reload.email).to eq("user@example.com")
    end
  end

  describe "enums" do
    it "defines role enum" do
      expect(User.roles).to eq("user" => 0, "admin" => 1)
    end

    it "defines status enum" do
      expect(User.statuses).to eq("active" => 0, "suspended" => 1)
    end
  end

  describe "password reset tokens (Rails 8 built-in)" do
    let(:user) { create(:user) }

    it "generates a password reset token" do
      token = user.password_reset_token
      expect(token).to be_present
    end

    it "finds user by valid token" do
      token = user.password_reset_token
      found = User.find_by_password_reset_token(token)
      expect(found).to eq(user)
    end

    it "returns nil for invalid token" do
      found = User.find_by_password_reset_token("invalid-token")
      expect(found).to be_nil
    end

    it "invalidates token after password change" do
      token = user.password_reset_token
      user.update!(password: "newpassword123", password_confirmation: "newpassword123")
      found = User.find_by_password_reset_token(token)
      expect(found).to be_nil
    end
  end

  describe "associations" do
    it "destroys remember_tokens on user destroy" do
      user = create(:user)
      create(:remember_token, user: user)
      expect { user.destroy }.to change(RememberToken, :count).by(-1)
    end
  end
end
