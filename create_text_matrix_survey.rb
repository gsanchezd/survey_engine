#!/usr/bin/env ruby

# Script to create a survey with text-based matrix questions (like Likert scales)
# Run with: rails runner create_text_matrix_survey.rb

puts "Creating survey with text-based matrix questions..."

# Ensure we have the matrix question types
SurveyEngine::QuestionType.seed_standard_types

# Create survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Encuesta de Satisfacción con Escalas de Texto",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')

# Question position counter
position = 1

# ========================================
# QUESTION 1: Matrix - Service Satisfaction with Text Labels
# ========================================

service_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué piensas del contenido del módulo?",
  description: "Por favor, indica tu nivel de acuerdo con las siguientes afirmaciones",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create Likert scale options with text labels
likert_labels = [
  { text: "Totalmente en desacuerdo", value: "1" },
  { text: "En desacuerdo", value: "2" },
  { text: "Neutral", value: "3" },
  { text: "De acuerdo", value: "4" },
  { text: "Totalmente de acuerdo", value: "5" }
]

likert_labels.each_with_index do |scale, index|
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

# Matrix sub-questions - statements to evaluate
satisfaction_statements = [
  "El contenido es relevante para mi trabajo",
  "La información está bien organizada",
  "Los ejemplos ayudan a comprender los conceptos",
  "El nivel de dificultad es apropiado"
]

satisfaction_statements.each_with_index do |statement, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: statement,
    matrix_row_text: statement,
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

puts "Created Matrix Question 1: Module Content Satisfaction (#{satisfaction_statements.count} statements)"

# ========================================
# QUESTION 2: Matrix - Learning Experience
# ========================================

learning_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Evaluación de la Experiencia de Aprendizaje",
  description: "Evalúa los siguientes aspectos de tu experiencia educativa",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create quality scale options
quality_labels = [
  { text: "Muy malo", value: "1" },
  { text: "Malo", value: "2" },
  { text: "Regular", value: "3" },
  { text: "Bueno", value: "4" },
  { text: "Excelente", value: "5" }
]

quality_labels.each_with_index do |scale, index|
  SurveyEngine::Option.create!(
    question: learning_matrix,
    option_text: scale[:text],
    option_value: scale[:value],
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for learning experience
learning_aspects = [
  "Claridad de las explicaciones",
  "Interactividad del material",
  "Apoyo del instructor"
]

learning_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect,
    matrix_row_text: aspect,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: learning_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question 2: Learning Experience (#{learning_aspects.count} aspects)"

# ========================================
# CREATE SURVEY
# ========================================

survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Encuesta de Satisfacción - Escalas de Texto",
  is_active: true,
  global: true
)

# Create participant
participant = SurveyEngine::Participant.create!(
  survey: survey,
  email: "user@survey.com",
  status: "invited"
)

puts "\n=== Text-Based Matrix Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /survey_engine/surveys/#{survey.uuid}"
puts "Participant created for: user@survey.com"

puts "\n=== Survey Structure ==="
template.questions.where(matrix_parent_id: nil).ordered.each_with_index do |question, index|
  if question.is_matrix?
    puts "#{index + 1}. #{question.title} (MATRIX - #{question.matrix_sub_questions.count} statements)"
    puts "   Scale options: #{question.options.ordered.pluck(:option_text).join(' | ')}"
    question.matrix_sub_questions.ordered.each_with_index do |sub_q, sub_index|
      puts "   #{sub_index + 1}. #{sub_q.matrix_row_text}"
    end
  else
    puts "#{index + 1}. #{question.title} (#{question.question_type.name.upcase})"
  end
end

puts "\n=== Matrix Questions Details ==="
template.questions.matrix_questions.each do |matrix_q|
  puts "\nMatrix: #{matrix_q.title}"
  puts "  Description: #{matrix_q.description}"
  puts "  Statements: #{matrix_q.matrix_sub_questions.count}"
  puts "  Scale: #{matrix_q.options.ordered.pluck(:option_text).join(' → ')}"
end

puts "\nText-based matrix survey ready for testing!"
puts "This survey includes:"
puts "- Likert scale (Totalmente en desacuerdo → Totalmente de acuerdo)"
puts "- Quality scale (Muy malo → Excelente)"
puts "- Semantic statements instead of numeric scales"