require 'rails/generators'

module SurveyEngine
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc "Copy SurveyEngine views to your application"
      
      source_root File.expand_path('templates', __dir__)
      
      def copy_views
        directory 'views', 'app/views/survey_engine'
      end
      
      def copy_stylesheet
        copy_file 'stylesheets/survey_engine.css', 'app/assets/stylesheets/survey_engine.css'
      end
      
      def show_instructions
        say ""
        say "Views generated successfully!", :green
        say ""
        say "Add the following to your application layout to include the stylesheet:", :blue
        say "  <%= stylesheet_link_tag 'survey_engine' %>"
        say ""
        say "You can now customize the views in app/views/survey_engine/", :blue
      end
    end
  end
end