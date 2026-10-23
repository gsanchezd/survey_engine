require "test_helper"

module SurveyEngine
  class GlobalSurveyResponseTest < ActionDispatch::IntegrationTest
    setup do
      # Crear usuario para autenticación
      @user = User.create!(
        email: "test@example.com",
        password: "password123"
      )
      sign_in @user

      # Crear tipos de pregunta necesarios
      @text_type = SurveyEngine::QuestionType.find_or_create_by!(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      @boolean_type = SurveyEngine::QuestionType.find_or_create_by!(name: "boolean") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      @single_choice_type = SurveyEngine::QuestionType.find_or_create_by!(name: "single_choice") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end

      # Las preguntas viven en la plantilla; la encuesta la referencia
      @survey_template = SurveyEngine::SurveyTemplate.create!(
        name: "Plantilla Satisfacción #{SecureRandom.hex(4)}",
        is_active: true
      )

      # Crear encuesta global
      @survey = SurveyEngine::Survey.create!(
        title: "Encuesta Global de Satisfacción",
        survey_template: @survey_template,
        is_active: true,
        global: true
      )

      # Crear preguntas
      @text_question = @survey_template.questions.create!(
        title: "¿Cómo describirías tu experiencia?",
        question_type: @text_type,
        is_required: true,
        order_position: 1
      )

      @boolean_question = @survey_template.questions.create!(
        title: "¿Recomendarías nuestros servicios?",
        question_type: @boolean_type,
        is_required: true,
        order_position: 2
      )

      @choice_question = @survey_template.questions.create!(
        title: "¿Cuál es tu nivel de satisfacción?",
        question_type: @single_choice_type,
        is_required: true,
        order_position: 3
      )

      # Crear opciones para pregunta de opción única
      @option_excellent = @choice_question.options.create!(
        option_text: "Excelente",
        option_value: "excellent",
        order_position: 1
      )

      @option_good = @choice_question.options.create!(
        option_text: "Bueno",
        option_value: "good",
        order_position: 2
      )

      @option_regular = @choice_question.options.create!(
        option_text: "Regular",
        option_value: "regular",
        order_position: 3
      )

      # Responder requiere invitación previa
      @participant = @survey.participants.create!(email: @user.email, status: "invited")
    end

    test "usuario puede completar encuesta global correctamente y se guarda" do
      assert_equal 0, @survey.responses.count

      # Ver la encuesta
      get survey_engine.survey_path(@survey)
      assert_response :success

      # Ir a responder la encuesta: crea la respuesta en curso
      get survey_engine.answer_survey_path(@survey)
      assert_response :success
      assert_equal 1, @survey.responses.count

      # Verificar que las preguntas se muestran
      assert_select "h3", text: /¿Cómo describirías tu experiencia?/
      assert_select "h3", text: /¿Recomendarías nuestros servicios?/
      assert_select "h3", text: /¿Cuál es tu nivel de satisfacción?/

      # Enviar respuestas completas
      post survey_engine.submit_answer_survey_path(@survey), params: {
        complete_survey: "1",
        answers: {
          @text_question.id.to_s => {
            text_answer: "La experiencia fue muy buena, el servicio cumplió mis expectativas."
          },
          @boolean_question.id.to_s => {
            boolean_answer: "1"  # Sí
          },
          @choice_question.id.to_s => {
            option_id: @option_excellent.id.to_s
          }
        }
      }

      # Debería redirigir a página de completado
      assert_redirected_to survey_engine.completed_survey_path(@survey)

      # Verificar que se guardó la respuesta
      response = @survey.responses.first
      assert response.completed_at.present?
      assert_equal @participant, response.participant

      # Verificar que el participante se marcó como completado
      @participant.reload
      assert @participant.completed?
      assert @participant.completed_at.present?

      # Verificar respuestas individuales
      assert_equal 3, response.answers.count

      text_answer = response.answers.find_by(question: @text_question)
      assert_equal "La experiencia fue muy buena, el servicio cumplió mis expectativas.", text_answer.text_answer

      boolean_answer = response.answers.find_by(question: @boolean_question)
      assert_equal true, boolean_answer.boolean_answer

      choice_answer = response.answers.find_by(question: @choice_question)
      assert_equal [ @option_excellent ], choice_answer.answer_options.map(&:option)

      # Seguir la redirección a página completada
      follow_redirect!
      assert_response :success
    end

    test "no se puede completar encuesta sin respuestas obligatorias" do
      get survey_engine.answer_survey_path(@survey)
      assert_response :success

      # Intentar completar sin respuestas
      post survey_engine.submit_answer_survey_path(@survey), params: {
        complete_survey: "1",
        answers: {}
      }

      # Debería redirigir de vuelta con error
      assert_redirected_to survey_engine.answer_survey_path(@survey)
      assert_not_nil flash[:alert]
      assert_match @text_question.title, flash[:alert]

      # No debería completarse
      assert_not @participant.reload.completed?
      assert_nil @survey.responses.first.completed_at
    end

    test "no se puede responder encuesta dos veces con mismo email" do
      get survey_engine.answer_survey_path(@survey)

      # Completar encuesta la primera vez
      post survey_engine.submit_answer_survey_path(@survey), params: {
        complete_survey: "1",
        answers: {
          @text_question.id.to_s => { text_answer: "Primera respuesta" },
          @boolean_question.id.to_s => { boolean_answer: "1" },
          @choice_question.id.to_s => { option_id: @option_good.id.to_s }
        }
      }
      assert @participant.reload.completed?

      # Intentar acceder nuevamente redirige a completado
      get survey_engine.survey_path(@survey)
      assert_redirected_to survey_engine.completed_survey_path(@survey)

      get survey_engine.answer_survey_path(@survey)
      assert_redirected_to survey_engine.completed_survey_path(@survey)

      assert_equal 1, @survey.responses.count
    end
  end
end
