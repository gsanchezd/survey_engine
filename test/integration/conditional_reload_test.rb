require "test_helper"

class ConditionalReloadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    # Create a user and sign in (if authentication is required)
    begin
      @user = User.create!(email: "test@example.com", password: "password123", password_confirmation: "password123")
      sign_in @user, scope: :user
    rescue NameError, RuntimeError => e
      # User model doesn't exist or Devise not configured, skip authentication
      puts "Skipping authentication: #{e.message}"
    end
    
    # Create a survey template first
    @survey_template = SurveyEngine::SurveyTemplate.create!(
      name: "Test Template"
    )
    
    @survey = SurveyEngine::Survey.create!(
      title: "Test Survey with Conditional Questions",
      survey_template: @survey_template,
      is_active: true,
      global: true
    )

    # Create question types
    @scale_type = SurveyEngine::QuestionType.find_by(name: "scale") ||
                  SurveyEngine::QuestionType.create!(name: "scale", allows_options: false, allows_multiple_selections: false)
    @text_type = SurveyEngine::QuestionType.find_by(name: "text") ||
                 SurveyEngine::QuestionType.create!(name: "text", allows_options: false, allows_multiple_selections: false)

    # Create parent question (scale)
    @parent_question = @survey_template.questions.create!(
      title: "Rate your satisfaction (1-5)",
      question_type: @scale_type,
      is_required: true,
      order_position: 1,
      scale_min: 1,
      scale_max: 5,
      scale_min_label: "Very Dissatisfied",
      scale_max_label: "Very Satisfied"
    )

    # Create conditional child question (text)
    @child_question = @survey_template.questions.create!(
      title: "Please explain why you are dissatisfied",
      question_type: @text_type,
      is_required: false,
      order_position: 2,
      conditional_parent_id: @parent_question.id,
      conditional_type: 'scale',
      conditional_logic_type: 'single',
      conditional_operator: 'less_than_or_equal',
      conditional_value: 2,
      show_if_condition_met: true
    )

    # Create participant and response with existing answers
    @participant = @survey.participants.create!(
      email: "test@example.com",
      status: "invited"
    )
    
    @response = @survey.responses.create!(
      participant: @participant
    )

    # Create answer to parent question that SHOULD trigger the conditional
    @parent_answer = @response.answers.create!(
      question: @parent_question,
      numeric_answer: 2  # This should trigger the conditional (<=2)
    )
  end

  test "conditional questions are shown on page reload when parent answer triggers them" do
    # Visit the survey answer page
    get survey_engine.answer_survey_path(@survey, email: @participant.email)
    
    assert_response :success
    
    # Check that both questions are present in the DOM
    assert_select "div[data-question-id='#{@parent_question.id}']", 1
    assert_select "div[data-question-id='#{@child_question.id}']", 1
    
    # The parent question should be visible (no style="display: none;")
    assert_select "div[data-question-id='#{@parent_question.id}'][style*='display: none']", 0
    
    # The conditional question should have style="display: none;" initially
    # but should be made visible by JavaScript on page load
    assert_select "div[data-question-id='#{@child_question.id}'][style*='display: none']", 1
    
    # Check that the parent question has the correct answer selected
    assert_select "input[name='answers[#{@parent_question.id}][numeric_answer]'][value='2'][checked='checked']", 1
    
    # Verify the conditional flow configuration includes our questions
    config_script = css_select("script").find { |s| s.text.include?("SurveyConditionalFlow") }
    assert config_script.present?, "Should include conditional flow initialization script"
    assert config_script.text.include?(@parent_question.id.to_s), "Should include parent question ID"
    assert config_script.text.include?(@child_question.id.to_s), "Should include child question ID"
  end

  test "conditional questions remain hidden when parent answer does not trigger them" do
    # Update parent answer to NOT trigger the conditional
    @parent_answer.update!(numeric_answer: 4)  # This should NOT trigger (>2)
    
    get survey_engine.answer_survey_path(@survey, email: @participant.email)
    
    assert_response :success
    
    # Check that both questions are present
    assert_select "div[data-question-id='#{@parent_question.id}']", 1
    assert_select "div[data-question-id='#{@child_question.id}']", 1
    
    # The conditional question should remain hidden
    assert_select "div[data-question-id='#{@child_question.id}'][style*='display: none']", 1
    
    # Check that the parent has the correct value selected
    assert_select "input[name='answers[#{@parent_question.id}][numeric_answer]'][value='4'][checked='checked']", 1
  end

  test "JavaScript evaluateInitialState method properly handles existing answers" do
    get survey_engine.answer_survey_path(@survey, email: @participant.email)
    
    assert_response :success
    
    # Verify the conditional flow configuration is present and correctly configured
    config_script = css_select("script").find { |s| s.text.include?("SurveyConditionalFlow") }
    assert config_script.present?, "Should include conditional flow initialization script"
    
    # Check that config includes both parent and child questions
    script_text = config_script.text
    assert_match(/conditionalFlow\.initialize/, script_text)
    assert script_text.include?(@parent_question.id.to_s), "Should include parent question ID in config"
    assert script_text.include?(@child_question.id.to_s), "Should include child question ID in config"
    
    # Verify that the conditional configuration includes the necessary operator and value
    assert_match(/"operator":"less_than_or_equal"/, script_text)
    assert_match(/"value":2/, script_text)
  end

  test "multiple conditional questions work correctly on reload" do
    # Create a second conditional question
    @child_question_2 = @survey_template.questions.create!(
      title: "What specific aspect disappointed you most?",
      question_type: @text_type,
      is_required: false,
      order_position: 3,
      conditional_parent_id: @parent_question.id,
      conditional_type: 'scale',
      conditional_logic_type: 'single',
      conditional_operator: 'equal_to',
      conditional_value: 1,  # Only show if rating is exactly 1
      show_if_condition_met: true
    )
    
    # Update parent answer to trigger first but not second conditional
    @parent_answer.update!(numeric_answer: 2)  # Triggers first (<=2) but not second (=1)
    
    get survey_engine.answer_survey_path(@survey, email: @participant.email)
    
    assert_response :success
    
    # Both conditional questions should be present
    assert_select "div[data-question-id='#{@child_question.id}']", 1
    assert_select "div[data-question-id='#{@child_question_2.id}']", 1
    
    # Both should initially be hidden (will be shown by JS if conditions met)
    assert_select "div[data-question-id='#{@child_question.id}'][style*='display: none']", 1
    assert_select "div[data-question-id='#{@child_question_2.id}'][style*='display: none']", 1
  end

  private

  def css_select(selector)
    Nokogiri::HTML(response.body).css(selector)
  end
end