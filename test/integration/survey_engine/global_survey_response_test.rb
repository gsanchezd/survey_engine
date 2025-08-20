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
      @text_type = SurveyEngine::QuestionType.find_or_create_by!(
        name: "text",
        allows_options: false,
        allows_multiple_selections: false
      )
      
      @boolean_type = SurveyEngine::QuestionType.find_or_create_by!(
        name: "boolean",
        allows_options: false,
        allows_multiple_selections: false
      )
      
      @single_choice_type = SurveyEngine::QuestionType.find_or_create_by!(
        name: "single_choice",
        allows_options: true,
        allows_multiple_selections: false
      )
      
      # Crear encuesta global
      @survey = SurveyEngine::Survey.create!(
        title: "Encuesta Global de Satisfacción",
        description: "Encuesta para evaluar la satisfacción general",
        status: "published",
        is_active: true,
        global: true
      )
      
      # Crear preguntas
      @text_question = @survey.questions.create!(
        title: "¿Cómo describirías tu experiencia?",
        question_type: @text_type,
        is_required: true,
        order_position: 1
      )
      
      @boolean_question = @survey.questions.create!(
        title: "¿Recomendarías nuestros servicios?",
        question_type: @boolean_type,
        is_required: true,
        order_position: 2
      )
      
      @choice_question = @survey.questions.create!(
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
    end

    test "usuario puede completar encuesta global correctamente y se guarda" do
      # Verificar que no hay participante inicialmente
      assert_equal 0, @survey.participants.count
      assert_equal 0, @survey.responses.count
      
      # Ir a la página de la encuesta
      get survey_engine.survey_path(@survey, email: @user.email)
      assert_response :success
      
      # Debería crear un participante
      assert_equal 1, @survey.participants.count
      participant = @survey.participants.first
      assert_equal @user.email, participant.email
      assert_equal "invited", participant.status
      
      # Ir a responder la encuesta
      get survey_engine.answer_survey_path(@survey, email: @user.email)
      assert_response :success
      
      # Verificar que las preguntas se muestran
      assert_select "h3", text: /¿Cómo describirías tu experiencia?/
      assert_select "h3", text: /¿Recomendarías nuestros servicios?/
      assert_select "h3", text: /¿Cuál es tu nivel de satisfacción?/
      
      # Enviar respuestas completas
      post survey_engine.submit_survey_path(@survey), params: {
        email: @user.email,
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
      assert_redirected_to survey_engine.completed_survey_path(@survey, email: @user.email)
      
      # Verificar que se guardó la respuesta
      assert_equal 1, @survey.responses.count
      response = @survey.responses.first
      assert response.completed_at.present?
      assert_equal participant, response.participant
      
      # Verificar que el participante se marcó como completado
      participant.reload
      assert_equal "completed", participant.status
      assert participant.completed_at.present?
      
      # Verificar respuestas individuales
      assert_equal 3, response.answers.count
      
      # Verificar respuesta de texto
      text_answer = response.answers.joins(:question).find_by(questions: { id: @text_question.id })
      assert_not_nil text_answer
      assert_equal "La experiencia fue muy buena, el servicio cumplió mis expectativas.", text_answer.text_answer
      
      # Verificar respuesta booleana
      boolean_answer = response.answers.joins(:question).find_by(questions: { id: @boolean_question.id })
      assert_not_nil boolean_answer
      assert_equal true, boolean_answer.boolean_answer
      
      # Verificar respuesta de opción única
      choice_answer = response.answers.joins(:question).find_by(questions: { id: @choice_question.id })
      assert_not_nil choice_answer
      assert_equal 1, choice_answer.answer_options.count
      assert_equal @option_excellent, choice_answer.answer_options.first.option
      
      # Seguir la redirección a página completada
      follow_redirect!
      assert_response :success
      assert_select "h2", text: /Encuesta Completada/
    end

    test "no se puede completar encuesta sin respuestas obligatorias" do
      # Ir a responder la encuesta
      get survey_engine.answer_survey_path(@survey, email: @user.email)
      assert_response :success
      
      # Intentar enviar sin respuestas
      post survey_engine.submit_survey_path(@survey), params: {
        email: @user.email,
        answers: {}
      }
      
      # No debería crear respuesta
      assert_equal 0, @survey.responses.count
      
      # Debería redirigir de vuelta con error
      assert_redirected_to survey_engine.answer_survey_path(@survey, email: @user.email)
      
      # Verificar mensaje de error en flash
      follow_redirect!
      assert_not_nil flash[:alert]
      assert_match /preguntas obligatorias/, flash[:alert]
    end

    test "no se puede responder encuesta dos veces con mismo email" do
      # Completar encuesta la primera vez
      post survey_engine.submit_survey_path(@survey), params: {
        email: @user.email,
        answers: {
          @text_question.id.to_s => { text_answer: "Primera respuesta" },
          @boolean_question.id.to_s => { boolean_answer: "1" },
          @choice_question.id.to_s => { option_id: @option_good.id.to_s }
        }
      }
      
      assert_equal 1, @survey.responses.count
      
      # Intentar acceder nuevamente
      get survey_engine.survey_path(@survey, email: @user.email)
      
      # Debería redirigir a página de ya completada
      assert_redirected_to survey_engine.completed_survey_path(@survey, email: @user.email)
      
      # Verificar que sigue habiendo solo una respuesta
      assert_equal 1, @survey.responses.count
    end
  end
end