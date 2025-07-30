#!/usr/bin/env ruby

# Debug script to check the HTML output for conditional flow
# Run with: rails runner debug_conditional_html.rb

puts "=== Debugging Conditional Flow HTML Output ==="

# Include the helper
include SurveyEngine::ConditionalFlowHelper
include ActionView::Helpers::TagHelper
include ActionView::Helpers::FormTagHelper

survey = SurveyEngine::Survey.find_by(title: 'Product Satisfaction Survey')
questions = survey.questions.ordered.includes(:question_type, :options)

puts "\n1. Survey: #{survey.title}"
puts "   Questions: #{questions.count}"

questions.each_with_index do |question, index|
  puts "\n=== Question #{index + 1}: #{question.title} ==="
  puts "Type: #{question.question_type.name}"
  puts "Is conditional: #{question.is_conditional?}"
  puts "Has conditionals: #{question.has_conditional_questions?}"
  
  # Test conditional_question_container
  puts "\n--- Conditional Question Container HTML ---"
  container_html = conditional_question_container(question) do
    "QUESTION CONTENT GOES HERE"
  end
  puts container_html
  
  if question.question_type.name == 'scale'
    puts "\n--- Scale Input HTML ---"
    scale_html = conditional_scale_input(question, nil)
    puts scale_html
  end
  
  puts "\n" + ("="*60)
end

puts "\n=== JavaScript Configuration ==="
config = conditional_flow_config(survey)
puts config

puts "\n=== DONE ==="