# Configure SurveyEngine for dummy app (Devise authentication mode)
SurveyEngine.configure do |config|
  # Use Devise authentication
  config.current_user_email_method = lambda { current_user&.email }
end