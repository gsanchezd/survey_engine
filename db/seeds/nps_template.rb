# NPS Survey Template Seed
# Run with: rails runner db/seeds/nps_template.rb

# Create NPS Survey Template
nps_template = SurveyEngine::SurveyTemplate.create!(
  name: "Net Promoter Score (NPS) Survey",
  is_active: true
)

puts "Created NPS Survey Template: #{nps_template.name}"

# Question 1: NPS Score Question (0-10 scale)
nps_question = SurveyEngine::Question.create!(
  survey_template: nps_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'scale'),
  title: "How likely are you to recommend our product/service to a friend or colleague?",
  description: "Please rate on a scale from 0 to 10",
  is_required: true,
  order_position: 1,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Not at all likely",
  scale_max_label: "Extremely likely"
)

puts "Created Question 1: NPS Score"

# Question 2: Reason for Score (Open-ended)
reason_question = SurveyEngine::Question.create!(
  survey_template: nps_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'textarea'),
  title: "What is the primary reason for your score?",
  description: "Please help us understand your rating",
  is_required: true,
  order_position: 2,
  placeholder_text: "Tell us more about your experience...",
  max_characters: 500
)

puts "Created Question 2: Reason for Score"

# Question 3: Improvement Suggestions (Multiple Choice with Other option)
improvement_question = SurveyEngine::Question.create!(
  survey_template: nps_template,
  question_type: SurveyEngine::QuestionType.find_by(name: 'multiple_choice'),
  title: "Which areas do you think we should improve? (Select all that apply)",
  description: "Your feedback helps us serve you better",
  is_required: false,
  order_position: 3,
  min_selections: 0,
  max_selections: nil,
  allow_other: true,
  randomize_options: false
)

# Add options for improvement question
improvement_options = [
  "Product quality",
  "Customer service",
  "Pricing",
  "User interface/experience",
  "Response time",
  "Documentation/Support materials",
  "Feature set",
  "Reliability/Performance"
]

improvement_options.each_with_index do |option_text, index|
  SurveyEngine::Option.create!(
    question: improvement_question,
    option_text: option_text,
    option_value: option_text.downcase.gsub(/[^a-z0-9]/, '_'),
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Add "Other" option
SurveyEngine::Option.create!(
  question: improvement_question,
  option_text: "Other",
  option_value: "other",
  order_position: improvement_options.length + 1,
  is_other: true,
  is_exclusive: false,
  is_active: true
)

# Add "None - Everything is great!" option (exclusive)
SurveyEngine::Option.create!(
  question: improvement_question,
  option_text: "None - Everything is great!",
  option_value: "none",
  order_position: improvement_options.length + 2,
  is_other: false,
  is_exclusive: true,
  is_active: true
)

puts "Created Question 3: Improvement Areas with #{improvement_options.length + 2} options"
puts "\nNPS Survey Template created successfully!"
puts "Template ID: #{nps_template.id}"
puts "Total questions: #{nps_template.questions.count}"