# Encuesta Global Desafío Latam - Survey Engine Implementation
# This file creates a comprehensive satisfaction survey using all available question types
# from the SurveyEngine gem, based on the original TypeForm survey structure.

puts "🎯 Starting Global Satisfaction Survey creation..."

ActiveRecord::Base.transaction do
  puts "📦 Starting database transaction..."

  # Create the survey template
  survey_template = SurveyEngine::SurveyTemplate.find_or_create_by(name: "Encuesta Satisfacción Global") do |template|
    # template.description = "Queremos conocer tu opinión tras la finalización de tu Programa Académico en la Academia Desafío Latam y si requieres apoyo en búsqueda de nuevas oportunidades laborales"
  end

  puts "📋 Creating survey template: #{survey_template.name}"

  # Get question types
  nps_type = SurveyEngine::QuestionType.find_by(name: "scale")
  single_choice_type = SurveyEngine::QuestionType.find_by(name: "single_choice")
  multiple_choice_type = SurveyEngine::QuestionType.find_by(name: "multiple_choice")
  matrix_type = SurveyEngine::QuestionType.find_by(name: "matrix_scale")
  textarea_type = SurveyEngine::QuestionType.find_by(name: "textarea")
  text_type = SurveyEngine::QuestionType.find_by(name: "text")
  boolean_type = SurveyEngine::QuestionType.find_by(name: "boolean")
  ranking_type = SurveyEngine::QuestionType.find_by(name: "ranking")

  # Clear existing questions to avoid duplicates
  survey_template.questions.destroy_all

  order_position = 1

# Question 1: NPS Question (Scale type)
q1 = survey_template.questions.create!(
  title: "¿Recomendarías a un amigo o colega estudiar el programa que cursaste?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  question_type: nps_type,
  order_position: order_position,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)
puts "✅ Created Q#{order_position}: NPS Question - #{q1.title}"
order_position += 1

# Question 2: Multiple Choice with Other Option
q2 = survey_template.questions.create!(
  title: "¿Qué otra carrera te gustaría cursar en Desafío Latam?",
  description: "Actualmente contamos con las siguientes carreras. Si tienes en mente una carrera o curso que no está en nuestra oferta y crees que deberíamos incluir, por favor selecciona 'Otros' y escribe el nombre del programa",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true,
  allow_other: true
)

# Add options for question 2
careers = [
  "Desarrollo Full Stack JavaScript",
  "Desarrollo Front End",
  "Data Science",
  "Diseño UX/UI",
  "Data Analytics",
  "Ciberseguridad",
  "No estoy interesado en cursar otra carrera"
]

careers.each_with_index do |career, index|
  q2.options.create!(
    option_text: career,
    option_value: career,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Multiple Choice - #{q2.title}"
order_position += 1

# Question 3: Matrix Question - Community Evaluation
q3 = survey_template.questions.create!(
  title: "¡Evalúa nuestra comunidad!",
  description: "Por favor, evalúa los siguientes puntos en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_type,
  order_position: order_position,
  is_required: true,
  is_matrix_question: true,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Muy en desacuerdo",
  scale_max_label: "Muy de acuerdo"
)

# Add options for matrix question
scale_options = [
  "Muy en desacuerdo",
  "En desacuerdo", 
  "Ni en acuerdo ni en desacuerdo",
  "De acuerdo",
  "Muy de acuerdo"
]

scale_options.each_with_index do |option_text, index|
  q3.options.create!(
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1
  )
end

# Matrix sub-questions
community_questions = [
  "Siento que he aprovechado y obtenido beneficios de los talleres online y cursos gratuitos ofrecidos por Desafío Latam para complementar mi carrera",
  "Considero que el programa académico cursado ha sido beneficioso para mi crecimiento profesional",
  "Me siento parte de la comunidad de Desafío Latam"
]

community_questions.each_with_index do |matrix_question, index|
  survey_template.questions.create!(
    title: matrix_question,
    question_type: matrix_type,
    order_position: order_position + (index + 1) * 0.1,
    is_required: true,
    matrix_parent_id: q3.id,
    matrix_row_text: matrix_question,
    is_matrix_question: false,
    scale_min: 1,
    scale_max: 5
  )
end
puts "✅ Created Q#{order_position}: Matrix Question - #{q3.title}"
order_position += 1

# Question 4: NPS Question - Admissions Team
q4 = survey_template.questions.create!(
  title: "¿Qué tan probable es que recomiendes el equipo de consejeros de admisión por haber entregado toda la información necesaria sobre el programa, incluyendo contenidos, modalidad y servicio de empleabilidad?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  question_type: nps_type,
  order_position: order_position,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)
puts "✅ Created Q#{order_position}: NPS Question - #{q4.title}"
order_position += 1

# Question 5: Matrix Question - Academic Program
q5 = survey_template.questions.create!(
  title: "¡Evalúa nuestro Programa Académico!",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_type,
  order_position: order_position,
  is_required: true,
  is_matrix_question: true,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Muy en desacuerdo",
  scale_max_label: "Muy de acuerdo"
)

# Add options for q5 matrix question
scale_options.each_with_index do |option_text, index|
  q5.options.create!(
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1
  )
end

academic_questions = [
  "La metodología utilizada en el programa cursado favorece el aprendizaje",
  "El programa posee un apropiado equilibrio entre el contenido teórico y práctico"
]

academic_questions.each_with_index do |matrix_question, index|
  survey_template.questions.create!(
    title: matrix_question,
    question_type: matrix_type,
    order_position: order_position + (index + 1) * 0.1,
    is_required: true,
    matrix_parent_id: q5.id,
    matrix_row_text: matrix_question,
    is_matrix_question: false,
    scale_min: 1,
    scale_max: 5
  )
end
puts "✅ Created Q#{order_position}: Matrix Question - #{q5.title}"
order_position += 1

# Question 6: Long Text (Textarea)
q6 = survey_template.questions.create!(
  title: "¿En qué aspectos consideras que la plataforma Empieza podría mejorar para ajustarse mejor a tus necesidades?",
  question_type: textarea_type,
  order_position: order_position,
  is_required: true
)
puts "✅ Created Q#{order_position}: Textarea Question - #{q6.title}"
order_position += 1

# Question 7: Multiple Choice with Multiple Selections
q7 = survey_template.questions.create!(
  title: "El complemento al programa que facilitaría el proceso de aprendizaje es:",
  description: "Selecciona la opción que mejor describa el complemento que crees que facilitaría el proceso de aprendizaje. Si seleccionas \"Otros\", por favor deja tus comentarios en el campo para que podamos entender mejor tus necesidades y sugerencias",
  question_type: multiple_choice_type,
  order_position: order_position,
  is_required: true,
  allow_other: true
)

complements = [
  "Prueba de diagnóstico",
  "Taller de nivelación",
  "Ampliar módulos críticos",
  "Sesiones de tutoría grupal",
  "Sesiones de ayudantía obligatorias"
]

complements.each_with_index do |complement, index|
  q7.options.create!(
    option_text: complement,
    option_value: complement,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Multiple Choice (Multiple Selections) - #{q7.title}"
order_position += 1

# Question 8: NPS Question - General Recommendation with Conditional Logic
q8 = survey_template.questions.create!(
  title: "¿Recomendarías a un amigo o colega estudiar en Desafío Latam?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  question_type: nps_type,
  order_position: order_position,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)
puts "✅ Created Q#{order_position}: NPS Question (Main) - #{q8.title}"
order_position += 1

# Question 9: Single Choice - Negative Feedback (conditional on Q8 < 7)
q9 = survey_template.questions.create!(
  title: "Lamentamos que tu experiencia no haya sido satisfactoria ¿Qué no te gustó de Desafío Latam?",
  description: "Selecciona de la lista a continuación las razones por las que no estuviste satisfecho. Si tu razón no está en la lista, selecciona 'Otro' y deja un comentario específico para que podamos mejorar",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true,
  allow_other: true,
  conditional_parent: q8,
  conditional_operator: "less_than",
  conditional_value: 7.0
)

negative_aspects = [
  "Contenido",
  "Staff ADL",
  "Team Docente",
  "Modalidad de clases"
]

negative_aspects.each_with_index do |aspect, index|
  q9.options.create!(
    option_text: aspect,
    option_value: aspect,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Conditional Single Choice (Negative) - #{q9.title}"
order_position += 1

# Question 10: Single Choice - Neutral Feedback (conditional on Q8 7-8)
q10 = survey_template.questions.create!(
  title: "¿Qué cambios crees que podríamos hacer para mejorar tu experiencia y aumentar tu calificación?",
  description: "Selecciona de la lista a continuación los cambios que crees que podrían mejorar tu experiencia. Si tienes una sugerencia que no está en la lista, selecciona 'Otro' y déjanos tu comentario específico",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true,
  allow_other: true,
  conditional_parent: q8,
  conditional_operator: "greater_than_or_equal",
  conditional_value: 7.0,
  conditional_operator_2: "less_than_or_equal",
  conditional_value_2: 8.0,
  conditional_logic_type: "range"
)

improvement_aspects = [
  "Contenido",
  "Staff ADL",
  "Team Docente",
  "Modalidad de clases"
]

improvement_aspects.each_with_index do |aspect, index|
  q10.options.create!(
    option_text: aspect,
    option_value: aspect,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Conditional Single Choice (Neutral) - #{q10.title}"
order_position += 1

# Question 11: Single Choice - Positive Feedback (conditional on Q8 >= 9)
q11 = survey_template.questions.create!(
  title: "¡Nos alegra saber que disfrutaste tu tiempo en Desafío Latam! ¿Qué aspectos de tu experiencia destacarías como los más positivos?",
  description: "Selecciona de la lista a continuación los aspectos de tu experiencia que te resultaron más satisfactorios. Si tienes otro comentario positivo que no está en la lista, selecciona 'Otro' y compártelo con nosotros",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true,
  allow_other: true,
  conditional_parent: q8,
  conditional_operator: "greater_than_or_equal",
  conditional_value: 9.0
)

positive_aspects = [
  "Contenido",
  "Staff ADL",
  "Team Docente",
  "Modalidad de clases"
]

positive_aspects.each_with_index do |aspect, index|
  q11.options.create!(
    option_text: aspect,
    option_value: aspect,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Conditional Single Choice (Positive) - #{q11.title}"
order_position += 1

# Question 12: Matrix Question - Experience Evaluation
q12 = survey_template.questions.create!(
  title: "¡Evalúa tu experiencia en Desafío Latam!",
  description: "Por favor, evalúa los siguientes puntos en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_type,
  order_position: order_position,
  is_required: true,
  is_matrix_question: true,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Muy en desacuerdo",
  scale_max_label: "Muy de acuerdo"
)

# Add options for q12 matrix question
scale_options.each_with_index do |option_text, index|
  q12.options.create!(
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1
  )
end

experience_questions = [
  "Mi Coordinador/a de Experiencia Académica pudo resolver mis solicitudes y la de mi generación de manera oportuna",
  "Recibí a tiempo los accesos a las diferentes plataformas de aprendizaje (Empieza, Slack, Zoom)",
  "El equipo de Ayuda de Desafío Latam (Servicio al Cliente y Comité Evaluador) pudo resolver mis reintegros u otras solicitudes académicas de manera oportuna",
  "Las respuestas de las encuestas modulares que entregué provocaron un cambio positivo durante mi carrera"
]

experience_questions.each_with_index do |matrix_question, index|
  survey_template.questions.create!(
    title: matrix_question,
    question_type: matrix_type,
    order_position: order_position + (index + 1) * 0.1,
    is_required: true,
    matrix_parent_id: q12.id,
    matrix_row_text: matrix_question,
    is_matrix_question: false,
    scale_min: 1,
    scale_max: 5
  )
end
puts "✅ Created Q#{order_position}: Matrix Question - #{q12.title}"
order_position += 1

# Question 13: NPS Question - Student Support Team
q13 = survey_template.questions.create!(
  title: "¿Recomendarías el servicio del Equipo de Apoyo al estudiante a un colega o amigo?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  question_type: nps_type,
  order_position: order_position,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)
puts "✅ Created Q#{order_position}: NPS Question - #{q13.title}"
order_position += 1

# Question 14: Matrix Question - Finance Team
q14 = survey_template.questions.create!(
  title: "¡Evalúa al Equipo Finanzas!",
  description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
  question_type: matrix_type,
  order_position: order_position,
  is_required: true,
  is_matrix_question: true,
  scale_min: 1,
  scale_max: 5,
  scale_min_label: "Muy en desacuerdo",
  scale_max_label: "Muy de acuerdo"
)

# Add options for q14 matrix question
scale_options.each_with_index do |option_text, index|
  q14.options.create!(
    option_text: option_text,
    option_value: (index + 1).to_s,
    order_position: index + 1
  )
end

finance_questions = [
  "Los sistemas de información y herramientas de gestión utilizados para firmas de contratos son eficientes y funcionan adecuadamente",
  "Los sistemas de información y herramientas de gestión utilizados para pagos son eficientes y funcionan adecuadamente"
]

finance_questions.each_with_index do |matrix_question, index|
  survey_template.questions.create!(
    title: matrix_question,
    question_type: matrix_type,
    order_position: order_position + (index + 1) * 0.1,
    is_required: true,
    matrix_parent_id: q14.id,
    matrix_row_text: matrix_question,
    is_matrix_question: false,
    scale_min: 1,
    scale_max: 5
  )
end
puts "✅ Created Q#{order_position}: Matrix Question - #{q14.title}"
order_position += 1

# Question 15: NPS Question - Finance Team
q15 = survey_template.questions.create!(
  title: "¿Recomendarías la atención, conocimiento y proceso de gestión del Equipo de Finanzas a un colega o amigo?",
  description: "En una escala del 0 al 10, donde 0 es 'Nada probable' y 10 es 'Extremadamente probable'",
  question_type: nps_type,
  order_position: order_position,
  is_required: true,
  scale_min: 0,
  scale_max: 10,
  scale_min_label: "Nada probable",
  scale_max_label: "Extremadamente probable"
)
puts "✅ Created Q#{order_position}: NPS Question - #{q15.title}"
order_position += 1

# Question 16: Ranking Question
q16 = survey_template.questions.create!(
  title: "¿Cuál medio de comunicación consideras que es más efectivo?",
  description: "Por favor, ordena del más al menos efectivo.",
  question_type: ranking_type,
  order_position: order_position,
  is_required: true
)

communication_methods = [
  "Correo",
  "Empieza",
  "Whatsapp",
  "Slack generación",
  "Slack#dudas-y-consultas"
]

communication_methods.each_with_index do |method, index|
  q16.options.create!(
    option_text: method,
    option_value: method,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Ranking Question - #{q16.title}"
order_position += 1

# Question 17: Short Text
q17 = survey_template.questions.create!(
  title: "Indícanos tu link de LinkedIn",
  question_type: text_type,
  order_position: order_position,
  is_required: true
)
puts "✅ Created Q#{order_position}: Text Question - #{q17.title}"
order_position += 1

# Question 18: Single Choice - Employment Status Before
q18 = survey_template.questions.create!(
  title: "¿Cuál era tu situación laboral al momento de empezar a estudiar en Desafío Latam?",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true
)

employment_before = [
  "Empleado/a",
  "Desempleado/a",
  "Emprendedor/a"
]

employment_before.each_with_index do |status, index|
  q18.options.create!(
    option_text: status,
    option_value: status,
    order_position: index + 1
  )
end
puts "✅ Created Q#{order_position}: Single Choice - #{q18.title}"
order_position += 1

# Question 19: Single Choice - Current Employment Status (with conditional logic)
q19 = survey_template.questions.create!(
  title: "¿Cuál es tu situación laboral actual?",
  question_type: single_choice_type,
  order_position: order_position,
  is_required: true
)

employment_current = [
  "Empleado/a",
  "Desempleado/a",
  "Emprendedor/a",
  "Freelance"
]

current_options = []
employment_current.each_with_index do |status, index|
  option = q19.options.create!(
    option_text: status,
    option_value: status,
    order_position: index + 1
  )
  current_options << option
end
puts "✅ Created Q#{order_position}: Single Choice - #{q19.title}"
order_position += 1

# Question 20: Company Name (optional for all)
q20 = survey_template.questions.create!(
  title: "Nombre de la empresa donde trabajas (opcional)",
  question_type: text_type,
  order_position: order_position,
  is_required: false
)
puts "✅ Created Q#{order_position}: Text Question - #{q20.title}"
order_position += 1

# Question 21: Job Title (optional for all)
q21 = survey_template.questions.create!(
  title: "¿Cuál es el nombre de tu cargo? (opcional)",
  question_type: text_type,
  order_position: order_position,
  is_required: false
)
puts "✅ Created Q#{order_position}: Text Question - #{q21.title}"
order_position += 1

# Question 22: Job/Business Relation to Studies (for all)
q22 = survey_template.questions.create!(
  title: "¿Tu trabajo/emprendimiento se relaciona con lo que estudiaste en Desafío Latam?",
  description: "Cargo, Funciones, y/o su industria",
  question_type: boolean_type,
  order_position: order_position,
  is_required: true
)
puts "✅ Created Q#{order_position}: Boolean Question - #{q22.title}"
order_position += 1

# Question 23: Business Name (optional for all)
q23 = survey_template.questions.create!(
  title: "¿Cómo se llama tu emprendimiento o empresa? (opcional)",
  question_type: text_type,
  order_position: order_position,
  is_required: false
)
puts "✅ Created Q#{order_position}: Text Question - #{q23.title}"
order_position += 1

# Removed Q24 as it's now covered by Q22
order_position += 1

# Question 25: Need Job Support
q25 = survey_template.questions.create!(
  title: "¿Necesitas apoyo de parte de ADL para buscar nuevas oportunidades laborales?",
  question_type: boolean_type,
  order_position: order_position,
  is_required: true
)
puts "✅ Created Q#{order_position}: Boolean Question - #{q25.title}"
order_position += 1

# Question 26: Authorization for Data Usage
q26 = survey_template.questions.create!(
  title: "Autorizo a Desafío Latam a compartir el contenido total o parcial de mis respuestas de esta encuesta con fines publicitarios y comerciales para mejorar los servicios y la experiencia educativa, protegiendo mi privacidad y confidencialidad.",
  question_type: boolean_type,
  order_position: order_position,
  is_required: true
)
puts "✅ Created Q#{order_position}: Boolean Question - #{q26.title}"

puts "\n🎉 Survey template creation completed!"
puts "📊 Total questions created: #{survey_template.questions.count}"
puts "🔄 Matrix sub-questions included"
puts "🎯 Conditional logic implemented"
puts "📝 All question types utilized:"
puts "   • Scale (NPS): #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'scale' }).count}"
puts "   • Single Choice: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'single_choice' }).count}"
puts "   • Multiple Choice: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'multiple_choice' }).count}"
puts "   • Matrix Scale: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'matrix_scale' }).count}"
puts "   • Textarea: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'textarea' }).count}"
puts "   • Text: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'text' }).count}"
puts "   • Boolean: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'boolean' }).count}"
puts "   • Ranking: #{survey_template.questions.joins(:question_type).where(survey_engine_question_types: { name: 'ranking' }).count}"

  puts "\n🚀 To create a survey from this template:"
  puts "survey = SurveyEngine::Survey.create!("
  puts "  title: 'Encuesta Satisfacción Global - #{Date.current.strftime('%B %Y')}',"
  puts "  survey_template: SurveyEngine::SurveyTemplate.find_by(name: 'Encuesta Satisfacción Global')"
  puts ")"

  puts "\n✅ Transaction completed successfully!"

rescue => e
  puts "\n❌ Error creating survey template: #{e.message}"
  puts "❌ Transaction will be rolled back"
  puts "Stack trace:"
  puts e.backtrace.first(10)
  raise e
end

puts "\n🎉 Global Satisfaction Survey setup completed!"
