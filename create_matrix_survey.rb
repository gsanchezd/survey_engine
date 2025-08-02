#!/usr/bin/env ruby

# Script to create a survey with matrix questions (like the image shown)
# Run with: rails runner create_matrix_survey.rb

puts "Creating survey with matrix questions..."

# First, ensure we have the matrix question types
puts "Seeding question types..."
SurveyEngine::QuestionType.seed_standard_types

# Create the survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Evaluación de Módulo",
  description: "Plantilla para evaluar módulos de formación con preguntas tipo matriz",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')

# Create Matrix Question: Module Content Evaluation
matrix_question = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: matrix_scale_type,
  title: "¿Qué piensas del contenido del módulo?",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  is_required: true,
  order_position: 1,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)

puts "Created Matrix Question: #{matrix_question.title}"

# Create matrix scale options (columns)
scale_options = [
  { text: "1", value: "1", position: 1 },
  { text: "2", value: "2", position: 2 },
  { text: "3", value: "3", position: 3 },
  { text: "4", value: "4", position: 4 },
  { text: "5", value: "5", position: 5 }
]

scale_options.each do |opt|
  SurveyEngine::Option.create!(
    question: matrix_question,
    option_text: opt[:text],
    option_value: opt[:value],
    order_position: opt[:position],
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

puts "Created #{scale_options.count} scale options"

# Create matrix sub-questions (rows)
matrix_rows = [
  {
    text: "Los recursos de aprendizaje disponibles me permitieron alcanzar los aprendizajes del módulo y resolver las evaluaciones de forma satisfactoria.",
    position: 1
  },
  {
    text: "Pude resolver los desafíos del módulo a partir del material disponible.",
    position: 2
  },
  {
    text: "Pude resolver la prueba del módulo a partir de lo ejercitado en las unidades.",
    position: 3
  }
]

matrix_rows.each do |row|
  sub_question = SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: row[:text],  # Main question text
    matrix_row_text: row[:text],  # Same text for display as row
    description: "",
    is_required: true,
    order_position: matrix_question.order_position + row[:position],
    matrix_parent: matrix_question,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  
  puts "Created matrix row: #{sub_question.matrix_row_text[0..50]}..."
end

# Create the actual survey
survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Evaluación del Módulo de Formación",
  description: "Tu opinión es importante para mejorar nuestros contenidos educativos",
  is_active: true,
  global: true
)

puts "Created survey: #{survey.title} (UUID: #{survey.uuid})"

puts "\n=== Matrix Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /surveys/#{survey.uuid}"
puts "Test URL: /surveys/#{survey.uuid}?email=test@example.com"

puts "\n=== Matrix Question Structure ==="
puts "Parent Question: #{matrix_question.title}"
puts "Scale Options: #{scale_options.map { |o| o[:text] }.join(', ')}"
puts "Matrix Rows (Sub-questions): #{matrix_rows.count}"
matrix_question.matrix_sub_questions.each_with_index do |sub, i|
  puts "  #{i+1}. #{sub.matrix_row_text[0..60]}..."
end

puts "\n=== How It Works ==="
puts "1. Matrix parent question displays as a grid/table"
puts "2. Each row is a sub-question stored separately"
puts "3. All rows share the same scale options from parent"
puts "4. Each row's answer is stored as a separate Answer record"
puts "5. Results can be aggregated by grouping answers by matrix_parent_id"