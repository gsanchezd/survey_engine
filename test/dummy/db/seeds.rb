# Seeds for test dummy app only
# This file only affects the dummy app's database, not the main engine

puts "Creating demo user for dummy app..."
demo_user = User.find_or_create_by(email: 'user@survey.com') do |user|
  user.password = '12345678'
  user.password_confirmation = '12345678'
end

if demo_user.persisted?
  puts "Demo user created: #{demo_user.email}"
else
  puts "Failed to create demo user: #{demo_user.errors.full_messages.join(', ')}"
end