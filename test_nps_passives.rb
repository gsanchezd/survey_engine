#!/usr/bin/env ruby

# Test script for NPS Passives Range Conditional Logic
# This demonstrates the new range conditional logic feature

require_relative 'test/dummy/config/environment'

# Clean up any existing test data
SurveyEngine::Survey.where(title: "NPS Survey with Passives Range Logic").destroy_all
SurveyEngine::SurveyTemplate.where(name: "NPS Passives Test Template").destroy_all

puts "Creating NPS Survey with Passives Range Logic..."

# Create survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "NPS Passives Test Template",
  is_active: true
)

# Create survey
survey = SurveyEngine::Survey.create!(
  title: "NPS Survey with Passives Range Logic",
  survey_template: template,
  is_active: true
)

# Get question types
scale_type = SurveyEngine::QuestionType.find_by(name: "scale")
text_type = SurveyEngine::QuestionType.find_by(name: "text")

# Create NPS question (0-10 scale)
nps_question = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: scale_type,
  title: "¿Qué tan probable es que recomiendes nuestro servicio a un amigo o colega?",
  description: "0 = Nada probable, 10 = Extremadamente probable",
  order_position: 1,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)

# Create question for Detractors (0-6)
detractors_question = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: text_type,
  title: "¿Qué podríamos mejorar en nuestro servicio?",
  description: "Nos ayudaría mucho conocer qué aspectos podemos mejorar",
  order_position: 2,
  is_required: true,
  conditional_parent: nps_question,
  conditional_operator: "less_than_or_equal",
  conditional_value: 6,
  conditional_logic_type: "single"
)

# Create question for Passives (7-8) - NEW RANGE LOGIC!
passives_question = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: text_type,
  title: "¿Qué te motivaría a recomendarnos más activamente?",
  description: "Queremos saber qué haría que nos recomiendes con más entusiasmo",
  order_position: 3,
  is_required: true,
  conditional_parent: nps_question,
  conditional_logic_type: "range",
  conditional_operator: "greater_than_or_equal",
  conditional_value: 7,
  conditional_operator_2: "less_than_or_equal",
  conditional_value_2: 8
)

# Create question for Promoters (9-10)
promoters_question = SurveyEngine::Question.create!(
  survey_template: template,
  question_type: text_type,
  title: "¡Gracias por tu alta calificación! ¿Qué es lo que más valoras de nuestro servicio?",
  description: "Nos encantaría saber qué aspectos destacas más",
  order_position: 4,
  is_required: false,
  conditional_parent: nps_question,
  conditional_operator: "greater_than_or_equal",
  conditional_value: 9,
  conditional_logic_type: "single"
)

puts "✅ Survey created successfully!"
puts "📊 NPS Question: #{nps_question.title}"
puts "😞 Detractors (0-6): #{detractors_question.title}"
puts "😐 Passives (7-8): #{passives_question.title} [NEW RANGE LOGIC!]"
puts "😊 Promoters (9-10): #{promoters_question.title}"
puts ""
puts "🔗 Survey URL: /surveys/#{survey.uuid}"
puts "📋 Survey UUID: #{survey.uuid}"
puts ""
puts "🧪 Test the range conditional logic:"
puts "   - Score 0-6: Shows Detractors question"
puts "   - Score 7-8: Shows Passives question (NEW!)"
puts "   - Score 9-10: Shows Promoters question"