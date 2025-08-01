# Simple Survey with Scale-based Conditional Logic (3 Questions)
# Run with: rails runner db/seeds/simple_conditional_template_v2.rb

# Create Simple Conditional Survey Template
simple_template = SurveyEngine::SurveyTemplate.create!(
  name: "Product Satisfaction Survey",
  is_active: true
)

puts "Created Product Satisfaction Template: #{simple_template.name}"

# Question 1: Satisfaction Scale (1-5) - triggers conditional
satisfaction_scale = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'scale'),
  title: "How satisfied are you with our product?",
  is_required: true,
  order_position: 1,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Very Dissatisfied",
  scale_max_label: "Very Satisfied"
)

puts "Created Question 1: Satisfaction scale (1-5)"

# Question 2: What went wrong? (Conditional - shown only if satisfaction <= 2)
issues_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'textarea'),
  title: "We're sorry to hear that. What issues did you experience?",
  description: "Please help us understand what went wrong",
  is_required: true,
  order_position: 2,
  conditional_parent_id: satisfaction_scale.id,
  conditional_operator: 'less_than_or_equal',
  conditional_value: 2,
  show_if_condition_met: true,
  placeholder_text: "Please describe the issues...",
  max_characters: 500
)

puts "Created Question 2: Issues description (Conditional - shown if satisfaction <= 2)"

# Question 3: Would recommend? (Conditional - shown only if satisfaction >= 4)
recommend_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'boolean'),
  title: "Great to hear! Would you recommend our product to others?",
  is_required: true,
  order_position: 3,
  conditional_parent_id: satisfaction_scale.id,
  conditional_operator: 'greater_than_or_equal',
  conditional_value: 4,
  show_if_condition_met: true
)

puts "Created Question 3: Recommendation question (Conditional - shown if satisfaction >= 4)"

puts "\nProduct Satisfaction Template created successfully!"
puts "Template ID: #{simple_template.id}"
puts "Total questions: #{simple_template.questions.count}"
puts "Conditional logic:"
puts "- If satisfaction <= 2: Ask about issues"
puts "- If satisfaction >= 4: Ask about recommendation"
puts "- If satisfaction = 3: No additional questions"