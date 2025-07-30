require "test_helper"

module SurveyEngine
  class SurveyTest < ActiveSupport::TestCase
    # Validations
    test "should require title" do
      survey = Survey.new
      assert_not survey.valid?
      assert_includes survey.errors[:title], "can't be blank"
    end

    test "should limit title length" do
      survey = Survey.new(title: "a" * 256)
      assert_not survey.valid?
      assert_includes survey.errors[:title], "is too long (maximum is 255 characters)"
    end

    test "should limit description length" do
      survey = Survey.new(title: "Valid Title", description: "a" * 2001)
      assert_not survey.valid?
      assert_includes survey.errors[:description], "is too long (maximum is 2000 characters)"
    end

    test "should require status" do
      survey = Survey.new(title: "Test")
      survey.status = nil
      assert_not survey.valid?
      assert_includes survey.errors[:status], "can't be blank"
    end

    test "should require valid status" do
      survey = Survey.new(title: "Test")
      assert_raises(ArgumentError) do
        survey.status = "invalid_status"
      end
    end

    test "should accept valid status values" do
      %w[draft published paused archived].each do |status|
        survey = Survey.new(title: "Test", status: status)
        assert survey.valid?, "Should accept status: #{status}"
      end
    end

    test "should require is_active boolean" do
      survey = Survey.new(title: "Test")
      survey.is_active = nil
      assert_not survey.valid?
      assert_includes survey.errors[:is_active], "is not included in the list"
    end

    test "should require global boolean" do
      survey = Survey.new(title: "Test")
      survey.global = nil
      assert_not survey.valid?
      assert_includes survey.errors[:global], "is not included in the list"
    end

    test "should validate published_at before expires_at" do
      survey = Survey.new(
        title: "Test",
        published_at: 1.day.from_now,
        expires_at: 1.hour.from_now
      )
      assert_not survey.valid?
      assert_includes survey.errors[:expires_at], "must be after publication date"
    end

    test "should accept valid date order" do
      survey = Survey.new(
        title: "Test",
        published_at: 1.hour.from_now,
        expires_at: 1.day.from_now
      )
      assert survey.valid?
    end

    # Associations
    test "should have many questions" do
      association = Survey.reflect_on_association(:questions)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # test "should have many participants" do
    #   association = Survey.reflect_on_association(:participants)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # test "should have many responses" do
    #   association = Survey.reflect_on_association(:responses)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # test "should have many settings" do
    #   association = Survey.reflect_on_association(:settings)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    test "should destroy dependent questions" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      question = survey.questions.create!(question_type: question_type, title: "Test Question", order_position: 1)
      
      assert_difference('Question.count', -1) do
        survey.destroy!
      end
    end

    # Default values
    test "should have default values" do
      survey = Survey.new(title: "Test")
      assert_equal false, survey.is_active
      assert_equal false, survey.global
      assert_equal "draft", survey.status
    end

    # Conditional Flow Integration Tests
    test "survey should correctly identify root and conditional questions" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      # Create main scale question
      main_question = Question.create!(
        survey: survey,
        question_type: scale_type,
        title: "Main Question",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Create regular question
      regular_question = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "Regular Question",
        order_position: 2
      )

      # Create conditional question
      conditional_question = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "Conditional Question",
        conditional_parent: main_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 3
      )

      # Test root questions (no conditional parent)
      root_questions = survey.questions.root_questions
      assert_includes root_questions, main_question
      assert_includes root_questions, regular_question
      assert_not_includes root_questions, conditional_question

      # Test conditional questions (have conditional parent)
      conditional_questions = survey.questions.conditional_questions
      assert_includes conditional_questions, conditional_question
      assert_not_includes conditional_questions, main_question
      assert_not_includes conditional_questions, regular_question
    end

    test "survey should handle complex conditional flows" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      # Main satisfaction question
      satisfaction_q = Question.create!(
        survey: survey,
        question_type: scale_type,
        title: "Overall Satisfaction (1-10)",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Main importance question
      importance_q = Question.create!(
        survey: survey,
        question_type: scale_type,
        title: "How important is this to you? (1-5)",
        scale_min: 1,
        scale_max: 5,
        order_position: 2
      )

      # Conditional: Low satisfaction
      low_satisfaction_q = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "What can we improve?",
        conditional_parent: satisfaction_q,
        conditional_operator: "less_than",
        conditional_value: 6,
        show_if_condition_met: true,
        order_position: 3
      )

      # Conditional: High importance
      high_importance_q = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "Tell us more about why this is important",
        conditional_parent: importance_q,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 4,
        show_if_condition_met: true,
        order_position: 4
      )

      # Test that survey has correct structure
      assert_equal 4, survey.questions.count
      assert_equal 2, survey.questions.root_questions.count
      assert_equal 2, survey.questions.conditional_questions.count

      # Test question flows
      satisfaction_flow = satisfaction_q.next_questions_for_answer(3) # Low satisfaction
      assert_includes satisfaction_flow, low_satisfaction_q

      importance_flow = importance_q.next_questions_for_answer(5) # High importance
      assert_includes importance_flow, high_importance_q

      # Test that questions are independent
      assert_empty satisfaction_q.next_questions_for_answer(8) # High satisfaction
      assert_empty importance_q.next_questions_for_answer(2) # Low importance
    end

    test "survey should maintain data integrity with conditional relationships" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_q = Question.create!(
        survey: survey,
        question_type: scale_type,
        title: "Parent Question",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      child1_q = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "Child Question 1",
        conditional_parent: parent_q,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 2
      )

      child2_q = Question.create!(
        survey: survey,
        question_type: text_type,
        title: "Child Question 2",
        conditional_parent: parent_q,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        show_if_condition_met: true,
        order_position: 3
      )

      # Verify parent-child relationships
      assert_equal parent_q, child1_q.conditional_parent
      assert_equal parent_q, child2_q.conditional_parent
      assert_includes parent_q.conditional_questions, child1_q
      assert_includes parent_q.conditional_questions, child2_q
      assert_equal 2, parent_q.conditional_questions.count

      # Verify conditional methods work
      assert child1_q.is_conditional?
      assert child2_q.is_conditional?
      assert_not parent_q.is_conditional?
      assert parent_q.has_conditional_questions?

      # Test cascade deletion
      initial_count = survey.questions.count
      parent_q.destroy!
      
      # Should delete parent + 2 children = 3 questions
      assert_equal initial_count - 3, survey.questions.count
    end

    test "survey should validate conditional question constraints across the survey" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      # Valid setup
      parent_q = Question.create!(
        survey: survey,
        question_type: scale_type,
        title: "Valid Parent",
        scale_min: 1,
        scale_max: 10,
        order_position: 1
      )

      # Valid conditional question
      valid_conditional = Question.new(
        survey: survey,
        question_type: text_type,
        title: "Valid Conditional",
        conditional_parent: parent_q,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true,
        order_position: 2
      )
      
      assert valid_conditional.valid?, "Valid conditional should pass validation: #{valid_conditional.errors.full_messages}"

      # Invalid: conditional value outside parent's scale range
      invalid_conditional = Question.new(
        survey: survey,
        question_type: text_type,
        title: "Invalid Conditional",
        conditional_parent: parent_q,
        conditional_operator: "less_than",
        conditional_value: 15, # Outside 1-10 range
        show_if_condition_met: true,
        order_position: 3
      )
      
      assert_not invalid_conditional.valid?
      assert_includes invalid_conditional.errors[:conditional_value], "must be within parent question scale range"
    end
  end
end