#!/usr/bin/env ruby

# Script to clear old surveys and create a fresh test survey
# Run with: rails runner clear_and_recreate_survey.rb

puts "Clearing old test surveys..."

# Delete all surveys and related data
SurveyEngine::Survey.destroy_all
SurveyEngine::SurveyTemplate.destroy_all

puts "Creating fresh test survey with unique titles..."

# Ensure we have the matrix question types
SurveyEngine::QuestionType.seed_standard_types

# Create survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Fresh Matrix Test Template",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')
textarea_type = SurveyEngine::QuestionType.find_by(name: 'textarea')

# Question position counter
position = 1

# ========================================
# QUESTION 1: Matrix - Service Evaluation
# ========================================

service_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Evaluación del Servicio",
  description: "Califica cada aspecto usando la escala del 1 al 5",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create scale options (1-5)
scale_labels = [
  { text: "1", value: "1" },
  { text: "2", value: "2" },
  { text: "3", value: "3" },
  { text: "4", value: "4" },
  { text: "5", value: "5" }
]

scale_labels.each_with_index do |scale, index|
  SurveyEngine::Option.create!(
    question: service_matrix,
    option_text: scale[:text],
    option_value: scale[:value],
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for service
service_aspects = [
  "Atención recibida",
  "Tiempo de respuesta"
]

service_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect, # Use aspect as title
    matrix_row_text: aspect,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: service_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question 1: Service Evaluation (#{service_aspects.count} rows)"

# ========================================
# QUESTION 2: Matrix - Experience Satisfaction  
# ========================================

experience_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Satisfacción con la Experiencia",
  description: "Indica tu nivel de satisfacción con cada elemento",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create satisfaction scale options (same 1-5)
scale_labels.each_with_index do |scale, index|
  SurveyEngine::Option.create!(
    question: experience_matrix,
    option_text: scale[:text],
    option_value: scale[:value],
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for experience
experience_aspects = [
  "Facilidad de navegación",
  "Claridad de información"
]

experience_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect, # Use aspect as title
    matrix_row_text: aspect,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: experience_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question 2: Experience Satisfaction (#{experience_aspects.count} rows)"

# ========================================
# CREATE SURVEY
# ========================================

survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Nueva Encuesta de Matriz",
  is_active: true,
  global: true
)

# Create participant
participant = SurveyEngine::Participant.create!(
  survey: survey,
  email: "user@survey.com",
  status: "invited"
)

puts "\n=== Fresh Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /survey_engine/surveys/#{survey.uuid}?email=user@survey.com"
puts "Participant created for: user@survey.com"

puts "\n=== Survey Structure ==="
template.questions.where(matrix_parent_id: nil).ordered.each_with_index do |question, index|
  if question.is_matrix?
    puts "#{index + 1}. #{question.title} (MATRIX - #{question.matrix_sub_questions.count} rows)"
    question.matrix_sub_questions.ordered.each_with_index do |sub_q, sub_index|
      puts "   #{sub_index + 1}. #{sub_q.matrix_row_text}"
    end
  else
    puts "#{index + 1}. #{question.title} (#{question.question_type.name.upcase})"
  end
end

puts "\nFresh survey ready for testing!"