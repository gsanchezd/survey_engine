# Set default locale to Spanish after Rails has loaded
Rails.application.config.after_initialize do
  I18n.default_locale = :es
  I18n.available_locales = [:es, :en]
end