#!/usr/bin/env ruby

# Script to create an NPS survey with 3 questions and conditional logic
# Run with: rails runner create_nps_survey.rb

puts "Creating NPS survey with conditional questions..."

# Create the survey template first
template = SurveyEngine::SurveyTemplate.create!(
  name: "Plantilla NPS",
  description: "Plantilla para encuesta Net Promoter Score con preguntas condicionales",
  is_active: true
)

puts "Created survey template: #{template.name}"

# Get question types
scale_type = SurveyEngine::QuestionType.find_by(name: 'scale')
textarea_type = SurveyEngine::QuestionType.find_by(name: 'textarea')

# Question 1: NPS Rating (0-10 scale)
question1 = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: scale_type,
  title: "¿Qué tan probable es que recomiendes nuestro producto/servicio a un amigo o colega?",
  description: "Califica en una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  is_required: true,
  order_position: 1,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable",
  allow_other: false,
  randomize_options: false
)

puts "Created Question 1: NPS Rating (0-10)"

# Question 2: Conditional for Detractors (0-6) - Why not satisfied?
question2 = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: textarea_type,
  title: "¿Qué es lo principal que no te satisface de nuestro producto/servicio?",
  description: "Por favor, comparte los aspectos que consideras que podríamos mejorar",
  is_required: true,
  order_position: 2,
  allow_other: false,
  randomize_options: false,
  max_characters: 500,
  placeholder_text: "Comparte tus comentarios aquí...",
  # Conditional logic - show for detractors (0-6)
  conditional_parent_id: question1.id,
  conditional_operator: 'less_than_or_equal',
  conditional_value: 6,
  show_if_condition_met: true
)

puts "Created Question 2: Detractor feedback (shows when NPS ≤ 6)"

# Question 3: Conditional for Promoters (9-10) - What they love most
question3 = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: textarea_type,
  title: "¿Qué es lo que más te gusta de nuestro producto/servicio?",
  description: "Nos encantaría saber qué aspectos valoras más",
  is_required: true,
  order_position: 3,
  allow_other: false,
  randomize_options: false,
  max_characters: 500,
  placeholder_text: "Cuéntanos qué es lo que más valoras...",
  # Conditional logic - show for promoters (9-10)
  conditional_parent_id: question1.id,
  conditional_operator: 'greater_than_or_equal',
  conditional_value: 9,
  show_if_condition_met: true
)

puts "Created Question 3: Promoter feedback (shows when NPS ≥ 9)"

# Create the actual survey using the template
survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Encuesta de Satisfacción NPS",
  description: "Ayúdanos a mejorar calificando tu experiencia con nuestro producto/servicio",
  is_active: true,
  global: true
)

puts "Created survey: #{survey.title} (UUID: #{survey.uuid})"

puts "\n=== NPS Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /surveys/#{survey.uuid}"
puts "Test URL: /surveys/#{survey.uuid}?email=test@example.com"

puts "\n=== Test Scenarios ==="
puts "1. Detractors (0-6): Will see Q1 + Q2 (what's not satisfying)"
puts "2. Passives (7-8): Will see only Q1 (no additional questions)"
puts "3. Promoters (9-10): Will see Q1 + Q3 (what they love most)"

puts "\n=== Question Flow ==="
puts "Q1: NPS Rating (0-10) - Always shown"
puts "Q2: Feedback for improvement - Shows when rating ≤ 6"
puts "Q3: What you love most - Shows when rating ≥ 9"