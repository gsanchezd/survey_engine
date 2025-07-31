# SurveyEngine Configuration
SurveyEngine.configure do |config|
  # Configure how to get the current user's email for survey participation
  # This should return the email address of the currently signed-in user
  # 
  # For Devise authentication:
  config.current_user_email_method = lambda { current_user&.email }
  
  # For other authentication systems, modify as needed:
  # config.current_user_email_method = lambda { session[:user_email] }
  # config.current_user_email_method = lambda { current_person&.email_address }
end