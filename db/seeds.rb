# Users
puts "Seeding users..."

User.find_or_create_by!(email: "admin@stockerly.com") do |user|
  user.full_name = "Admin User"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :admin
  user.is_verified = true
end

User.find_or_create_by!(email: "demo@stockerly.com") do |user|
  user.full_name = "Demo Trader"
  user.password = "password123"
  user.password_confirmation = "password123"
  user.role = :user
  user.is_verified = true
end

puts "Seeded #{User.count} users."
