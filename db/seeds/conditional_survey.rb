# Create a Survey based on Product Satisfaction Template
# Run with: rails runner db/seeds/conditional_survey.rb

# Find the Product Satisfaction template
satisfaction_template = SurveyEngine::SurveyTemplate.find_by(name: "Product Satisfaction Survey")

unless satisfaction_template
  puts "Error: Product Satisfaction template not found. Please run the template seed first."
  exit
end

# Create a new survey based on the conditional template
satisfaction_survey = SurveyEngine::Survey.create!(
  title: "January 2025 Product Feedback",
  survey_template: satisfaction_template,
  is_active: true,
  global: true,
  uuid: SecureRandom.uuid
)

puts "Created Product Satisfaction Survey:"
puts "- Title: #{satisfaction_survey.title}"
puts "- Template: #{satisfaction_survey.survey_template.name}"
puts "- UUID: #{satisfaction_survey.uuid}"
puts "- Questions: #{satisfaction_survey.questions.count}"
puts "- Conditional questions: #{satisfaction_survey.questions.conditional_questions.count}"
puts "\nSurvey URL path: /survey_engine/surveys/#{satisfaction_survey.uuid}"
puts "\nConditional behavior:"
puts "- Users rating 1-2 will see: 'What issues did you experience?'"
puts "- Users rating 4-5 will see: 'Would you recommend our product?'"
puts "- Users rating 3 will only answer the main question"