# Seeds for test dummy app only
# This file only affects the dummy app's database, not the main engine

puts "Creating demo user for dummy app..."
demo_user = User.find_or_create_by(email: 'user@survey.com') do |user|
  user.password = '12345678'
  user.password_confirmation = '12345678'
end

if demo_user.persisted?
  puts "Demo user created: #{demo_user.email}"
else
  puts "Failed to create demo user: #{demo_user.errors.full_messages.join(', ')}"
end

# Create survey engine data for testing
puts "\nCreating SurveyEngine test data..."

# First, create question types
text_type = SurveyEngine::QuestionType.find_or_create_by(name: 'text') do |qt|
  qt.allows_options = false
  qt.allows_multiple_selections = false
end

scale_type = SurveyEngine::QuestionType.find_or_create_by(name: 'scale') do |qt|
  qt.allows_options = false
  qt.allows_multiple_selections = false
end

single_choice_type = SurveyEngine::QuestionType.find_or_create_by(name: 'single_choice') do |qt|
  qt.allows_options = true
  qt.allows_multiple_selections = false
end

matrix_scale_type = SurveyEngine::QuestionType.find_or_create_by(name: 'matrix_scale') do |qt|
  qt.allows_options = true
  qt.allows_multiple_selections = false
end

# Create survey templates
template1 = SurveyEngine::SurveyTemplate.find_or_create_by(name: 'Customer Satisfaction') do |template|
  template.is_active = true
end

template2 = SurveyEngine::SurveyTemplate.find_or_create_by(name: 'Employee Feedback') do |template|
  template.is_active = true
end

puts "Created survey templates: #{template1.name}, #{template2.name}"

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

puts "Created questions for both templates"

# Create surveys
survey1 = SurveyEngine::Survey.find_or_create_by(survey_template: template1, title: "Q1 2024 Customer Survey") do |s|
  s.is_active = true
  s.global = true
end

survey2 = SurveyEngine::Survey.find_or_create_by(survey_template: template2, title: "Employee Satisfaction Survey") do |s|
  s.is_active = true
  s.global = true
end

puts "Created surveys: #{survey1.title}, #{survey2.title}"

# Create participants and responses for Survey 1
participants_data = [
  'john@example.com',
  'jane@example.com', 
  'bob@example.com',
  'alice@example.com',
  'charlie@example.com'
]

puts "\nCreating participants and responses for Survey 1..."
participants_data.each_with_index do |email, index|
  participant = SurveyEngine::Participant.find_or_create_by(survey: survey1, email: email) do |p|
    p.status = 'completed'
    p.completed_at = Time.current - (index + 1).days
  end

  response = SurveyEngine::Response.find_or_create_by(survey: survey1, participant: participant) do |r|
    r.completed_at = participant.completed_at
  end

  # Create answers for q1 (scale)
  answer1 = SurveyEngine::Answer.find_or_create_by(response: response, question: q1) do |a|
    a.numeric_answer = [3, 4, 5, 4, 2][index]
  end

  # Create answers for q2 (text) - some empty
  if index < 3
    SurveyEngine::Answer.find_or_create_by(response: response, question: q2) do |a|
      a.text_answer = ["Great service!", "Could be faster", "More options needed"][index]
    end
  end

  # Create answers for q3 (single choice)
  selected_option = q3.options.to_a[[0, 0, 1, 2, 1][index]]
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
    p.status = 'completed'
    p.completed_at = Time.current - (index + 2).days
  end

  response = SurveyEngine::Response.find_or_create_by(survey: survey2, participant: participant) do |r|
    r.completed_at = participant.completed_at
  end

  # Create answers for q4 (scale 1-10)
  SurveyEngine::Answer.find_or_create_by(response: response, question: q4) do |a|
    a.numeric_answer = [7, 8, 6, 9, 5][index]
  end

  # Create answers for q5 (text) - some empty  
  if index < 4
    SurveyEngine::Answer.find_or_create_by(response: response, question: q5) do |a|
      a.text_answer = ["Better coffee", "Flexible hours", "More team events", "Quiet spaces"][index]
    end
  end

  puts "Created participant: #{email}"
end

puts "\n✅ Seed completed!"
puts "Created:"
puts "- 2 Survey Templates with questions"
puts "- 2 Active Surveys" 
puts "- 5 Participants per survey (#{participants_data.count * 2} total)"
puts "- Sample responses with various answer types"