#!/usr/bin/env ruby

# Script to create a simple conditional survey for testing CSS and conditional logic
# Run with: rails runner create_conditional_test_survey.rb

puts "Creating conditional survey with matrix and flow logic..."

# Ensure we have the question types
SurveyEngine::QuestionType.seed_standard_types

# Create survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Test Conditional Survey with Matrix",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')
scale_type = SurveyEngine::QuestionType.find_by(name: 'scale')
textarea_type = SurveyEngine::QuestionType.find_by(name: 'textarea')
multiple_choice_type = SurveyEngine::QuestionType.find_by(name: 'multiple_choice')

# Question position counter
position = 1

puts "Creating questions with conditional flow..."

# ========================================
# QUESTION 1: NPS Scale (0-10) - Parent Question
# ========================================

nps_question = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué tan probable es que recomiendes nuestro servicio?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Muy probable'",
  question_type: scale_type,
  is_required: true,
  order_position: position,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Muy probable",
  is_matrix_question: false,
  allow_other: false,
  randomize_options: false
)
position += 1

puts "Created NPS Question (Parent): #{nps_question.title}"

# ========================================
# QUESTION 2: Conditional for Detractors (0-6)
# ========================================

detractors_question = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué podríamos mejorar en nuestro servicio?",
  description: "Ayúdanos a entender qué aspectos necesitan mejora",
  question_type: multiple_choice_type,
  is_required: true,
  order_position: position,
  conditional_parent: nps_question,
  conditional_operator: 'less_than_or_equal',
  conditional_value: 6,
  show_if_condition_met: true,
  is_matrix_question: false,
  allow_other: true,
  randomize_options: false
)
position += 1

# Add options for detractors
detractor_options = [
  "Precios demasiado altos",
  "Atención al cliente deficiente", 
  "Producto no cumple expectativas",
  "Proceso de compra complicado",
  "Tiempo de entrega lento"
]

detractor_options.each_with_index do |option_text, index|
  SurveyEngine::Option.create!(
    question: detractors_question,
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Add "Other" option
SurveyEngine::Option.create!(
  question: detractors_question,
  option_text: "Otro",
  option_value: "other",
  order_position: detractor_options.length + 1,
  is_other: true,
  is_exclusive: false,
  is_active: true
)

puts "Created Conditional Question for Detractors (0-6): #{detractors_question.title}"

# ========================================
# QUESTION 3: Conditional for Promoters (9-10)
# ========================================

promoters_question = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué te gusta más de nuestro servicio?",
  description: "Comparte qué aspectos valoras más",
  question_type: multiple_choice_type,
  is_required: true,
  order_position: position,
  conditional_parent: nps_question,
  conditional_operator: 'greater_than_or_equal',
  conditional_value: 9,
  show_if_condition_met: true,
  is_matrix_question: false,
  allow_other: true,
  randomize_options: false
)
position += 1

# Add options for promoters
promoter_options = [
  "Excelente calidad del producto",
  "Atención al cliente excepcional",
  "Precios competitivos",
  "Entrega rápida y confiable",
  "Fácil proceso de compra"
]

promoter_options.each_with_index do |option_text, index|
  SurveyEngine::Option.create!(
    question: promoters_question,
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Add "Other" option
SurveyEngine::Option.create!(
  question: promoters_question,
  option_text: "Otro",
  option_value: "other",
  order_position: promoter_options.length + 1,
  is_other: true,
  is_exclusive: false,
  is_active: true
)

puts "Created Conditional Question for Promoters (9-10): #{promoters_question.title}"

# ========================================
# QUESTION 4: Matrix Question - Always Shown
# ========================================

satisfaction_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Evalúa tu experiencia general",
  description: "Califica los siguientes aspectos de tu experiencia con nosotros",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create satisfaction scale options
satisfaction_labels = [
  { text: "Muy insatisfecho", value: "1" },
  { text: "Insatisfecho", value: "2" },
  { text: "Neutral", value: "3" },
  { text: "Satisfecho", value: "4" },
  { text: "Muy satisfecho", value: "5" }
]

satisfaction_labels.each_with_index do |scale, index|
  SurveyEngine::Option.create!(
    question: satisfaction_matrix,
    option_text: scale[:text],
    option_value: scale[:value],
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions
satisfaction_aspects = [
  "Calidad del producto",
  "Servicio al cliente",
  "Facilidad de uso"
]

satisfaction_aspects.each_with_index do |aspect, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: aspect,
    matrix_row_text: aspect,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: satisfaction_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question: #{satisfaction_matrix.title} (#{satisfaction_aspects.count} aspects)"

# ========================================
# QUESTION 5: Final Comments - Always Shown
# ========================================

final_comments = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Comentarios adicionales",
  description: "¿Hay algo más que te gustaría compartir con nosotros?",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Escribe tus comentarios aquí...",
  max_characters: 500,
  is_matrix_question: false,
  allow_other: false,
  randomize_options: false
)
position += 1

puts "Created Final Comments Question: #{final_comments.title}"

# ========================================
# CREATE SURVEY
# ========================================

survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Encuesta de Prueba - Flujo Condicional y Matrix",
  is_active: true,
  global: true
)

# Create participant
participant = SurveyEngine::Participant.create!(
  survey: survey,
  email: "user@survey.com",
  status: "invited"
)

puts "\n=== Conditional Test Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /survey_engine/surveys/#{survey.uuid}"
puts "Participant created for: user@survey.com"

puts "\n=== Survey Flow Logic ==="
puts "1. NPS Question (0-10) - Always shown"
puts "2. Detractors Question (Multiple Choice) - Shows if NPS ≤ 6"
puts "3. Promoters Question (Multiple Choice) - Shows if NPS ≥ 9"
puts "4. Matrix Question (Satisfaction) - Always shown"
puts "5. Final Comments (Textarea) - Always shown"

puts "\n=== Survey Structure ==="
template.questions.where(matrix_parent_id: nil).ordered.each_with_index do |question, index|
  if question.is_conditional?
    condition_text = "#{question.conditional_operator} #{question.conditional_value}"
    puts "#{index + 1}. #{question.title} (#{question.question_type.name.upcase}) - CONDITIONAL: #{condition_text}"
  elsif question.is_matrix?
    puts "#{index + 1}. #{question.title} (MATRIX - #{question.matrix_sub_questions.count} rows)"
  else
    puts "#{index + 1}. #{question.title} (#{question.question_type.name.upcase})"
  end
end

puts "\n=== Testing Instructions ==="
puts "To test conditional flow:"
puts "- Answer 0-6 on NPS → Should show detractors question"
puts "- Answer 7-8 on NPS → Should show neither conditional question"  
puts "- Answer 9-10 on NPS → Should show promoters question"
puts ""
puts "To test matrix CSS:"
puts "- Check that radio buttons are centered under column headers"
puts "- Verify text labels display properly"
puts "- Test responsive behavior"

puts "\nConditional test survey ready!"