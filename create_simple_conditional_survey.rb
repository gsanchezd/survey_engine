#!/usr/bin/env ruby

# Simple script to create a 2-question survey with conditional logic for testing
# Run with: rails runner create_simple_conditional_survey.rb

puts "Creating simple conditional survey for testing..."

# Create the survey
survey = SurveyEngine::Survey.create!(
  title: "Product Satisfaction Survey",
  description: "A simple 2-question survey to test conditional flow",
  status: "published",
  is_active: true,
  global: true
)

puts "Created survey: #{survey.title} (UUID: #{survey.uuid})"

# Get question types
scale_type = SurveyEngine::QuestionType.find_by(name: 'scale')
text_type = SurveyEngine::QuestionType.find_by(name: 'text')

# Question 1: Scale rating (1-5)
question1 = SurveyEngine::Question.create!(
  survey: survey,
  question_type: scale_type,
  title: "How satisfied are you with our product?",
  description: "Please rate your satisfaction on a scale of 1 to 5",
  is_required: true,
  order_position: 1,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Very Dissatisfied",
  scale_max_label: "Very Satisfied",
  allow_other: false,
  randomize_options: false
)

puts "Created Question 1: #{question1.title}"

# Question 2: Conditional text question (shows when rating <= 3)
question2 = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What can we do to improve your experience?",
  description: "Please tell us how we can make our product better for you",
  is_required: true,
  order_position: 2,
  allow_other: false,
  randomize_options: false,
  # Conditional logic fields
  conditional_parent_id: question1.id,
  conditional_operator: 'less_than_or_equal',
  conditional_value: 3,
  show_if_condition_met: true,
  placeholder_text: "Please share your feedback..."
)

puts "Created Question 2: #{question2.title}"
puts "  - Conditional: Shows when Q1 rating <= 3"

puts "\nSurvey created successfully!"
puts "Survey URL: /surveys/#{survey.uuid}"
puts "To test: /surveys/#{survey.uuid}?email=test@example.com"
puts "\nTest scenario:"
puts "1. Rate satisfaction as 1, 2, or 3 → Question 2 will appear"
puts "2. Rate satisfaction as 4 or 5 → Question 2 will be hidden"