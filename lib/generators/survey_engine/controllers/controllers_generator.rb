require 'rails/generators/base'

module SurveyEngine
  module Generators
    class ControllersGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      def copy_controllers
        copy_file 'surveys_controller.rb', 'app/controllers/survey_engine/surveys_controller.rb'
      end
    end
  end
end