namespace :stockerly do
  desc "Seed every asset in AssetCatalog (picker + system rows). Idempotent, safe for production."
  task seed_assets: :environment do
    result = Administration::UseCases::Assets::SeedCatalog.call

    result[:skipped].each { |symbol| warn "  ! #{symbol}: catalogue currency differs but it has trades — not touching it" }
    puts "Assets: #{result[:created]} created, #{result[:corrected]} corrected, #{result[:total]} total"
  end

  desc "Print a VAPID key pair for push notifications. Generate once and keep — replacing it drops every subscription."
  task vapid_keys: :environment do
    pair = WebPush.generate_key

    puts "VAPID_PUBLIC_KEY=#{pair.public_key}"
    puts "VAPID_PRIVATE_KEY=#{pair.private_key}"
  end

  desc "Promote a user to admin by email"
  task :promote_admin, [ :email ] => :environment do |_t, args|
    email = args[:email]
    abort "Usage: rake stockerly:promote_admin[user@example.com]" if email.blank?

    user = User.find_by(email: email.downcase.strip)
    abort "User not found: #{email}" unless user

    if user.admin?
      puts "#{user.email} is already an admin."
    else
      user.update!(role: :admin)
      puts "Promoted #{user.email} to admin."
    end
  end

  desc "Reset a user's password from the box, for when mail is not configured (D55)"
  task :reset_password, [ :email ] => :environment do |_t, args|
    email = args[:email]
    abort "Usage: rake stockerly:reset_password[user@example.com]" if email.blank?

    user = User.find_by(email: email.downcase.strip)
    abort "User not found: #{email}" unless user
    abort "No TTY: run this from an interactive shell so the password is not echoed." unless $stdin.tty?

    require "io/console"
    password = $stdin.getpass("New password for #{user.email}: ")
    abort "Passwords do not match." unless password == $stdin.getpass("Repeat: ")

    user.update!(password: password)
    puts "Password updated for #{user.email}."
    puts "Two-factor authentication is unchanged." if user.otp_enrolled?
  end
end
