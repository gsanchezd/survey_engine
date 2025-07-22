# SurveyEngine Demo Data Seeds
# This file should contain all the seed data needed for demo and testing purposes

puts "🌱 Starting SurveyEngine seed data generation..."

# Clear existing data in correct order to avoid FK constraints
puts "Clearing existing data..."
SurveyEngine::AnswerOption.delete_all
SurveyEngine::Answer.delete_all
SurveyEngine::Response.delete_all
SurveyEngine::Participant.delete_all
SurveyEngine::Option.delete_all
SurveyEngine::Question.delete_all
SurveyEngine::Survey.delete_all
SurveyEngine::QuestionType.delete_all

# 1. Create Question Types
puts "Creating question types..."

text_type = SurveyEngine::QuestionType.create!(
  name: "text",
  description: "Free text input",
  allows_options: false,
  allows_multiple_selections: false
)

single_choice_type = SurveyEngine::QuestionType.create!(
  name: "single_choice", 
  description: "Single selection",
  allows_options: true,
  allows_multiple_selections: false
)

multiple_choice_type = SurveyEngine::QuestionType.create!(
  name: "multiple_choice",
  description: "Multiple selections allowed",
  allows_options: true,
  allows_multiple_selections: true
)

scale_type = SurveyEngine::QuestionType.create!(
  name: "scale",
  description: "Numeric scale",
  allows_options: false,
  allows_multiple_selections: false
)

boolean_type = SurveyEngine::QuestionType.create!(
  name: "boolean",
  description: "Yes/No questions",
  allows_options: false,
  allows_multiple_selections: false
)

email_type = SurveyEngine::QuestionType.create!(
  name: "email",
  description: "Email address input",
  allows_options: false,
  allows_multiple_selections: false
)

number_type = SurveyEngine::QuestionType.create!(
  name: "number",
  description: "Numeric input",
  allows_options: false,
  allows_multiple_selections: false
)

date_type = SurveyEngine::QuestionType.create!(
  name: "date",
  description: "Date selection",
  allows_options: false,
  allows_multiple_selections: false
)

puts "✅ Created #{SurveyEngine::QuestionType.count} question types"

# 2. Create Survey Template
puts "Creating survey template..."

survey_template = SurveyEngine::Survey.create!(
  title: "Student Satisfaction Survey Template",
  description: "Evaluate student experience",
  status: "draft"
)

# 3. Add Questions to Survey Template
puts "Adding questions to survey template..."

# Text question
text_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: text_type,
  title: "What did you like most about the course?",
  description: "Please be specific",
  is_required: true,
  order_position: 1
)

# Scale question  
scale_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: scale_type,
  title: "How would you rate the overall course?",
  is_required: true,
  order_position: 2,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Poor",
  scale_max_label: "Excellent"
)

# Multiple choice question
choice_question = SurveyEngine::Question.create!(
  survey: survey_template,
  question_type: single_choice_type,
  title: "Which format did you prefer?",
  is_required: true,
  order_position: 3
)

# Add options to choice question
in_person_option = SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "In-person classes",
  option_value: "in_person", 
  order_position: 1
)

online_option = SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Online sessions",
  option_value: "online",
  order_position: 2
)

hybrid_option = SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Hybrid approach",
  option_value: "hybrid",
  order_position: 3
)

# "Other" option with text input
other_option = SurveyEngine::Option.create!(
  question: choice_question,
  option_text: "Other",
  option_value: "other",
  order_position: 4,
  is_other: true
)

puts "✅ Created #{survey_template.questions.count} questions with #{choice_question.options.count} options"

# 4. Deploy Survey to Cohorts
puts "Deploying surveys to cohorts..."

cohort_ids = [
  "cohort_spring_2024",
  "cohort_summer_2024", 
  "cohort_fall_2024",
  "cohort_enterprise_pilot",
  "cohort_beta_users",
  "cohort_premium_customers"
]

cohort_surveys = []

cohort_ids.each do |cohort_id|
  # Create survey for this cohort
  cohort_survey = SurveyEngine::Survey.create!(
    title: "#{survey_template.title} - #{cohort_id}",
    description: survey_template.description,
    status: "draft"
  )
  
  # Copy questions from template
  survey_template.questions.ordered.each do |template_question|
    new_question = SurveyEngine::Question.create!(
      survey: cohort_survey,
      question_type: template_question.question_type,
      title: template_question.title,
      description: template_question.description,
      is_required: template_question.is_required,
      order_position: template_question.order_position,
      scale_min: template_question.scale_min,
      scale_max: template_question.scale_max,
      scale_min_label: template_question.scale_min_label,
      scale_max_label: template_question.scale_max_label
    )
    
    # Copy options if question has them
    template_question.options.ordered.each do |template_option|
      SurveyEngine::Option.create!(
        question: new_question,
        option_text: template_option.option_text,
        option_value: template_option.option_value,
        order_position: template_option.order_position,
        is_other: template_option.is_other,
        is_exclusive: template_option.is_exclusive
      )
    end
  end
  
  # Publish the survey
  cohort_survey.publish!
  cohort_surveys << cohort_survey
  
  puts "✅ Created and published survey for #{cohort_id}"
end

# 5. Create NPS Survey Template
puts "Creating NPS survey template..."

nps_template = SurveyEngine::Survey.create!(
  title: "Net Promoter Score Survey Template",
  description: "Measure customer satisfaction and loyalty",
  status: "draft"
)

# Add the main NPS question (0-10 scale)
nps_question = SurveyEngine::Question.create!(
  survey: nps_template,
  question_type: scale_type,
  title: "How likely are you to recommend our service to a friend or colleague?",
  description: "Please rate on a scale from 0 (not at all likely) to 10 (extremely likely)",
  is_required: true,
  order_position: 1,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Not at all likely",
  scale_max_label: "Extremely likely"
)

# Add follow-up question for feedback
feedback_question = SurveyEngine::Question.create!(
  survey: nps_template,
  question_type: text_type,
  title: "What is the primary reason for your score?",
  description: "Please help us understand your rating",
  is_required: false,
  order_position: 2,
  placeholder_text: "Tell us what influenced your rating..."
)

puts "✅ NPS Survey template created"

# 6. Deploy NPS to Cohorts
puts "Deploying NPS surveys to cohorts..."

nps_cohort_ids = ["cohort_q1_2024", "cohort_q2_2024", "cohort_enterprise_2024"]
nps_surveys = []

nps_cohort_ids.each do |cohort_id|
  # Create cohort-specific survey
  cohort_survey = SurveyEngine::Survey.create!(
    title: "NPS Survey - #{cohort_id}",
    description: nps_template.description,
    status: "draft"
  )
  
  # Copy NPS question
  nps_q = SurveyEngine::Question.create!(
    survey: cohort_survey,
    question_type: scale_type,
    title: nps_question.title,
    description: nps_question.description,
    is_required: nps_question.is_required,
    order_position: nps_question.order_position,
    scale_min: nps_question.scale_min,
    scale_max: nps_question.scale_max,
    scale_min_label: nps_question.scale_min_label,
    scale_max_label: nps_question.scale_max_label
  )
  
  # Copy feedback question
  feedback_q = SurveyEngine::Question.create!(
    survey: cohort_survey,
    question_type: text_type,
    title: feedback_question.title,
    description: feedback_question.description,
    is_required: feedback_question.is_required,
    order_position: feedback_question.order_position,
    placeholder_text: feedback_question.placeholder_text
  )
  
  # Publish the survey
  cohort_survey.publish!
  nps_surveys << cohort_survey
  
  puts "✅ Created and published NPS survey for #{cohort_id}"
end

# 7. Simulate Survey Responses for Student Satisfaction Survey
puts "Simulating survey responses for student satisfaction survey..."

# Work with the first cohort survey
survey = cohort_surveys.first
text_q = survey.questions.find_by(order_position: 1)
scale_q = survey.questions.find_by(order_position: 2) 
choice_q = survey.questions.find_by(order_position: 3)

# Get choice options
in_person_opt = choice_q.options.find_by(option_value: "in_person")
online_opt = choice_q.options.find_by(option_value: "online")
hybrid_opt = choice_q.options.find_by(option_value: "hybrid")
other_opt = choice_q.options.find_by(option_value: "other")

# Simulate responses from different participants
participants_data = [
  {
    email: "alice.student@university.edu",
    text_answer: "The interactive sessions and practical examples were excellent",
    scale_answer: 5,
    choice_option: in_person_opt
  },
  {
    email: "bob.learner@college.edu", 
    text_answer: "Good content but could use more hands-on exercises",
    scale_answer: 4,
    choice_option: hybrid_opt
  },
  {
    email: "carol.pupil@school.edu",
    text_answer: "Amazing course! Very well structured and informative",
    scale_answer: 5,
    choice_option: online_opt
  },
  {
    email: "david.scholar@academy.edu",
    text_answer: "The course was okay, nothing exceptional",
    scale_answer: 3,
    choice_option: in_person_opt
  },
  {
    email: "eve.trainee@institute.edu",
    text_answer: "Loved the flexibility and personalized feedback approach",
    scale_answer: 4,
    choice_option: other_opt,
    other_text: "Self-paced online with weekly mentorship calls"
  }
]

# Create responses for each participant
participants_data.each do |participant_data|
  # Create participant
  participant = SurveyEngine::Participant.create!(
    survey: survey,
    email: participant_data[:email],
    status: 'invited'
  )
  
  # Start response
  response = SurveyEngine::Response.create!(
    survey: survey,
    participant: participant
  )
  
  # Answer text question
  text_answer = SurveyEngine::Answer.create!(
    response: response,
    question: text_q,
    text_answer: participant_data[:text_answer]
  )
  
  # Answer scale question
  scale_answer = SurveyEngine::Answer.create!(
    response: response,
    question: scale_q,
    numeric_answer: participant_data[:scale_answer]
  )
  
  # Answer choice question - build association and save properly
  choice_answer = SurveyEngine::Answer.new(
    response: response,
    question: choice_q
  )
  choice_answer.answer_options.build(option: participant_data[:choice_option])
  choice_answer.save!
  
  # Add other text if it's an "other" option
  if participant_data[:choice_option] == other_opt && participant_data[:other_text]
    choice_answer.update!(other_text: participant_data[:other_text])
  end
  
  # Complete the response
  response.complete!
  participant.complete!
end

puts "✅ Created #{participants_data.count} survey responses"

# 8. Simulate NPS Survey Responses
puts "Simulating NPS survey responses..."

# Work with the first NPS survey
nps_survey = nps_surveys.first
nps_q = nps_survey.questions.find_by(order_position: 1)
feedback_q = nps_survey.questions.find_by(order_position: 2)

# Simulate various customer responses
nps_customer_responses = [
  { email: "alice@company.com", nps_score: 9, feedback: "Great service, very responsive support team!" },
  { email: "bob@startup.com", nps_score: 7, feedback: "Good overall, but could improve response times" },
  { email: "carol@enterprise.com", nps_score: 10, feedback: "Outstanding! Exceeded all expectations" },
  { email: "david@agency.com", nps_score: 6, feedback: "Average service, nothing special" },
  { email: "eve@tech.com", nps_score: 3, feedback: "Had several issues, support was slow to respond" },
  { email: "frank@consulting.com", nps_score: 8, feedback: "Really solid product, minor UI improvements needed" }
]

# Create responses for each customer
nps_customer_responses.each do |customer|
  # Create participant
  participant = SurveyEngine::Participant.create!(
    survey: nps_survey,
    email: customer[:email],
    status: 'invited'
  )
  
  # Create response
  response = SurveyEngine::Response.create!(
    survey: nps_survey,
    participant: participant
  )
  
  # Answer NPS question
  nps_answer = SurveyEngine::Answer.create!(
    response: response,
    question: nps_q,
    numeric_answer: customer[:nps_score]
  )
  
  # Answer feedback question
  feedback_answer = SurveyEngine::Answer.create!(
    response: response,
    question: feedback_q,
    text_answer: customer[:feedback]
  )
  
  # Complete the response
  response.complete!
  participant.complete!
end

puts "✅ Created #{nps_customer_responses.count} NPS responses"

# 9. Display Summary
puts "\n📊 SEED DATA SUMMARY"
puts "=" * 50
puts "Question Types: #{SurveyEngine::QuestionType.count}"
puts "Surveys: #{SurveyEngine::Survey.count}"
puts "Questions: #{SurveyEngine::Question.count}"
puts "Options: #{SurveyEngine::Option.count}"
puts "Participants: #{SurveyEngine::Participant.count}"
puts "Responses: #{SurveyEngine::Response.count}"
puts "Answers: #{SurveyEngine::Answer.count}"
puts "Answer Options: #{SurveyEngine::AnswerOption.count}"

puts "\nSurvey Details:"
SurveyEngine::Survey.all.each do |survey|
  completion_rate = survey.participants.any? ? 
    (survey.participants.completed.count.to_f / survey.participants.count * 100).round(1) : 0
  puts "  #{survey.title}: #{survey.participants.count} participants, #{completion_rate}% completion rate"
end

puts "\n🎉 Seed data generation completed successfully!"
puts "You can now test the SurveyEngine with realistic data."
puts "Run 'rails console' to interact with the data."