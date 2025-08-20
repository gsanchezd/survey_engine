require "test_helper"

module SurveyEngine
  class QAEdgeCasesTest < ActiveSupport::TestCase
    def setup
      @scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @single_choice_type = QuestionType.find_or_create_by(name: "single_choice") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      @template = SurveyTemplate.create!(name: "QA Evil Test #{Time.current.to_f}")
      @survey = Survey.create!(title: "Evil Survey", survey_template: @template, is_active: true)
      @participant = Participant.create!(survey: @survey, email: "qa@evil.com", status: "invited")
      @response = Response.create!(survey: @survey, participant: @participant)
    end

    test "EDGE CASE: required conditional with impossible condition should allow submission" do
      # Parent question 1-5 scale
      parent_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Rate 1-5",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 5
      )

      # Evil conditional: shows if score > 5 (IMPOSSIBLE on 1-5 scale!)
      evil_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "This should NEVER show",
        order_position: 2,
        is_required: true,  # Required but impossible to show
        conditional_parent: parent_q,
        conditional_operator: "greater_than",
        conditional_value: 5,
        show_if_condition_met: true
      )

      # Answer with max possible value
      Answer.create!(response: @response, question: parent_q, numeric_answer: 5)

      # Evil question should be hidden (impossible condition)
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_not_includes visible_questions, evil_q
      
      # Should be 100% complete despite having a "required" question that can never show
      assert_equal 100.0, @response.completion_percentage
    end

    test "EDGE CASE: conditional with boundary conditions - equal_to edge" do
      parent_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Rate 1-10",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      # Shows exactly when score = 5.0
      exact_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Exactly 5 question",
        order_position: 2,
        is_required: true,
        conditional_parent: parent_q,
        conditional_operator: "equal_to",
        conditional_value: 5,
        show_if_condition_met: true
      )

      # Test boundary: 4.99999 should NOT show
      Answer.create!(response: @response, question: parent_q, numeric_answer: 4.999)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_not_includes visible_questions, exact_q
      assert_equal 100.0, @response.completion_percentage

      # Test boundary: exactly 5 should show
      @response.answers.destroy_all
      Answer.create!(response: @response, question: parent_q, numeric_answer: 5)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, exact_q
      assert_equal 50.0, @response.completion_percentage  # Now requires the conditional
    end

    test "EDGE CASE: circular logic attempt with inverted conditions" do
      # Parent satisfaction question
      satisfaction_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Satisfaction 1-10",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      # Shows for LOW satisfaction (<=3)
      low_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What went wrong?",
        order_position: 2,
        is_required: true,
        conditional_parent: satisfaction_q,
        conditional_operator: "less_than_or_equal",
        conditional_value: 3,
        show_if_condition_met: true
      )

      # Shows for HIGH satisfaction (>=8) but with inverted logic
      high_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "What was great? (inverted logic)",
        order_position: 3,
        is_required: true,
        conditional_parent: satisfaction_q,
        conditional_operator: "less_than",  # Less than 8...
        conditional_value: 8,
        show_if_condition_met: false  # ...but show when condition is FALSE (so >=8)
      )

      # Test middle score (5) - should hide both conditionals
      Answer.create!(response: @response, question: satisfaction_q, numeric_answer: 5)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_includes visible_questions, satisfaction_q
      assert_not_includes visible_questions, low_q
      assert_not_includes visible_questions, high_q
      assert_equal 100.0, @response.completion_percentage
    end

    test "EDGE CASE: all questions are conditional and all are hidden" do
      # Parent question
      trigger_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Trigger question (1-5)",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 5
      )

      # All remaining questions are conditional and will be hidden
      conditional1 = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Hidden conditional 1",
        order_position: 2,
        is_required: true,
        conditional_parent: trigger_q,
        conditional_operator: "greater_than",
        conditional_value: 5,  # Impossible on 1-5 scale
        show_if_condition_met: true
      )

      conditional2 = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Hidden conditional 2",
        order_position: 3,
        is_required: true,
        conditional_parent: trigger_q,
        conditional_operator: "less_than",
        conditional_value: 1,  # Impossible on 1-5 scale
        show_if_condition_met: true
      )

      # Answer the trigger
      Answer.create!(response: @response, question: trigger_q, numeric_answer: 3)

      # Should only show the trigger question
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_includes visible_questions, trigger_q
      assert_not_includes visible_questions, conditional1
      assert_not_includes visible_questions, conditional2
      
      # Should be 100% complete (only 1 visible question answered)
      assert_equal 100.0, @response.completion_percentage
    end

    test "EDGE CASE: user changes parent answer to hide previously shown conditional" do
      parent_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Rating 1-10",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      conditional_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Follow-up question",
        order_position: 2,
        is_required: true,
        conditional_parent: parent_q,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5,
        show_if_condition_met: true
      )

      # Step 1: User gives low rating (3) - conditional should show
      parent_answer = Answer.create!(response: @response, question: parent_q, numeric_answer: 3)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, conditional_q
      assert_equal 50.0, @response.completion_percentage

      # Step 2: User answers the conditional
      conditional_answer = Answer.create!(response: @response, question: conditional_q, text_answer: "Problems here")
      @response.reload
      assert_equal 100.0, @response.completion_percentage

      # Step 3: EVIL - User changes parent answer to HIGH rating (8)
      # This should HIDE the conditional, but the answer is still there!
      parent_answer.update!(numeric_answer: 8)

      # What happens to completion percentage?
      @response.reload
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count  # Only parent visible
      assert_not_includes visible_questions, conditional_q
      
      # Should be 100% complete - conditional is now hidden so its answer doesn't matter
      assert_equal 100.0, @response.completion_percentage
      
      # But the conditional answer should still exist in database
      assert conditional_answer.reload
      assert_equal "Problems here", conditional_answer.text_answer
    end

    test "EDGE CASE: zero division when no visible questions exist" do
      # Create survey with only impossible conditionals
      trigger_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Trigger",
        order_position: 1,
        is_required: false,  # Not required
        scale_min: 1,
        scale_max: 5
      )

      impossible_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Impossible",
        order_position: 2,
        is_required: true,
        conditional_parent: trigger_q,
        conditional_operator: "greater_than",
        conditional_value: 10,  # Impossible on 1-5 scale
        show_if_condition_met: true
      )

      # Don't answer anything
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count  # Only trigger (non-required)
      
      # What happens with completion percentage when no required questions?
      completion = @response.completion_percentage
      assert completion.is_a?(Numeric), "Completion percentage should be numeric, got #{completion.class}"
      assert_equal 0.0, completion  # Should handle gracefully
    end

    test "EDGE CASE: non-required conditional that affects completion calculation" do
      # Required parent
      parent_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Required parent",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      # NON-required conditional
      optional_conditional = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Optional follow-up",
        order_position: 2,
        is_required: false,  # NOT required
        conditional_parent: parent_q,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5,
        show_if_condition_met: true
      )

      # Answer parent with low score to show conditional
      Answer.create!(response: @response, question: parent_q, numeric_answer: 3)

      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      
      # Should be 100% complete because conditional is not required
      assert_equal 100.0, @response.completion_percentage
      
      # Unanswered questions should be empty (non-required questions shouldn't count)
      assert_equal 0, @response.unanswered_questions.count
    end

    test "EDGE CASE: string vs numeric comparison in conditions" do
      parent_q = Question.create!(
        survey_template: @template,
        question_type: @scale_type,
        title: "Numeric parent",
        order_position: 1,
        is_required: true,
        scale_min: 1,
        scale_max: 10
      )

      conditional_q = Question.create!(
        survey_template: @template,
        question_type: @text_type,
        title: "Conditional",
        order_position: 2,
        is_required: true,
        conditional_parent: parent_q,
        conditional_operator: "greater_than",
        conditional_value: 5,  # Stored as integer
        show_if_condition_met: true
      )

      # Answer with string that represents a number
      answer = Answer.create!(response: @response, question: parent_q, numeric_answer: "7")

      # Should still work correctly despite potential type issues
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, conditional_q
    end
  end
end