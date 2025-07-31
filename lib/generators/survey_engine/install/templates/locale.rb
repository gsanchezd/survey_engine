# Set default locale for SurveyEngine
# Change :es to :en if you prefer English as default
Rails.application.config.after_initialize do
  I18n.default_locale = :es
  I18n.available_locales = [:es, :en]
end