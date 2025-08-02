#!/usr/bin/env ruby

# Create Student Satisfaction Survey Template adapted to current implementation
# Run with: rails runner create_student_satisfaction_survey.rb

puts "Creating Student Satisfaction Survey with matrix questions..."

# Ensure we have all the question types we need
SurveyEngine::QuestionType.seed_standard_types

# Create the survey template
template = SurveyEngine::SurveyTemplate.create!(
  name: "Encuesta de Satisfacción Estudiantes (Módulo)",
  description: "Evaluación completa del módulo incluyendo docente, tutor, contenido y experiencia general",
  is_active: true
)

puts "Created Survey Template: #{template.name}"

# Get question types
matrix_scale_type = SurveyEngine::QuestionType.find_by(name: 'matrix_scale')
textarea_type = SurveyEngine::QuestionType.find_by(name: 'textarea')
scale_type = SurveyEngine::QuestionType.find_by(name: 'scale')
multiple_choice_type = SurveyEngine::QuestionType.find_by(name: 'multiple_choice')

# Question position counter
position = 1

# ========================================
# SECTION 1: EVALUACIÓN DEL DOCENTE
# ========================================

# Question 1: Matrix - Docente evaluation
docente_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué piensas del docente del módulo?",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Create matrix scale options (1-5)
(1..5).each do |i|
  SurveyEngine::Option.create!(
    question: docente_matrix,
    option_text: i.to_s,
    option_value: i.to_s,
    order_position: i,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for docente
docente_subquestions = [
  "El/la docente presentó el material de manera clara y comprensible, facilitando tu aprendizaje",
  "El/la docente demostró un sólido dominio técnico del contenido y las habilidades enseñadas en el curso",
  "El/la docente responde mis dudas, clarificando y aportando ejemplos que facilitaron el aprendizaje",
  "Recibí feedback oportuno de la prueba realizada, lo cual me permitió identificar mis avances y oportunidades de aprendizaje"
]

docente_subquestions.each_with_index do |subq_text, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: subq_text,
    matrix_row_text: subq_text,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: docente_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question: Evaluación del Docente (#{docente_subquestions.count} rows)"

# Question 2: Long text - Docente practices
SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué prácticas de tu docente consideras que te han ayudado a entender mejor los contenidos?",
  description: "Comenta",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Describe las prácticas que más te ayudaron..."
)
position += 1

# Question 3: Long text - Docente suggestions
SurveyEngine::Question.create!(
  survey_template: template,
  title: "Si tienes algún comentario o sugerencia que permita mejorar al docente en rol, comentalo a continuación:",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Comparte tus sugerencias..."
)
position += 1

# ========================================
# SECTION 2: EVALUACIÓN DEL TUTOR
# ========================================

# Question 4: Matrix - Tutor evaluation
tutor_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué piensas del tutor del módulo?",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Add options for tutor matrix (1-5)
(1..5).each do |i|
  SurveyEngine::Option.create!(
    question: tutor_matrix,
    option_text: i.to_s,
    option_value: i.to_s,
    order_position: i,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for tutor
tutor_subquestions = [
  "El/la tutor/a estuvo disponible cuando necesité ayuda",
  "El/la tutor/a me proporcionó orientación clara sobre los proyectos y tareas",
  "El/la tutor/a me ayudó a resolver dudas de manera efectiva",
  "El/la tutor/a me motivó a seguir aprendiendo y superando desafíos"
]

tutor_subquestions.each_with_index do |subq_text, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: subq_text,
    matrix_row_text: subq_text,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: tutor_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question: Evaluación del Tutor (#{tutor_subquestions.count} rows)"

# Question 5: Long text - Tutor practices
SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué prácticas de tu tutor consideras que te han ayudado a entender mejor los contenidos?",
  description: "Comenta",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Describe las prácticas que más te ayudaron..."
)
position += 1

# Question 6: Long text - Tutor suggestions
SurveyEngine::Question.create!(
  survey_template: template,
  title: "Si tienes algún comentario o sugerencia que permita mejorar al/la tutor/a en rol, comentalo a continuación:",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Comparte tus sugerencias..."
)
position += 1

# ========================================
# SECTION 3: EVALUACIÓN DEL CONTENIDO
# ========================================

# Question 7: Matrix - Content evaluation
content_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Qué piensas del contenido del módulo?",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Add options for content matrix (1-5)
(1..5).each do |i|
  SurveyEngine::Option.create!(
    question: content_matrix,
    option_text: i.to_s,
    option_value: i.to_s,
    order_position: i,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Matrix sub-questions for content
content_subquestions = [
  "Los recursos de aprendizaje disponibles me permitieron alcanzar los aprendizajes del módulo y resolver las evaluaciones de forma satisfactoria",
  "Pude resolver los desafíos del módulo a partir del material disponible",
  "Pude resolver la prueba del módulo a partir de lo ejercitado en las unidades",
  "El contenido está actualizado y es relevante para el mercado laboral actual"
]

content_subquestions.each_with_index do |subq_text, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: subq_text,
    matrix_row_text: subq_text,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: content_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question: Evaluación del Contenido (#{content_subquestions.count} rows)"

# Question 8: Long text - Content suggestions
SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Algún comentario, impresión o sugerencia que tengas respecto al contenido o recursos de aprendizaje del módulo?",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Comparte tus comentarios sobre el contenido..."
)
position += 1

# ========================================
# SECTION 4: COMUNICACIÓN CON EQUIPOS
# ========================================

# Question 9: Matrix - Communication with teams
communication_matrix = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Con los equipos a continuación, evalúo mi comunicación:",
  description: "Evalúa tu experiencia de comunicación con cada equipo: (1) Muy mala, (2) Mala, (3) Regular, (4) Buena, (5) Muy buena, (N/A) No aplica",
  question_type: matrix_scale_type,
  is_required: true,
  order_position: position,
  is_matrix_question: true,
  allow_other: false,
  randomize_options: false
)
position += 1

# Add options for communication matrix (1-5 + N/A)
(1..5).each do |i|
  SurveyEngine::Option.create!(
    question: communication_matrix,
    option_text: i.to_s,
    option_value: i.to_s,
    order_position: i,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end
SurveyEngine::Option.create!(
  question: communication_matrix,
  option_text: "N/A",
  option_value: "N/A",
  order_position: 6,
  is_other: false,
  is_exclusive: false,
  is_active: true
)

# Matrix sub-questions for communication
communication_teams = [
  "Staff ADL (Admisiones, Student Success, etc.)",
  "Equipo Docente",
  "Equipo de Tutores",
  "Mesa de Ayuda / Soporte Técnico"
]

communication_teams.each_with_index do |team, index|
  SurveyEngine::Question.create!(
    survey_template: template,
    question_type: matrix_scale_type,
    title: team,
    matrix_row_text: team,
    description: "",
    is_required: true,
    order_position: position,
    matrix_parent: communication_matrix,
    is_matrix_question: false,
    allow_other: false,
    randomize_options: false
  )
  position += 1
end

puts "Created Matrix Question: Comunicación con Equipos (#{communication_teams.count} rows)"

# Question 10: Long text - Explain communication rating
SurveyEngine::Question.create!(
  survey_template: template,
  title: "Explica la nota de la pregunta anterior",
  description: "Proporciona más detalles sobre tu experiencia de comunicación con los equipos",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Explica tu experiencia de comunicación..."
)
position += 1

# ========================================
# SECTION 5: NPS Y PREGUNTAS CONDICIONALES
# ========================================

# Question 11: NPS - Would recommend (CONDITIONAL TRIGGER)
nps_question = SurveyEngine::Question.create!(
  survey_template: template,
  title: "En base al módulo cursado, ¿Recomendarías a un amigo/colega estudiar en Desafío Latam?",
  description: "Califica en una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Muy probable'",
  question_type: scale_type,
  is_required: true,
  order_position: position,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Muy probable"
)
position += 1

puts "Created NPS Question (conditional trigger)"

# CONDITIONAL QUESTIONS START HERE

# Question 12: Multiple choice - Detractors (NPS <= 6)
q12 = SurveyEngine::Question.create!(
  survey_template: template,
  title: "Lamentamos tu mala experiencia. ¿Qué no te gustó del módulo?",
  description: "Puedes seleccionar múltiples opciones",
  question_type: multiple_choice_type,
  is_required: true,
  order_position: position,
  allow_other: true,
  randomize_options: false,
  max_selections: nil, # Allow multiple selections
  # Conditional logic for detractors
  conditional_parent: nps_question,
  conditional_operator: 'less_than_or_equal',
  conditional_value: 6,
  show_if_condition_met: true
)
position += 1

# Options for detractors question
["Contenido", "Staff ADL", "Team Docente", "Modalidad de clases"].each_with_index do |option, index|
  SurveyEngine::Option.create!(
    question: q12,
    option_text: option,
    option_value: option.parameterize.underscore,
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Other option for detractors
SurveyEngine::Option.create!(
  question: q12,
  option_text: "Otro",
  option_value: "otro",
  order_position: 5,
  is_other: true,
  is_exclusive: false,
  is_active: true
)

puts "Created Conditional Question: Detractors (NPS ≤ 6)"

# Question 13: Multiple choice - Promoters (NPS >= 9)
q13 = SurveyEngine::Question.create!(
  survey_template: template,
  title: "¡Nos alegra saber que disfrutaste tu tiempo en Desafío Latam! ¿Qué destacarías de tu experiencia?",
  description: "Puedes seleccionar múltiples opciones",
  question_type: multiple_choice_type,
  is_required: true,
  order_position: position,
  allow_other: true,
  randomize_options: false,
  max_selections: nil, # Allow multiple selections
  # Conditional logic for promoters
  conditional_parent: nps_question,
  conditional_operator: 'greater_than_or_equal',
  conditional_value: 9,
  show_if_condition_met: true
)
position += 1

# Options for promoters question
["Contenido", "Staff ADL", "Team Docente", "Modalidad de clases"].each_with_index do |option, index|
  SurveyEngine::Option.create!(
    question: q13,
    option_text: option,
    option_value: option.parameterize.underscore,
    order_position: index + 1,
    is_other: false,
    is_exclusive: false,
    is_active: true
  )
end

# Other option for promoters
SurveyEngine::Option.create!(
  question: q13,
  option_text: "Otro",
  option_value: "otro",
  order_position: 5,
  is_other: true,
  is_exclusive: false,
  is_active: true
)

puts "Created Conditional Question: Promoters (NPS ≥ 9)"

# ========================================
# SECTION 6: PREGUNTAS FINALES
# ========================================

# Question 14: Long text - More details (all paths converge here)
SurveyEngine::Question.create!(
  survey_template: template,
  title: "¿Puedes darnos más detalles?",
  description: "Amplía tu respuesta anterior con más información",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Proporciona más detalles sobre tu experiencia..."
)
position += 1

# Question 15: Long text - Final comments
SurveyEngine::Question.create!(
  survey_template: template,
  title: "Comentanos tu experiencia durante el módulo",
  description: "Cualquier comentario adicional que quieras compartir",
  question_type: textarea_type,
  is_required: false,
  order_position: position,
  placeholder_text: "Comparte tu experiencia general..."
)
position += 1

# Create the actual survey
survey = SurveyEngine::Survey.create!(
  survey_template: template,
  title: "Encuesta de Satisfacción - Módulo Estudiantil",
  description: "Tu opinión es importante para mejorar nuestros módulos educativos. Esta encuesta incluye evaluación del docente, tutor, contenido y experiencia general.",
  is_active: true,
  global: true
)

puts "\n=== Student Satisfaction Survey Created Successfully! ==="
puts "Template: #{template.name} (ID: #{template.id})"
puts "Survey: #{survey.title} (UUID: #{survey.uuid})"
puts "Survey URL: /surveys/#{survey.uuid}"
puts "Test URL: /surveys/#{survey.uuid}?email=test@example.com"

puts "\n=== Survey Structure ==="
puts "Total questions created: #{template.questions.count}"
puts "Matrix questions: #{template.questions.matrix_questions.count}"
puts "Matrix rows: #{template.questions.matrix_rows.count}"
puts "Conditional questions: #{template.questions.conditional_questions.count}"
puts "Regular questions: #{template.questions.non_matrix_questions.where(conditional_parent_id: nil).count}"

puts "\n=== Matrix Questions ==="
template.questions.matrix_questions.each do |matrix_q|
  puts "- #{matrix_q.title} (#{matrix_q.matrix_sub_questions.count} rows)"
end

puts "\n=== Conditional Logic Summary ==="
puts "- NPS ≤ 6 (Detractors): Shows 'What didn't you like?'"
puts "- NPS 7-8 (Passives): No additional questions"
puts "- NPS ≥ 9 (Promoters): Shows 'What did you enjoy?'"

puts "\n=== How It Works ==="
puts "1. 3 Matrix questions with Likert scales (Docente, Tutor, Contenido)"
puts "2. 1 Matrix question for communication evaluation"
puts "3. NPS question triggers conditional logic"
puts "4. Detractors and Promoters get follow-up questions"
puts "5. All paths converge to final open-ended questions"