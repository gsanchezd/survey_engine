# Configure SurveyEngine for dummy app (manual email input mode)
SurveyEngine.configure do |config|
  # Dummy app doesn't have authentication, so require manual email input
  config.require_manual_email = true
end