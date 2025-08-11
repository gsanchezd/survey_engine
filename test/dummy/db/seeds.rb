# Seeds for test dummy app only
# This file only affects the dummy app's database, not the main engine

puts "Creating demo user for dummy app..."
demo_user = User.find_or_create_by(email: "user@survey.com") do |user|
  user.password = "12345678"
  user.password_confirmation = "12345678"
end

if demo_user.persisted?
  puts "Demo user created: #{demo_user.email}"
else
  puts "Failed to create demo user: #{demo_user.errors.full_messages.join(', ')}"
end

# Create survey engine data for testing
puts "\nCreating SurveyEngine test data..."

# First, create question types
text_type = SurveyEngine::QuestionType.find_or_create_by(name: "text") do |qt|
  qt.allows_options = false
  qt.allows_multiple_selections = false
end

scale_type = SurveyEngine::QuestionType.find_or_create_by(name: "scale") do |qt|
  qt.allows_options = false
  qt.allows_multiple_selections = false
end

single_choice_type = SurveyEngine::QuestionType.find_or_create_by(name: "single_choice") do |qt|
  qt.allows_options = true
  qt.allows_multiple_selections = false
end

matrix_scale_type = SurveyEngine::QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
  qt.allows_options = true
  qt.allows_multiple_selections = false
end

multiple_choice_type = SurveyEngine::QuestionType.find_or_create_by(name: "multiple_choice") do |qt|
  qt.allows_options = true
  qt.allows_multiple_selections = true
end

# Create survey templates
template1 = SurveyEngine::SurveyTemplate.find_or_create_by(name: "Customer Satisfaction") do |template|
  template.is_active = true
end

template2 = SurveyEngine::SurveyTemplate.find_or_create_by(name: "Employee Feedback") do |template|
  template.is_active = true
end

template3 = SurveyEngine::SurveyTemplate.find_or_create_by(name: "Product Evaluation") do |template|
  template.is_active = true
end

puts "Created survey templates: #{template1.name}, #{template2.name}, #{template3.name}"

# Create questions for template 1
q1 = SurveyEngine::Question.find_or_create_by(survey_template: template1, order_position: 1) do |q|
  q.question_type = scale_type
  q.title = "How satisfied are you with our service?"
  q.is_required = true
  q.scale_min = 1
  q.scale_max = 5
end

q2 = SurveyEngine::Question.find_or_create_by(survey_template: template1, order_position: 2) do |q|
  q.question_type = text_type
  q.title = "What could we improve?"
  q.is_required = false
end

q3 = SurveyEngine::Question.find_or_create_by(survey_template: template1, order_position: 3) do |q|
  q.question_type = single_choice_type
  q.title = "Would you recommend us?"
  q.is_required = true
end

# Create options for q3
SurveyEngine::Option.find_or_create_by(question: q3, order_position: 1) do |opt|
  opt.option_text = "Definitely"
  opt.option_value = "definitely"
end

SurveyEngine::Option.find_or_create_by(question: q3, order_position: 2) do |opt|
  opt.option_text = "Probably"
  opt.option_value = "probably"
end

SurveyEngine::Option.find_or_create_by(question: q3, order_position: 3) do |opt|
  opt.option_text = "Not sure"
  opt.option_value = "not_sure"
end

# Create questions for template 2
q4 = SurveyEngine::Question.find_or_create_by(survey_template: template2, order_position: 1) do |q|
  q.question_type = scale_type
  q.title = "How do you rate your work environment?"
  q.is_required = true
  q.scale_min = 1
  q.scale_max = 10
end

q5 = SurveyEngine::Question.find_or_create_by(survey_template: template2, order_position: 2) do |q|
  q.question_type = text_type
  q.title = "Any suggestions for improvement?"
  q.is_required = false
end

# Create questions for template 3 (with matrix and conditional flow)
q6 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 1) do |q|
  q.question_type = scale_type
  q.title = "Overall product rating"
  q.is_required = true
  q.scale_min = 1
  q.scale_max = 5
end

# Matrix parent question
matrix_parent = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 2) do |q|
  q.question_type = matrix_scale_type
  q.title = "Rate each aspect"
  q.is_required = true
  q.is_matrix_question = true
end

# Create options for matrix questions
opt1 = SurveyEngine::Option.find_or_create_by(question: matrix_parent, order_position: 1) do |opt|
  opt.option_text = "Poor"
  opt.option_value = "1"
end

opt2 = SurveyEngine::Option.find_or_create_by(question: matrix_parent, order_position: 2) do |opt|
  opt.option_text = "Fair"
  opt.option_value = "2"
end

opt3 = SurveyEngine::Option.find_or_create_by(question: matrix_parent, order_position: 3) do |opt|
  opt.option_text = "Good"
  opt.option_value = "3"
end

opt4 = SurveyEngine::Option.find_or_create_by(question: matrix_parent, order_position: 4) do |opt|
  opt.option_text = "Excellent"
  opt.option_value = "4"
end

# Matrix sub-questions
matrix_sub1 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 3) do |q|
  q.question_type = matrix_scale_type
  q.title = "Quality sub-question"
  q.is_required = true
  q.matrix_parent = matrix_parent
  q.matrix_row_text = "Quality"
end

matrix_sub2 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 4) do |q|
  q.question_type = matrix_scale_type
  q.title = "Value sub-question"
  q.is_required = true
  q.matrix_parent = matrix_parent
  q.matrix_row_text = "Value for money"
end

matrix_sub3 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 5) do |q|
  q.question_type = matrix_scale_type
  q.title = "Support sub-question"
  q.is_required = true
  q.matrix_parent = matrix_parent
  q.matrix_row_text = "Customer support"
end

# Conditional question (shows if overall rating <= 3)
q7 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 6) do |q|
  q.question_type = multiple_choice_type
  q.title = "What could we improve?"
  q.is_required = false
  q.conditional_parent = q6
  q.conditional_operator = "less_than_or_equal"
  q.conditional_value = 3
  q.conditional_logic_type = "single"
  q.show_if_condition_met = true
end

# Create options for conditional question
SurveyEngine::Option.find_or_create_by(question: q7, order_position: 1) do |opt|
  opt.option_text = "Product quality"
  opt.option_value = "quality"
end

SurveyEngine::Option.find_or_create_by(question: q7, order_position: 2) do |opt|
  opt.option_text = "Pricing"
  opt.option_value = "pricing"
end

SurveyEngine::Option.find_or_create_by(question: q7, order_position: 3) do |opt|
  opt.option_text = "Customer service"
  opt.option_value = "service"
end

SurveyEngine::Option.find_or_create_by(question: q7, order_position: 4) do |opt|
  opt.option_text = "Delivery speed"
  opt.option_value = "delivery"
end

# Final question for everyone
q8 = SurveyEngine::Question.find_or_create_by(survey_template: template3, order_position: 7) do |q|
  q.question_type = text_type
  q.title = "Any additional comments?"
  q.is_required = false
end

puts "Created questions for all three templates"

# Create surveys
survey1 = SurveyEngine::Survey.find_or_create_by(survey_template: template1, title: "Q1 2024 Customer Survey") do |s|
  s.is_active = true
  s.global = true
end

survey2 = SurveyEngine::Survey.find_or_create_by(survey_template: template2, title: "Employee Satisfaction Survey") do |s|
  s.is_active = true
  s.global = true
end

survey3 = SurveyEngine::Survey.find_or_create_by(survey_template: template3, title: "Product Evaluation Survey") do |s|
  s.is_active = true
  s.global = true
end

puts "Created surveys: #{survey1.title}, #{survey2.title}, #{survey3.title}"

# Create participants and responses for Survey 1
participants_data = [
  "john@example.com",
  "jane@example.com",
  "bob@example.com",
  "alice@example.com",
  "charlie@example.com"
]

puts "\nCreating participants and responses for Survey 1..."
participants_data.each_with_index do |email, index|
  participant = SurveyEngine::Participant.find_or_create_by(survey: survey1, email: email) do |p|
    p.status = "completed"
    p.completed_at = Time.current - (index + 1).days
  end

  response = SurveyEngine::Response.find_or_create_by(survey: survey1, participant: participant) do |r|
    r.completed_at = participant.completed_at
  end

  # Create answers for q1 (scale)
  answer1 = SurveyEngine::Answer.find_or_create_by(response: response, question: q1) do |a|
    a.numeric_answer = [ 3, 4, 5, 4, 2 ][index]
  end

  # Create answers for q2 (text) - some empty
  if index < 3
    SurveyEngine::Answer.find_or_create_by(response: response, question: q2) do |a|
      a.text_answer = [ "Great service!", "Could be faster", "More options needed" ][index]
    end
  end

  # Create answers for q3 (single choice)
  selected_option = q3.options.to_a[[ 0, 0, 1, 2, 1 ][index]]
  answer3 = SurveyEngine::Answer.find_by(response: response, question: q3)

  unless answer3
    answer3 = SurveyEngine::Answer.new(response: response, question: q3)
    answer3.answer_options.build(option: selected_option)
    answer3.save!
  end

  puts "Created participant: #{email}"
end

puts "\nCreating participants and responses for Survey 2..."
participants_data.each_with_index do |email, index|
  participant = SurveyEngine::Participant.find_or_create_by(survey: survey2, email: email) do |p|
    p.status = "completed"
    p.completed_at = Time.current - (index + 2).days
  end

  response = SurveyEngine::Response.find_or_create_by(survey: survey2, participant: participant) do |r|
    r.completed_at = participant.completed_at
  end

  # Create answers for q4 (scale 1-10)
  SurveyEngine::Answer.find_or_create_by(response: response, question: q4) do |a|
    a.numeric_answer = [ 7, 8, 6, 9, 5 ][index]
  end

  # Create answers for q5 (text) - some empty
  if index < 4
    SurveyEngine::Answer.find_or_create_by(response: response, question: q5) do |a|
      a.text_answer = [ "Better coffee", "Flexible hours", "More team events", "Quiet spaces" ][index]
    end
  end

  puts "Created participant: #{email}"
end

puts "\nCreating participants and responses for Survey 3 (Matrix & Conditional)..."
participants_data.each_with_index do |email, index|
  participant = SurveyEngine::Participant.find_or_create_by(survey: survey3, email: email) do |p|
    p.status = "completed"
    p.completed_at = Time.current - (index + 3).days
  end

  response = SurveyEngine::Response.find_or_create_by(survey: survey3, participant: participant) do |r|
    r.completed_at = participant.completed_at
  end

  # Create answers for q6 (overall rating 1-5)
  overall_rating = [ 2, 4, 3, 5, 1 ][index]  # Mix of high and low ratings
  SurveyEngine::Answer.find_or_create_by(response: response, question: q6) do |a|
    a.numeric_answer = overall_rating
  end

  # Create answers for matrix sub-questions
  # Matrix sub1 (Quality)
  quality_option = [ opt2, opt4, opt3, opt4, opt1 ][index]  # Fair, Excellent, Good, Excellent, Poor
  answer_sub1 = SurveyEngine::Answer.find_by(response: response, question: matrix_sub1)
  unless answer_sub1
    answer_sub1 = SurveyEngine::Answer.new(response: response, question: matrix_sub1)
    answer_sub1.answer_options.build(option: quality_option)
    answer_sub1.save!
  end

  # Matrix sub2 (Value)
  value_option = [ opt1, opt3, opt3, opt4, opt2 ][index]  # Poor, Good, Good, Excellent, Fair
  answer_sub2 = SurveyEngine::Answer.find_by(response: response, question: matrix_sub2)
  unless answer_sub2
    answer_sub2 = SurveyEngine::Answer.new(response: response, question: matrix_sub2)
    answer_sub2.answer_options.build(option: value_option)
    answer_sub2.save!
  end

  # Matrix sub3 (Support)
  support_option = [ opt3, opt4, opt2, opt4, opt1 ][index]  # Good, Excellent, Fair, Excellent, Poor
  answer_sub3 = SurveyEngine::Answer.find_by(response: response, question: matrix_sub3)
  unless answer_sub3
    answer_sub3 = SurveyEngine::Answer.new(response: response, question: matrix_sub3)
    answer_sub3.answer_options.build(option: support_option)
    answer_sub3.save!
  end

  # Create answers for q7 (conditional - only for ratings <= 3)
  if overall_rating <= 3
    answer7 = SurveyEngine::Answer.find_by(response: response, question: q7)
    unless answer7
      answer7 = SurveyEngine::Answer.new(response: response, question: q7)
      # Select multiple options for multiple choice
      if index == 0  # john - rating 2
        answer7.answer_options.build(option: q7.options.find_by(option_value: "quality"))
        answer7.answer_options.build(option: q7.options.find_by(option_value: "service"))
      elsif index == 2  # bob - rating 3
        answer7.answer_options.build(option: q7.options.find_by(option_value: "pricing"))
      elsif index == 4  # charlie - rating 1
        answer7.answer_options.build(option: q7.options.find_by(option_value: "quality"))
        answer7.answer_options.build(option: q7.options.find_by(option_value: "delivery"))
      end
      answer7.save! if answer7.answer_options.any?
    end
  end

  # Create answers for q8 (final comments) - some empty
  if index < 3
    SurveyEngine::Answer.find_or_create_by(response: response, question: q8) do |a|
      a.text_answer = [ "Needs improvement", "Great product overall", "Good value" ][index]
    end
  end

  puts "Created participant: #{email}"
end

puts "\n✅ Seed completed!"
puts "Created:"
puts "- 3 Survey Templates with questions"
puts "- 3 Active Surveys"
puts "- 5 Participants per survey (#{participants_data.count * 3} total)"
puts "- Sample responses including matrix questions and conditional flow"
