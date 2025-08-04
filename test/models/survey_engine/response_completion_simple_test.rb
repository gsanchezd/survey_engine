require "test_helper"

module SurveyEngine
  class ResponseCompletionSimpleTest < ActiveSupport::TestCase
    def setup
      # Use existing question types
      @text_type = QuestionType.find_by(name: "text")
      @scale_type = QuestionType.find_by(name: "scale")
      
      # Create survey template with unique name
      @template = SurveyTemplate.create!(name: "Test Survey #{Time.current.to_f}")
      
      # Create survey
      @survey = Survey.create!(title: "Test Survey #{Time.current.to_f}", survey_template: @template, is_active: true)
      
      # Create participant and response
      @participant = Participant.create!(survey: @survey, email: "test@example.com", status: "invited")
      @response = Response.create!(survey: @survey, participant: @participant)
    end

    test "completion percentage with regular questions only" do
      # Create 3 regular questions
      q1 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q1", order_position: 1)
      q2 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q2", order_position: 2)
      q3 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q3", order_position: 3)
      
      # Answer 2 out of 3 questions
      Answer.create!(response: @response, question: q1, text_answer: "Answer 1")
      Answer.create!(response: @response, question: q2, text_answer: "Answer 2")
      
      # Should be 66.67% (2 of 3 answered)
      assert_equal 66.67, @response.completion_percentage
      assert_equal 3, @response.visible_questions_for_response.count
      assert_equal 1, @response.unanswered_questions.count
    end

    test "completion percentage with conditional questions - condition met" do
      # Create NPS question (parent)
      nps_question = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS Question", 
        order_position: 1,
        scale_min: 0,
        scale_max: 10
      )
      
      # Create conditional question for low scores (NPS <= 6)
      conditional_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What didn't you like?", 
        order_position: 2,
        conditional_parent: nps_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 6,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # User gives NPS score of 3 (should show conditional question)
      Answer.create!(response: @response, question: nps_question, numeric_answer: 3)
      
      # Both questions should be visible
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_includes visible_questions, conditional_q
      
      # Only NPS answered - 50% completion (1 of 2 visible)
      assert_equal 50.0, @response.completion_percentage
      
      # Answer conditional question too - 100% completion
      Answer.create!(response: @response, question: conditional_q, text_answer: "Poor service")
      @response.reload
      assert_equal 100.0, @response.completion_percentage
    end

    test "completion percentage with conditional questions - condition not met" do
      # Create NPS question (parent)
      nps_question = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS Question", 
        order_position: 1,
        scale_min: 0,
        scale_max: 10
      )
      
      # Create conditional question for low scores (NPS <= 6)
      conditional_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What didn't you like?", 
        order_position: 2,
        conditional_parent: nps_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 6,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # User gives NPS score of 9 (should NOT show conditional question)
      Answer.create!(response: @response, question: nps_question, numeric_answer: 9)
      
      # Only NPS question should be visible (conditional hidden)
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_not_includes visible_questions, conditional_q
      
      # Only 1 visible question answered - 100% completion
      assert_equal 100.0, @response.completion_percentage
    end

    test "completion percentage with range conditional logic" do
      # Create NPS question (parent)
      nps_question = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS Question", 
        order_position: 1,
        scale_min: 0,
        scale_max: 10
      )
      
      # Create conditional question for passives (NPS 7-8 range)
      passive_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What could we improve?", 
        order_position: 2,
        conditional_parent: nps_question,
        conditional_logic_type: "range",
        conditional_operator: "greater_than_or_equal",
        conditional_value: 7,
        conditional_operator_2: "less_than_or_equal",
        conditional_value_2: 8,
        show_if_condition_met: true
      )
      
      # Test score in range (NPS = 7)
      Answer.create!(response: @response, question: nps_question, numeric_answer: 7)
      
      # Both questions should be visible
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_includes visible_questions, passive_q
      
      # Only NPS answered - 50% completion
      assert_equal 50.0, @response.completion_percentage
      
      # Test score outside range (NPS = 9)
      @response.answers.destroy_all
      Answer.create!(response: @response, question: nps_question, numeric_answer: 9)
      
      # Only NPS should be visible (passive hidden)
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_not_includes visible_questions, passive_q
      
      # 100% completion (only 1 visible question)
      assert_equal 100.0, @response.completion_percentage
    end

    test "empty survey has 100% completion" do
      # No questions = 100% completion
      assert_equal 100.0, @response.completion_percentage
      assert_equal 0, @response.visible_questions_for_response.count
      assert_equal 0, @response.unanswered_questions.count
    end
  end
end