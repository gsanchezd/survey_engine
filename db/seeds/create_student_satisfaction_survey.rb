# Create Student Satisfaction Survey Template from encuesta-modular.json
# Run with: rails runner db/seeds/create_student_satisfaction_survey.rb

module SurveyEngine
  puts "🎯 Creating Student Satisfaction Survey..."
  
  # Clean up any existing survey with the same name
  existing_template = SurveyTemplate.find_by(name: "Encuesta de Satisfacción Estudiantes (Módulo)")
  if existing_template
    puts "🗑️  Removing existing surveys and template..."
    # First remove surveys that use this template
    existing_template.surveys.destroy_all
    # Then remove the template
    existing_template.destroy
  end
  
  # Ensure we have the question types we need (use existing types)
  question_types = {
    'matrix_scale' => 'Matrix question with scale ratings',
    'text' => 'Short text answer',
    'textarea' => 'Long text answer',
    'scale' => 'Scale question (0-10 NPS style)',
    'multiple_choice' => 'Multiple choice question'
  }

  question_types.each do |name, description|
    qt = QuestionType.find_by(name: name)
    if qt
      puts "✓ Question type '#{name}' already exists"
    else
      puts "❌ Question type '#{name}' not found - please ensure it exists"
    end
  end

  # Create the survey template
  template = SurveyTemplate.create!(
    name: "Encuesta de Satisfacción Estudiantes (Módulo)",
    is_active: true
  )

  puts "Created Survey Template: #{template.name}"

  # Question position counter
  position = 1

  # Question 1: Matrix - Docente evaluation
  q1 = Question.create!(
    survey_template: template,
    title: "¿Qué piensas del docente del módulo?",
    description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
    question_type: QuestionType.find_by(name: 'matrix_scale'),
    is_required: true,
    order_position: position,
    is_matrix_question: true
  )
  position += 1

  # Matrix options for scale (1-5)
  scale_options = [
    { text: "Muy en desacuerdo", value: "1" },
    { text: "En desacuerdo", value: "2" },
    { text: "Ni en acuerdo ni en desacuerdo", value: "3" },
    { text: "De acuerdo", value: "4" },
    { text: "Muy de acuerdo", value: "5" }
  ]
  
  scale_options.each_with_index do |opt, idx|
    Option.create!(
      question: q1,
      option_text: opt[:text],
      option_value: opt[:value],
      order_position: idx + 1
    )
  end

  # Matrix sub-questions (rows) for docente
  docente_subquestions = [
    "El/la docente presentó el material de manera clara y comprensible, facilitando tu aprendizaje",
    "El/la docente demostró un sólido dominio técnico del contenido y las habilidades enseñadas en el curso",
    "El/la docente responde mis dudas, clarificando y aportando ejemplos que facilitaron el aprendizaje",
    "Recibí feedback oportuno de la prueba realizada, lo cual me permitió identificar mis avances y oportunidades de aprendizaje"
  ]

  docente_subquestions.each_with_index do |text, idx|
    Question.create!(
      survey_template: template,
      title: text,
      question_type: QuestionType.find_by(name: 'matrix_scale'),
      matrix_parent: q1,
      matrix_row_text: text,
      is_required: true,
      order_position: position
    )
    position += 1
  end

  # Question 2: Long text - Docente practices
  Question.create!(
    survey_template: template,
    title: "¿Qué prácticas de tu docente consideras que te han ayudado a entender mejor los contenidos?",
    description: "Comenta",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 3: Long text - Docente suggestions
  Question.create!(
    survey_template: template,
    title: "Si tienes algún comentario o sugerencia que permita mejorar al docente en rol, comentalo a continuación:",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 4: Matrix - Tutor evaluation
  q4 = Question.create!(
    survey_template: template,
    title: "¿Qué piensas del tutor del módulo?",
    description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
    question_type: QuestionType.find_by(name: 'matrix_scale'),
    is_required: true,
    order_position: position,
    is_matrix_question: true
  )
  position += 1

  # Copy scale options from docente matrix to tutor matrix
  scale_options.each_with_index do |opt, idx|
    Option.create!(
      question: q4,
      option_text: opt[:text],
      option_value: opt[:value],
      order_position: idx + 1
    )
  end

  # Matrix sub-questions (rows) for tutor
  tutor_subquestions = [
    "El/la tutor/a me orientó efectivamente en mi proceso de aprendizaje",
    "El/la tutor/a demostró conocimiento técnico sólido en las materias del curso",
    "El/la tutor/a me ayudó a resolver mis dudas de manera clara y oportuna",
    "El/la tutor/a me proporcionó feedback útil para mejorar mi desempeño"
  ]

  tutor_subquestions.each_with_index do |text, idx|
    Question.create!(
      survey_template: template,
      title: text,
      question_type: QuestionType.find_by(name: 'matrix_scale'),
      matrix_parent: q4,
      matrix_row_text: text,
      is_required: true,
      order_position: position
    )
    position += 1
  end

  # Question 5: Long text - Tutor practices
  Question.create!(
    survey_template: template,
    title: "¿Qué prácticas de tu tutor consideras que te han ayudado a entender mejor los contenidos?",
    description: "Comenta",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 6: Long text - Tutor suggestions
  Question.create!(
    survey_template: template,
    title: "Si tienes algún comentario o sugerencia que permita mejorar al/la tutor/a en rol, comentalo a continuación:",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 7: Matrix - Content evaluation
  q7 = Question.create!(
    survey_template: template,
    title: "¿Qué piensas del contenido del módulo?",
    description: "Por favor, evalúa los siguientes puntos, en la siguiente escala: (1) Muy en desacuerdo, (2) En desacuerdo, (3) Ni en acuerdo ni en desacuerdo, (4) De acuerdo, (5) Muy de acuerdo.",
    question_type: QuestionType.find_by(name: 'matrix_scale'),
    is_required: true,
    order_position: position,
    is_matrix_question: true
  )
  position += 1

  # Copy scale options to content matrix
  scale_options.each_with_index do |opt, idx|
    Option.create!(
      question: q7,
      option_text: opt[:text],
      option_value: opt[:value],
      order_position: idx + 1
    )
  end

  # Matrix sub-questions (rows) for content
  content_subquestions = [
    "El contenido del módulo fue relevante para mis objetivos de aprendizaje",
    "Los materiales proporcionados eran de alta calidad y bien organizados",
    "El nivel de dificultad del contenido fue apropiado para mi nivel",
    "Los recursos de aprendizaje me ayudaron a comprender los conceptos"
  ]

  content_subquestions.each_with_index do |text, idx|
    Question.create!(
      survey_template: template,
      title: text,
      question_type: QuestionType.find_by(name: 'matrix_scale'),
      matrix_parent: q7,
      matrix_row_text: text,
      is_required: true,
      order_position: position
    )
    position += 1
  end

  # Question 8: Long text - Content suggestions
  Question.create!(
    survey_template: template,
    title: "¿Algún comentario, impresión o sugerencia que tengas respecto al contenido o recursos de aprendizaje del módulo?",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 9: Matrix - Communication with teams
  q9 = Question.create!(
    survey_template: template,
    title: "Con los equipos a continuación, evalúo mi comunicación:",
    description: "Evalúa tu nivel de comunicación con cada equipo: (1) Muy mala, (2) Mala, (3) Regular, (4) Buena, (5) Muy buena, N/A si no aplica.",
    question_type: QuestionType.find_by(name: 'matrix_scale'),
    is_required: true,
    order_position: position,
    is_matrix_question: true
  )
  position += 1

  # Communication matrix options (1-5 + N/A)
  communication_options = [
    { text: "Muy mala", value: "1" },
    { text: "Mala", value: "2" },
    { text: "Regular", value: "3" },
    { text: "Buena", value: "4" },
    { text: "Muy buena", value: "5" },
    { text: "N/A", value: "N/A" }
  ]

  communication_options.each_with_index do |opt, idx|
    Option.create!(
      question: q9,
      option_text: opt[:text],
      option_value: opt[:value],
      order_position: idx + 1
    )
  end

  # Matrix sub-questions (rows) for communication
  communication_subquestions = [
    "Equipo de Admisiones",
    "Equipo de Student Success",
    "Equipo de Empleabilidad",
    "Equipo Técnico/IT"
  ]

  communication_subquestions.each_with_index do |text, idx|
    Question.create!(
      survey_template: template,
      title: text,
      question_type: QuestionType.find_by(name: 'matrix_scale'),
      matrix_parent: q9,
      matrix_row_text: text,
      is_required: true,
      order_position: position
    )
    position += 1
  end

  # Question 10: Long text - Explain communication rating
  Question.create!(
    survey_template: template,
    title: "Explica la nota de la pregunta anterior",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 11: NPS - Would recommend (THIS IS THE CONDITIONAL TRIGGER)
  nps_question = Question.create!(
    survey_template: template,
    title: "En base al módulo cursado, ¿Recomendarías a un amigo/colega estudiar en Desafío Latam?",
    question_type: QuestionType.find_by(name: 'scale'),
    is_required: true,
    order_position: position,
    scale_min: 0,
    scale_max: 10,
    scale_min_label: "Nada probable",
    scale_max_label: "Muy probable"
  )
  position += 1

  # CONDITIONAL QUESTIONS START HERE (Using our improved range logic)

  # Question 12: Detractors (NPS 0-6)
  q12 = Question.create!(
    survey_template: template,
    title: "Lamentamos tu mala experiencia. ¿Qué no te gustó del módulo?",
    question_type: QuestionType.find_by(name: 'multiple_choice'),
    is_required: true,
    order_position: position,
    allow_other: true,
    max_selections: nil, # Allow multiple selections
    conditional_parent: nps_question,
    conditional_operator: 'less_than_or_equal',
    conditional_value: 6,
    conditional_logic_type: 'single',
    show_if_condition_met: true
  )
  position += 1

  # Options for detractors question
  detractor_options = ["Contenido", "Staff ADL", "Team Docente", "Modalidad de clases"]
  detractor_options.each_with_index do |option_text, idx|
    Option.create!(
      question: q12,
      option_text: option_text,
      option_value: option_text,
      order_position: idx + 1
    )
  end

  # Question 13: Passives (NPS 7-8) - Using RANGE logic!
  q13 = Question.create!(
    survey_template: template,
    title: "¿Qué podríamos mejorar para aumentar la nota?",
    question_type: QuestionType.find_by(name: 'multiple_choice'),
    is_required: true,
    order_position: position,
    allow_other: true,
    max_selections: nil, # Allow multiple selections
    conditional_parent: nps_question,
    conditional_logic_type: 'range',
    conditional_operator: 'greater_than_or_equal',
    conditional_value: 7,
    conditional_operator_2: 'less_than_or_equal',
    conditional_value_2: 8,
    show_if_condition_met: true
  )
  position += 1

  # Options for passives question
  passive_options = ["Contenido", "Staff ADL", "Team Docente", "Modalidad de clases"]
  passive_options.each_with_index do |option_text, idx|
    Option.create!(
      question: q13,
      option_text: option_text,
      option_value: option_text,
      order_position: idx + 1
    )
  end

  # Question 14: Promoters (NPS 9-10)
  q14 = Question.create!(
    survey_template: template,
    title: "¡Nos alegra saber que disfrutaste tu tiempo en Desafío Latam! ¿Qué destacarías de tu experiencia?",
    question_type: QuestionType.find_by(name: 'multiple_choice'),
    is_required: true,
    order_position: position,
    allow_other: true,
    max_selections: nil, # Allow multiple selections
    conditional_parent: nps_question,
    conditional_operator: 'greater_than_or_equal',
    conditional_value: 9,
    conditional_logic_type: 'single',
    show_if_condition_met: true
  )
  position += 1

  # Options for promoters question
  promoter_options = ["Contenido", "Staff ADL", "Team Docente", "Modalidad de clases"]
  promoter_options.each_with_index do |option_text, idx|
    Option.create!(
      question: q14,
      option_text: option_text,
      option_value: option_text,
      order_position: idx + 1
    )
  end

  # Question 15: Long text - More details (all paths converge here)
  Question.create!(
    survey_template: template,
    title: "¿Puedes darnos más detalles?",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  # Question 16: Long text - Final comments
  Question.create!(
    survey_template: template,
    title: "Comentanos tu experiencia durante el módulo",
    question_type: QuestionType.find_by(name: 'textarea'),
    is_required: false,
    order_position: position
  )
  position += 1

  puts "✅ Survey template created successfully!"
  puts "📊 Total questions created: #{template.questions.count}"
  puts "🔀 Conditional questions: #{template.questions.where.not(conditional_parent_id: nil).count}"
  
  # Create a survey instance from the template
  survey = Survey.create!(
    title: "Encuesta de Satisfacción - Módulo Demo",
    survey_template: template,
    is_active: true
  )
  
  puts "📋 Survey created: #{survey.title}"
  puts "🆔 Survey UUID: #{survey.uuid}"
  
  # Add invitation for demo user
  demo_user_email = "user@survey.com"
  
  participant = Participant.create!(
    survey: survey,
    email: demo_user_email,
    status: 'invited'
  )
  
  puts "👤 Demo user invitation created for: #{demo_user_email}"
  puts "🔗 Survey URL: /surveys/#{survey.uuid}?email=#{CGI.escape(demo_user_email)}"
  
  # Display conditional logic summary
  puts "\n🎯 Conditional Logic Summary:"
  puts "   - NPS 0-6: Shows 'What didn't you like?' (Detractors)"
  puts "   - NPS 7-8: Shows 'What could we improve?' (Passives) [RANGE LOGIC!]"
  puts "   - NPS 9-10: Shows 'What did you enjoy?' (Promoters)"
  puts "\n✨ Student Satisfaction Survey is ready to test!"
end