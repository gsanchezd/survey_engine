require 'rails/generators/base'

module SurveyEngine
  module Generators
    class ControllersGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      desc "Copies SurveyEngine controller to your application for customization"
      
      def copy_controllers
        copy_file 'surveys_controller.rb', 'app/controllers/survey_engine/surveys_controller.rb'
        say "✅ Created app/controllers/survey_engine/surveys_controller.rb", :green
      end
      
      def add_customization_notes
        say "\n💡 Controller Customization:", :cyan
        say "   - The controller now lives in your app and can be fully customized", :cyan
        say "   - All SurveyEngine models are available (Survey, Question, etc.)", :cyan
        say "   - You can override any action or add new ones", :cyan
        say "   - Matrix questions and conditional flow are fully supported", :cyan
        say "\n   To also customize views, run: rails generate survey_engine:views", :cyan
      end
    end
  end
end