class CreateDemoUser < ActiveRecord::Migration[8.0]
  def up
    # Create demo user for testing
    User.create!(
      email: 'user@survey.com',
      password: '12345678',
      password_confirmation: '12345678'
    )
  end

  def down
    User.find_by(email: 'user@survey.com')&.destroy
  end
end
