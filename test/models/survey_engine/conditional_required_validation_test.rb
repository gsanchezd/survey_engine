require "test_helper"

module SurveyEngine
  class ConditionalRequiredValidationTest < ActiveSupport::TestCase
    def setup
      # Create question types
      @scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      # Create survey template and survey
      @template = SurveyTemplate.create!(name: "Conditional Required Test #{Time.current.to_f}")
      @survey = Survey.create!(title: "Test Survey", survey_template: @template, is_active: true)
      
      # Create participant and response
      @participant = Participant.create!(survey: @survey, email: "test@example.com", status: "invited")
      @response = Response.create!(survey: @survey, participant: @participant)
    end

    test "required conditional question that is hidden should not block form submission" do
      # Parent question: satisfaction rating 1-10
      satisfaction_question = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "How satisfied are you with our service?",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      # Conditional follow-up: only shows if satisfaction <= 5
      improvement_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What specific improvements would you suggest?",
        order_position: 2,
        is_required: true,  # This is REQUIRED but conditional
        conditional_parent: satisfaction_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5,
        show_if_condition_met: true
      )

      # Another regular required question
      final_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Any final comments?",
        order_position: 3,
        is_required: true
      )

      # User gives HIGH satisfaction (8/10) - this should HIDE the improvement question
      Answer.create!(
        response: @response,
        question: satisfaction_question,
        numeric_answer: 8
      )

      # User answers the final question
      Answer.create!(
        response: @response,
        question: final_question,
        text_answer: "Great service overall!"
      )

      # Check visible questions - improvement question should be hidden
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, satisfaction_question
      assert_includes visible_questions, final_question
      assert_not_includes visible_questions, improvement_question
      
      # The form should be completable even though improvement_question is required
      # but hidden due to conditional logic
      assert_equal 100.0, @response.completion_percentage
      assert_equal 0, @response.unanswered_questions.count
      
      # Validate that the response can be marked as completed
      @response.completed_at = Time.current
      assert @response.valid?, "Response should be valid even with hidden required question"
    end

    test "required conditional question that is visible must be answered" do
      # Same setup as above
      satisfaction_question = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "How satisfied are you with our service?",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      improvement_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What specific improvements would you suggest?",
        order_position: 2,
        is_required: true,
        conditional_parent: satisfaction_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5,
        show_if_condition_met: true
      )

      final_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Any final comments?",
        order_position: 3,
        is_required: true
      )

      # User gives LOW satisfaction (3/10) - this should SHOW the improvement question
      Answer.create!(
        response: @response,
        question: satisfaction_question,
        numeric_answer: 3
      )

      # User answers final question but NOT the conditional improvement question
      Answer.create!(
        response: @response,
        question: final_question,
        text_answer: "Need better service!"
      )

      # Check visible questions - improvement question should be visible
      visible_questions = @response.visible_questions_for_response
      assert_equal 3, visible_questions.count
      assert_includes visible_questions, satisfaction_question
      assert_includes visible_questions, improvement_question
      assert_includes visible_questions, final_question
      
      # The form should NOT be complete - missing the required improvement question
      assert_equal 66.67, @response.completion_percentage.round(2)
      assert_equal 1, @response.unanswered_questions.count
      assert_includes @response.unanswered_questions, improvement_question
      
      # Now answer the improvement question
      Answer.create!(
        response: @response,
        question: improvement_question,
        text_answer: "Faster response times needed"
      )

      # Now it should be 100% complete
      @response.reload
      assert_equal 100.0, @response.completion_percentage
      assert_equal 0, @response.unanswered_questions.count
    end

    test "multiple conditional required questions with different visibility states" do
      # Parent question
      rating_question = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Rate your experience (1-10)",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      # Conditional for low scores (1-3)
      very_low_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What went very wrong?",
        order_position: 2,
        is_required: true,
        conditional_parent: rating_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 3,
        show_if_condition_met: true
      )

      # Conditional for medium scores (4-7)
      medium_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "How can we improve?",
        order_position: 3,
        is_required: true,
        conditional_parent: rating_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 4,
        show_if_condition_met: true
      )

      # Add another condition to medium_question (range: 4-7)
      medium_question.update!(
        conditional_operator_2: "less_than_or_equal",
        conditional_value_2: 7,
        conditional_logic_type: "range"
      )

      # Conditional for high scores (8-10)
      high_question = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What did we do well?",
        order_position: 4,
        is_required: true,
        conditional_parent: rating_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        show_if_condition_met: true
      )

      # User gives a HIGH score (9/10)
      # This should show: rating_question + high_question
      # This should hide: very_low_question + medium_question
      Answer.create!(
        response: @response,
        question: rating_question,
        numeric_answer: 9
      )

      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, rating_question
      assert_includes visible_questions, high_question
      assert_not_includes visible_questions, very_low_question
      assert_not_includes visible_questions, medium_question

      # Only answered the parent question - 50% complete
      assert_equal 50.0, @response.completion_percentage
      
      # Answer the visible conditional question
      Answer.create!(
        response: @response,
        question: high_question,
        text_answer: "Excellent customer service!"
      )

      # Now should be 100% - the hidden required questions don't block completion
      @response.reload
      assert_equal 100.0, @response.completion_percentage
      assert_equal 0, @response.unanswered_questions.count
    end

  end
end