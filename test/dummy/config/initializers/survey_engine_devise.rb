# Configure SurveyEngine for dummy app (Devise authentication mode)
SurveyEngine.configure do |config|
  # Use Devise authentication instead of manual email input
  config.require_manual_email = false
  config.current_user_email_method = -> { current_user&.email }
end