module SurveyEngine
  class Engine < ::Rails::Engine
    isolate_namespace SurveyEngine
    
    # Configure i18n
    config.after_initialize do
      # Set Spanish as default locale after all initializers have run
      I18n.default_locale = :es
      I18n.available_locales = [:es, :en]
    end
  end
end
