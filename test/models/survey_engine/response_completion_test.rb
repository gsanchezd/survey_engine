require "test_helper"

module SurveyEngine
  class ResponseCompletionTest < ActiveSupport::TestCase
    def setup
      # Use existing question types or create them if they don't exist
      @text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      @single_choice_type = QuestionType.find_or_create_by(name: "single_choice") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      @matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      # Create survey template with unique name
      @template = SurveyTemplate.create!(name: "Test Survey #{Time.current.to_f}")
      
      # Create survey
      @survey = Survey.create!(title: "Test Survey #{Time.current.to_f}", survey_template: @template, is_active: true)
      
      # Create participant and response
      @participant = Participant.create!(survey: @survey, email: "test@example.com", status: "invited")
      @response = Response.create!(survey: @survey, participant: @participant)
    end

    test "completion percentage with only regular questions" do
      # Create 3 regular questions
      q1 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q1", order_position: 1, is_required: true)
      q2 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q2", order_position: 2, is_required: true)
      q3 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q3", order_position: 3, is_required: true)
      
      # Answer 2 out of 3 questions
      Answer.create!(response: @response, question: q1, text_answer: "Answer 1")
      Answer.create!(response: @response, question: q2, text_answer: "Answer 2")
      
      assert_equal 66.67, @response.completion_percentage
      assert_equal 3, @response.visible_questions_for_response.count
      assert_equal 1, @response.unanswered_questions.count
    end

    test "completion percentage excludes matrix parent questions" do
      # Create regular question
      q1 = Question.create!(survey_template: @template, question_type: @text_type, title: "Q1", order_position: 1, is_required: true)
      
      # Create matrix parent question (should be excluded)
      matrix_parent = Question.create!(
        survey_template: @template, 
        question_type: @matrix_scale_type, 
        title: "Matrix Question", 
        order_position: 2, 
        is_required: true,
        is_matrix_question: true
      )
      
      # Create options for matrix questions
      opt1 = Option.create!(question: matrix_parent, option_text: "1", option_value: "1", order_position: 1)
      opt2 = Option.create!(question: matrix_parent, option_text: "2", option_value: "2", order_position: 2)
      opt3 = Option.create!(question: matrix_parent, option_text: "3", option_value: "3", order_position: 3)
      
      # Create matrix sub-questions (these are answerable)
      sub_q1 = Question.create!(
        survey_template: @template, 
        question_type: @matrix_scale_type, 
        title: "Sub Q1", 
        order_position: 3, 
        is_required: true,
        matrix_parent: matrix_parent,
        matrix_row_text: "Row 1"
      )
      sub_q2 = Question.create!(
        survey_template: @template, 
        question_type: @matrix_scale_type, 
        title: "Sub Q2", 
        order_position: 4, 
        is_required: true,
        matrix_parent: matrix_parent,
        matrix_row_text: "Row 2"
      )
      
      # Answer all answerable questions (1 regular + 2 matrix sub-questions)
      Answer.create!(response: @response, question: q1, text_answer: "Answer 1")
      
      # Create answers for matrix sub-questions with option selections
      answer1 = Answer.new(response: @response, question: sub_q1)
      answer1.answer_options.build(option: opt2)
      answer1.save!
      
      answer2 = Answer.new(response: @response, question: sub_q2)
      answer2.answer_options.build(option: opt1)
      answer2.save!
      
      # Should be 100% - matrix parent is excluded from count
      assert_equal 100.0, @response.completion_percentage
      assert_equal 3, @response.visible_questions_for_response.count  # 1 regular + 2 matrix subs
      assert_equal 0, @response.unanswered_questions.count
    end

    test "completion percentage with single conditional logic" do
      # Create NPS question (parent)
      nps_question = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS Question", 
        order_position: 1, 
        is_required: true,
        scale_min: 0,
        scale_max: 10
      )
      
      # Create conditional question for detractors (NPS <= 6)
      detractor_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What didn't you like?", 
        order_position: 2, 
        is_required: true,
        conditional_parent: nps_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 6,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # Create conditional question for promoters (NPS >= 9)
      promoter_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What did you like?", 
        order_position: 3, 
        is_required: true,
        conditional_parent: nps_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 9,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # User gives NPS score of 3 (detractor)
      Answer.create!(response: @response, question: nps_question, numeric_answer: 3)
      
      # Only NPS + detractor question should be visible (promoter hidden)
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_includes visible_questions, detractor_q
      assert_not_includes visible_questions, promoter_q
      
      # Answer only NPS question - 50% completion (1 of 2 visible)
      assert_equal 50.0, @response.completion_percentage
      
      # Answer detractor question too - 100% completion
      Answer.create!(response: @response, question: detractor_q, text_answer: "Poor service")
      @response.reload
      assert_equal 100.0, @response.completion_percentage
    end

    test "completion percentage with range conditional logic" do
      # Create NPS question (parent)
      nps_question = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS Question", 
        order_position: 1, 
        is_required: true,
        scale_min: 0,
        scale_max: 10
      )
      
      # Create conditional question for passives (NPS 7-8 range)
      passive_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What could we improve?", 
        order_position: 2, 
        is_required: true,
        conditional_parent: nps_question,
        conditional_logic_type: "range",
        conditional_operator: "greater_than_or_equal",
        conditional_value: 7,
        conditional_operator_2: "less_than_or_equal",
        conditional_value_2: 8,
        show_if_condition_met: true
      )
      
      # User gives NPS score of 7 (passive - should show range question)
      Answer.create!(response: @response, question: nps_question, numeric_answer: 7)
      
      # Both questions should be visible
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_includes visible_questions, passive_q
      
      # Only NPS answered - 50% completion
      assert_equal 50.0, @response.completion_percentage
      
      # Test with score outside range (NPS = 9)
      @response.answers.destroy_all
      Answer.create!(response: @response, question: nps_question, numeric_answer: 9)
      
      # Only NPS should be visible (passive hidden for promoters)
      visible_questions = @response.visible_questions_for_response
      assert_equal 1, visible_questions.count
      assert_includes visible_questions, nps_question
      assert_not_includes visible_questions, passive_q
      
      # 100% completion (only 1 visible question answered)
      assert_equal 100.0, @response.completion_percentage
    end

    test "completion percentage with multiple conditional levels" do
      # Parent question
      q1 = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "Rate service", 
        order_position: 1, 
        is_required: true,
        scale_min: 1,
        scale_max: 5
      )
      
      # First level conditional (shows if rating <= 3)
      q2 = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "What went wrong?", 
        order_position: 2, 
        is_required: true,
        conditional_parent: q1,
        conditional_operator: "less_than_or_equal",
        conditional_value: 3,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # Second level conditional (shows if q1 rating = 1)
      q3 = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "Would you like a refund?", 
        order_position: 3, 
        is_required: true,
        conditional_parent: q1,
        conditional_operator: "equal_to",
        conditional_value: 1,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # Test with rating = 2 (shows q1, q2 but not q3)
      Answer.create!(response: @response, question: q1, numeric_answer: 2)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 2, visible_questions.count
      assert_includes visible_questions, q1
      assert_includes visible_questions, q2
      assert_not_includes visible_questions, q3
      
      # 50% completion (1 of 2 answered)
      assert_equal 50.0, @response.completion_percentage
      
      # Test with rating = 1 (shows all 3 questions)
      @response.answers.destroy_all
      Answer.create!(response: @response, question: q1, numeric_answer: 1)
      
      visible_questions = @response.visible_questions_for_response
      assert_equal 3, visible_questions.count
      
      # 33.33% completion (1 of 3 answered)
      assert_equal 33.33, @response.completion_percentage
    end

    test "completion percentage with no visible questions" do
      # Create conditional question that will never show
      q1 = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "Parent", 
        order_position: 1, 
        is_required: true,
        scale_min: 1,
        scale_max: 5
      )
      
      q2 = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "Never shows", 
        order_position: 2, 
        is_required: true,
        conditional_parent: q1,
        conditional_operator: "greater_than",
        conditional_value: 5,  # Impossible value for 1-5 scale (greater than max)
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # Answer parent question
      Answer.create!(response: @response, question: q1, numeric_answer: 3)
      
      # Only parent should be visible
      assert_equal 1, @response.visible_questions_for_response.count
      assert_equal 100.0, @response.completion_percentage
    end

    test "visible_questions_for_response handles complex survey structure" do
      # Mix of regular, matrix, and conditional questions
      regular_q = Question.create!(survey_template: @template, question_type: @text_type, title: "Regular", order_position: 1)
      
      matrix_parent = Question.create!(
        survey_template: @template, 
        question_type: @matrix_scale_type, 
        title: "Matrix", 
        order_position: 2,
        is_matrix_question: true
      )
      
      # Create options for matrix parent
      Option.create!(question: matrix_parent, option_text: "Strongly Disagree", option_value: "1", order_position: 1)
      Option.create!(question: matrix_parent, option_text: "Agree", option_value: "2", order_position: 2)
      Option.create!(question: matrix_parent, option_text: "Strongly Agree", option_value: "3", order_position: 3)
      
      matrix_sub = Question.create!(
        survey_template: @template, 
        question_type: @matrix_scale_type, 
        title: "Matrix Sub", 
        order_position: 3,
        matrix_parent: matrix_parent,
        matrix_row_text: "Matrix Row 1"
      )
      
      nps_q = Question.create!(
        survey_template: @template, 
        question_type: @scale_type, 
        title: "NPS", 
        order_position: 4,
        scale_min: 0,
        scale_max: 10
      )
      
      conditional_q = Question.create!(
        survey_template: @template, 
        question_type: @text_type, 
        title: "Conditional", 
        order_position: 5,
        conditional_parent: nps_q,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        conditional_logic_type: "single",
        show_if_condition_met: true
      )
      
      # Answer NPS with high score to show conditional
      Answer.create!(response: @response, question: nps_q, numeric_answer: 9)
      
      visible = @response.visible_questions_for_response
      
      # Should include: regular_q, matrix_sub, nps_q, conditional_q
      # Should exclude: matrix_parent (is_matrix_question: true)
      assert_equal 4, visible.count
      assert_includes visible, regular_q
      assert_includes visible, matrix_sub
      assert_includes visible, nps_q
      assert_includes visible, conditional_q
      assert_not_includes visible, matrix_parent
    end
  end
end