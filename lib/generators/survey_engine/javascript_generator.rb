require 'rails/generators'

module SurveyEngine
  module Generators
    class JavascriptGenerator < Rails::Generators::Base
      desc "Export SurveyEngine JavaScript files for customization"
      
      source_root File.expand_path('templates', __dir__)
      
      class_option :output_path, type: :string, default: "app/assets/javascripts/survey_engine", 
                   desc: "Output path for JavaScript files"
      
      def copy_javascript_files
        say "Exporting SurveyEngine JavaScript files...", :green
        
        # Read the JavaScript file content and create the destination file
        # From: lib/generators/survey_engine/javascript_generator.rb 
        # To:   app/assets/javascripts/survey_engine/application.js
        source_path = File.expand_path("../../../app/assets/javascripts/survey_engine/application.js", __dir__)
        destination_path = File.join(options[:output_path], "survey_engine.js")
        
        if File.exist?(source_path)
          javascript_content = File.read(source_path)
          create_file destination_path, javascript_content
          say "Copied survey_engine.js to #{options[:output_path]}/ for customization"
        else
          say "Error: Could not find source JavaScript file at #{source_path}", :red
        end
        
        say ""
        say "JavaScript files exported successfully!", :green
        say ""
        show_usage_instructions
      end
      
      private
      
      def show_usage_instructions
        say "Files exported:", :blue
        say "  - #{File.join(options[:output_path], 'survey_engine.js')}"
        say ""
        say "Usage Instructions:", :blue
        say "1. Include the JavaScript file in your application:"
        say "   <%= javascript_include_tag 'survey_engine/survey_engine' %>"
        say ""
        say "2. Initialize the conditional flow system:"
        say "   <script>"
        say "     document.addEventListener('DOMContentLoaded', function() {"
        say "       if (typeof SurveyConditionalFlow !== 'undefined') {"
        say "         window.surveyConditionalFlow = new SurveyConditionalFlow();"
        say "         window.surveyConditionalFlow.initialize();"
        say "       }"
        say "     });"
        say "   </script>"
        say ""
        say "3. For Matrix questions, the initialization is automatic"
        say "4. For Ranking questions, the initialization is automatic"
        say ""
        say "Features included:", :blue
        say "  - Conditional flow logic for surveys"
        say "  - Matrix question interactions"
        say "  - Ranking question drag-and-drop"
        say "  - Touch support for mobile devices"
        say "  - Accessibility features"
        say ""
        say "You can now customize these JavaScript files as needed for your project.", :blue
      end
    end
  end
end