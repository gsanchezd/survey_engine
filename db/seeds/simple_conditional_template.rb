# Simple Customer Experience Survey with Conditional Logic (3 Questions)
# Run with: rails runner db/seeds/simple_conditional_template.rb

# Create Simple Conditional Survey Template
simple_template = SurveyEngine::SurveyTemplate.create!(
  name: "Customer Experience Quick Survey",
  is_active: true
)

puts "Created Simple Conditional Template: #{simple_template.name}"

# Question 1: Did you find what you were looking for? (Yes/No - triggers conditional)
found_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'boolean'),
  title: "Did you find what you were looking for?",
  is_required: true,
  order_position: 1
)

puts "Created Question 1: Yes/No question"

# Question 2A: What were you looking for? (Conditional - shown only if NO)
looking_for_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'text'),
  title: "What were you looking for?",
  description: "Please help us understand what you needed",
  is_required: true,
  order_position: 2,
  conditional_parent_id: found_question.id,
  conditional_logic: {
    "type" => "show_if",
    "conditions" => [
      {
        "question_id" => found_question.id,
        "operator" => "equals",
        "value" => false
      }
    ]
  },
  placeholder_text: "I was looking for...",
  max_characters: 200
)

puts "Created Question 2A: What were you looking for? (Conditional - shown if NO)"

# Question 2B: How easy was it to find? (Conditional - shown only if YES)
ease_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'scale'),
  title: "How easy was it to find what you needed?",
  is_required: true,
  order_position: 2,
  conditional_parent_id: found_question.id,
  conditional_logic: {
    "type" => "show_if", 
    "conditions" => [
      {
        "question_id" => found_question.id,
        "operator" => "equals",
        "value" => true
      }
    ]
  },
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Very Difficult",
  scale_max_label: "Very Easy"
)

puts "Created Question 2B: How easy was it? (Conditional - shown if YES)"

# Question 3: Email for follow-up (Always shown)
email_question = SurveyEngine::Question.create!(
  survey_template: simple_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'email'),
  title: "Would you like to receive updates about improvements we make based on your feedback?",
  description: "Enter your email if interested (optional)",
  is_required: false,
  order_position: 3,
  placeholder_text: "your.email@example.com"
)

puts "Created Question 3: Email for updates"

puts "\nSimple Conditional Template created successfully!"
puts "Template ID: #{simple_template.id}"
puts "Total questions: #{simple_template.questions.count}"
puts "- 1 boolean question (triggers conditionals)"
puts "- 2 conditional questions (one shows if YES, one if NO)"
puts "- 1 optional email question"