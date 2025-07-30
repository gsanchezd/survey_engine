#!/usr/bin/env ruby

# Script to create a test survey with conditional flow questions
# Run with: cd test/dummy && ruby ../../create_conditional_survey.rb

require_relative 'test/dummy/config/environment'

puts "🔄 Creating test survey with conditional flow questions..."
puts "=" * 60

# Ensure question types exist
puts "\n📋 Setting up question types..."
SurveyEngine::QuestionType.seed_standard_types

scale_type = SurveyEngine::QuestionType.find_by(name: 'scale')
text_type = SurveyEngine::QuestionType.find_by(name: 'text')
single_choice_type = SurveyEngine::QuestionType.find_by(name: 'single_choice')

puts "   ✓ Scale type: #{scale_type.name}"
puts "   ✓ Text type: #{text_type.name}"
puts "   ✓ Single choice type: #{single_choice_type.name}"

# Create the survey
puts "\n🏗️  Creating survey..."
survey = SurveyEngine::Survey.create!(
  title: "Customer Experience Survey with Conditional Flow",
  description: "Help us understand your experience with our service. This survey uses conditional questions that appear based on your previous answers.",
  status: "published",
  is_active: true,
  published_at: Time.current
)

puts "   ✓ Survey created: #{survey.title}"
puts "   ✓ Survey UUID: #{survey.uuid}"

# Question 1: Overall Satisfaction (Scale 1-10) - Parent question
puts "\n❓ Creating main satisfaction question..."
satisfaction_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: scale_type,
  title: "How satisfied are you with our service overall?",
  description: "Please rate your overall satisfaction on a scale from 1 to 10",
  scale_min: 1,
  scale_max: 10,
  scale_min_label: "Very Unsatisfied",
  scale_max_label: "Very Satisfied",
  is_required: true,
  order_position: 1
)

puts "   ✓ Main question: #{satisfaction_question.title}"

# Question 2: Low Satisfaction Follow-up (appears if rating < 6)
puts "\n❓ Creating low satisfaction conditional question..."
low_satisfaction_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What specific areas need improvement?",
  description: "Since you rated us below 6, please tell us what we can do better",
  conditional_parent: satisfaction_question,
  conditional_operator: "less_than",
  conditional_value: 6,
  show_if_condition_met: true,
  is_required: true,
  order_position: 2
)

puts "   ✓ Low satisfaction question: #{low_satisfaction_question.title}"
puts "     └─ Shows when satisfaction < 6"

# Question 3: High Satisfaction Follow-up (appears if rating >= 8)
puts "\n❓ Creating high satisfaction conditional question..."
high_satisfaction_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What did we do particularly well?",
  description: "We're glad you're satisfied! Please tell us what we're doing right",
  conditional_parent: satisfaction_question,
  conditional_operator: "greater_than_or_equal",
  conditional_value: 8,
  show_if_condition_met: true,
  is_required: false,
  order_position: 3
)

puts "   ✓ High satisfaction question: #{high_satisfaction_question.title}"
puts "     └─ Shows when satisfaction >= 8"

# Question 4: Service Type (Single Choice) - Another parent question
puts "\n❓ Creating service type question..."
service_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: single_choice_type,
  title: "Which service did you primarily use?",
  description: "Select the main service you interacted with",
  is_required: true,
  order_position: 4
)

# Create options for service question
puts "   ✓ Creating service options..."
support_option = SurveyEngine::Option.create!(
  question: service_question,
  option_text: "Customer Support",
  option_value: "support",
  order_position: 1
)

sales_option = SurveyEngine::Option.create!(
  question: service_question,
  option_text: "Sales",
  option_value: "sales",
  order_position: 2
)

technical_option = SurveyEngine::Option.create!(
  question: service_question,
  option_text: "Technical Support",
  option_value: "technical",
  order_position: 3
)

billing_option = SurveyEngine::Option.create!(
  question: service_question,
  option_text: "Billing",
  option_value: "billing",
  order_position: 4
)

puts "     ✓ Support, Sales, Technical, Billing options created"

# Question 5: Recommendation Score (NPS-style) - Another parent
puts "\n❓ Creating NPS question..."
nps_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: scale_type,
  title: "How likely are you to recommend us to a friend or colleague?",
  description: "Rate from 1 (not at all likely) to 10 (extremely likely)",
  scale_min: 1,
  scale_max: 10,
  scale_min_label: "Not at all likely",
  scale_max_label: "Extremely likely",
  is_required: true,
  order_position: 5
)

puts "   ✓ NPS question: #{nps_question.title}"

# Question 6: Detractor follow-up (appears if NPS <= 6)
puts "\n❓ Creating detractor conditional question..."
detractor_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What is the primary reason you would not recommend us?",
  description: "Please help us understand what we need to improve",
  conditional_parent: nps_question,
  conditional_operator: "less_than_or_equal",
  conditional_value: 6,
  show_if_condition_met: true,
  is_required: true,
  order_position: 6
)

puts "   ✓ Detractor question: #{detractor_question.title}"
puts "     └─ Shows when NPS <= 6"

# Question 7: Promoter follow-up (appears if NPS >= 9)
puts "\n❓ Creating promoter conditional question..."
promoter_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "What would you tell others about us?",
  description: "We'd love to know what you'd say when recommending us!",
  conditional_parent: nps_question,
  conditional_operator: "greater_than_or_equal",
  conditional_value: 9,
  show_if_condition_met: true,
  is_required: false,
  order_position: 7
)

puts "   ✓ Promoter question: #{promoter_question.title}"
puts "     └─ Shows when NPS >= 9"

# Question 8: Complex conditional - shows only for high satisfaction AND high NPS
puts "\n❓ Creating complex conditional question..."
# Note: This demonstrates a limitation - currently we only support single parent conditions
# For complex conditions, you'd need multiple conditional questions or enhanced logic

loyalty_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "Would you be interested in becoming a brand ambassador?",
  description: "Based on your positive feedback, we'd love to explore partnership opportunities",
  conditional_parent: nps_question, # Using NPS as the trigger
  conditional_operator: "equal_to",
  conditional_value: 10,
  show_if_condition_met: true,
  is_required: false,
  order_position: 8
)

puts "   ✓ Loyalty question: #{loyalty_question.title}"
puts "     └─ Shows when NPS = 10 (perfect score)"

# Question 9: Always visible closing question
puts "\n❓ Creating final question..."
final_question = SurveyEngine::Question.create!(
  survey: survey,
  question_type: text_type,
  title: "Any additional comments?",
  description: "Please share any other thoughts or feedback you have",
  is_required: false,
  order_position: 9
)

puts "   ✓ Final question: #{final_question.title}"

# Summary
puts "\n📊 Survey Creation Summary:"
puts "=" * 60
puts "Survey: #{survey.title}"
puts "Total Questions: #{survey.questions.count}"
puts "Root Questions: #{survey.questions.root_questions.count}"
puts "Conditional Questions: #{survey.questions.conditional_questions.count}"

puts "\n🔗 Question Flow:"
survey.questions.root_questions.ordered.each do |question|
  puts "#{question.order_position}. #{question.title}"
  
  question.conditional_questions.each do |conditional|
    condition_text = "#{conditional.conditional_operator.humanize} #{conditional.conditional_value}"
    show_text = conditional.show_if_condition_met? ? "shows" : "hides"
    puts "   └─ #{conditional.order_position}. #{conditional.title} (#{show_text} when #{condition_text})"
  end
end

puts "\n🌐 Survey URL:"
puts "http://localhost:3000/surveys/#{survey.uuid}"

puts "\n🧪 Test Scenarios:"
puts "1. Rate satisfaction 1-5 → See improvement question"
puts "2. Rate satisfaction 8-10 → See 'what we do well' question"  
puts "3. Rate NPS 1-6 → See 'why not recommend' question"
puts "4. Rate NPS 9-10 → See 'what would you tell others' question"
puts "5. Rate NPS exactly 10 → See brand ambassador question"

puts "\n✅ Survey created successfully!"
puts "Start the dummy app and visit the URL above to test conditional flow."