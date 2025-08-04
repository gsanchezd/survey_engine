require 'rails/generators'

module SurveyEngine
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Install SurveyEngine configuration files"
      
      class_option :controller, type: :boolean, default: false, 
                   desc: "Generate custom surveys controller (optional)"
      class_option :locale, type: :string, default: "es", 
                   desc: "Set default locale (es or en)"
      
      def create_initializer
        template "survey_engine.rb", "config/initializers/survey_engine.rb"
      end
      
      def create_locale_config
        template "locale.rb", "config/initializers/locale.rb"
        
        # Update locale based on option
        if options[:locale] == "en"
          gsub_file "config/initializers/locale.rb", ":es", ":en"
        end
      end
      
      def create_locale_files
        template "survey_engine.es.yml", "config/locales/survey_engine.es.yml"
        template "survey_engine.en.yml", "config/locales/survey_engine.en.yml"
      end
      
      def copy_stylesheets
        source = File.expand_path("../../../../../app/assets/stylesheets/survey_engine/application.css", __FILE__)
        copy_file source, "app/assets/stylesheets/survey_engine.css"
        say "Copied survey_engine.css to app/assets/stylesheets/ for customization"
        say "You can now modify the CSS variables and styles to match your application's design"
      end
      
      def create_controller
        if options[:controller]
          template "surveys_controller.rb", "app/controllers/surveys_controller.rb"
          say "Custom SurveysController created at app/controllers/surveys_controller.rb"
          say "Remember to add custom routes to config/routes.rb"
        end
      end
      
      def show_readme
        readme "README" if File.exist?(File.expand_path("README", __dir__))
      end
      
      private
      
      def readme(path)
        say IO.read(File.expand_path(path, __dir__))
      end
    end
  end
end