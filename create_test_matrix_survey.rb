#!/usr/bin/env ruby

# Script to create a simple test survey with matrix questions
# Run with: rails runner create_test_matrix_survey.rb

puts "Creating test survey with matrix questions..."

# Ensure we have the matrix question types
SurveyEngine::QuestionType.seed_standard_types

# Create survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Test Matrix Survey Template",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')
textarea_type = SurveyEngine::QuestionType.find_by(name: 'textarea')

# Question position counter
position = 1

# ========================================
# QUESTION 1: Matrix - Service Quality
# ========================================

service_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Cómo evalúas nuestro servicio?",
  description: "Evalúa los siguientes aspectos de nuestro servicio en una escala del 1 al 5, donde 1 es 'Muy malo' y 5 es 'Excelente'",
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
  { text: "1", value: "1", label: "Muy malo" },
  { text: "2", value: "2", label: "Malo" },
  { text: "3", value: "3", label: "Regular" },
  { text: "4", value: "4", label: "Bueno" },
  { text: "5", value: "5", label: "Excelente" }
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
  "Atención al cliente",
  "Rapidez del servicio",
  "Calidad del producto",
  "Relación precio-calidad"
]

service_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect,
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

puts "Created Matrix Question 1: Service Quality (#{service_aspects.count} rows)"

# ========================================
# QUESTION 2: Text Area - Additional Comments
# ========================================

SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Tienes algún comentario adicional sobre nuestro servicio?",
  description: "Comparte cualquier sugerencia o comentario que nos pueda ayudar a mejorar",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Escribe aquí tus comentarios...",
  max_characters: 500
)
position += 1

puts "Created Text Question: Additional Comments"

# ========================================
# QUESTION 3: Matrix - Experience Satisfaction
# ========================================

experience_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué tan satisfecho estás con tu experiencia?",
  description: "Evalúa los siguientes aspectos de tu experiencia usando la escala: 1 = Muy insatisfecho, 2 = Insatisfecho, 3 = Neutral, 4 = Satisfecho, 5 = Muy satisfecho",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create satisfaction scale options (same 1-5 but different labels)
satisfaction_labels = [
  { text: "1", value: "1", label: "Muy insatisfecho" },
  { text: "2", value: "2", label: "Insatisfecho" },
  { text: "3", value: "3", label: "Neutral" },
  { text: "4", value: "4", label: "Satisfecho" },
  { text: "5", value: "5", label: "Muy satisfecho" }
]

satisfaction_labels.each_with_index do |scale, index|
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
  "Facilidad de uso del sitio web",
  "Proceso de compra",
  "Tiempo de entrega"
]

experience_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect,
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
  title: "Encuesta de Prueba - Preguntas Matriz",
  is_active: true,
  global: true
)

puts "\n=== Test Matrix Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /surveys/#{survey.uuid}"
puts "Test URL: /surveys/#{survey.uuid}?email=test@example.com"

puts "\n=== Survey Structure ==="
puts "Total questions: #{template.questions.count}"
puts "Matrix questions: #{template.questions.matrix_questions.count}"
puts "Matrix rows: #{template.questions.matrix_rows.count}"
puts "Regular questions: #{template.questions.non_matrix_questions.count}"

puts "\n=== Questions Overview ==="
template.questions.where(matrix_parent_id: nil).ordered.each_with_index do |question, index|
  if question.is_matrix?
    puts "#{index + 1}. #{question.title} (MATRIX - #{question.matrix_sub_questions.count} rows x #{question.options.count} columns)"
    question.matrix_sub_questions.ordered.each_with_index do |sub_q, sub_index|
      puts "   #{sub_index + 1}. #{sub_q.matrix_row_text}"
    end
  else
    puts "#{index + 1}. #{question.title} (#{question.question_type.name.upcase})"
  end
end

puts "\n=== Matrix Details ==="
template.questions.matrix_questions.each do |matrix_q|
  puts "\nMatrix: #{matrix_q.title}"
  puts "  Rows: #{matrix_q.matrix_sub_questions.count}"
  puts "  Columns: #{matrix_q.options.count}"
  puts "  Options: #{matrix_q.options.ordered.pluck(:option_text).join(', ')}"
end

puts "\n=== Test Instructions ==="
puts "1. Visit the survey URL in your browser"
puts "2. Fill out the matrix questions by clicking radio buttons"
puts "3. Test keyboard navigation with arrow keys"
puts "4. Verify that answers are saved correctly"
puts "5. Submit the survey and check completion"

puts "\nThe survey is ready for testing!"