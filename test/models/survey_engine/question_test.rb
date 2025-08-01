require "test_helper"

module SurveyEngine
  class QuestionTest < ActiveSupport::TestCase
    def setup
      @survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      @question_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
    end

    # Validations
    test "should require title" do
      question = Question.new(survey: @survey, question_type: @question_type)
      assert_invalid question
      assert_validation_error question, :title
    end

    test "should limit title length" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "a" * 501
      )
      assert_invalid question
      assert_validation_error question, :title
    end

    test "should limit description length" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Valid Title",
        description: "a" * 1001
      )
      assert_invalid question
      assert_validation_error question, :description
    end

    test "should require order_position" do
      question = Question.new(survey: @survey, question_type: @question_type, title: "Test")
      # Bypass the callback that sets default order_position
      question.define_singleton_method(:set_next_order_position) { nil }
      question.order_position = nil
      assert_invalid question
      assert_validation_error question, :order_position
    end

    test "should require unique order_position within survey" do
      Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "First Question",
        order_position: 1
      )

      duplicate = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Second Question",
        order_position: 1
      )

      assert_invalid duplicate
      assert_validation_error duplicate, :order_position
    end

    test "should allow same order_position in different surveys" do
      other_survey = Survey.create!(title: "Other Survey #{SecureRandom.hex(4)}")
      
      Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "First Question",
        order_position: 1
      )

      question_in_other_survey = Question.new(
        survey: other_survey,
        question_type: @question_type,
        title: "Other Question",
        order_position: 1
      )

      assert question_in_other_survey.valid?
    end

    test "should require boolean values for flags" do
      question = Question.new(survey: @survey, question_type: @question_type, title: "Test")
      
      question.is_required = nil
      assert_invalid question
      assert_validation_error question, :is_required

      question.is_required = true
      question.allow_other = nil
      assert_invalid question
      assert_validation_error question, :allow_other

      question.allow_other = false
      question.randomize_options = nil
      assert_invalid question
      assert_validation_error question, :randomize_options
    end

    test "should validate positive max_characters" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        max_characters: -1
      )
      assert_invalid question
      assert_validation_error question, :max_characters
    end

    test "should validate non-negative min_selections" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        min_selections: -1
      )
      assert_invalid question
      assert_validation_error question, :min_selections
    end

    test "should validate positive max_selections" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        max_selections: 0
      )
      assert_invalid question
      assert_validation_error question, :max_selections
    end

    # Associations
    test "should belong to survey" do
      association = Question.reflect_on_association(:survey)
      assert_equal :belongs_to, association.macro
    end

    test "should belong to question_type" do
      association = Question.reflect_on_association(:question_type)
      assert_equal :belongs_to, association.macro
    end

    test "should have many options" do
      association = Question.reflect_on_association(:options)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # test "should have many answers" do
    #   association = Question.reflect_on_association(:answers)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    test "should destroy dependent options" do
      question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
      option = question.options.create!(
        option_text: "Test Option",
        option_value: "test",
        order_position: 1
      )

      assert_difference('Option.count', -1) do
        question.destroy!
      end
    end

    # Default values
    test "should have default values" do
      question = Question.new(survey: @survey, question_type: @question_type, title: "Test")
      assert_equal false, question.is_required
      assert_equal false, question.allow_other
      assert_equal false, question.randomize_options
    end

    # Conditional Flow Tests
    test "should have conditional parent association" do
      association = Question.reflect_on_association(:conditional_parent)
      assert_equal :belongs_to, association.macro
      assert_equal true, association.options[:optional]
      assert_equal 'Question', association.options[:class_name]
    end

    test "should have conditional questions association" do
      association = Question.reflect_on_association(:conditional_questions)
      assert_equal :has_many, association.macro
      assert_equal 'Question', association.options[:class_name]
      assert_equal 'conditional_parent_id', association.options[:foreign_key]
      assert_equal :destroy, association.options[:dependent]
    end

    # Conditional Validations
    test "should validate conditional operator values" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "invalid_operator",
        conditional_value: 5
      )
      assert_invalid question
      assert_validation_error question, :conditional_operator
    end

    test "should require conditional operator when conditional value is present" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_value: 5
      )
      assert_invalid question
      assert_validation_error question, :conditional_operator
    end

    test "should require conditional value when conditional operator is present" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than"
      )
      assert_invalid question
      assert_validation_error question, :conditional_value
    end

    test "should validate conditional parent is from same survey" do
      other_survey = Survey.create!(title: "Other Survey")
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: other_survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      assert_invalid question
      assert_validation_error question, :conditional_parent
    end

    test "should validate conditional parent is scale question" do
      parent_question = Question.create!(
        survey: @survey, 
        question_type: @question_type, 
        title: "Parent"
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      assert_invalid question
      assert_validation_error question, :conditional_parent
    end

    test "should validate conditional parent is not itself conditional" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      grandparent = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Grandparent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10,
        conditional_parent: grandparent,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 3
      )
      assert_invalid question
      assert_validation_error question, :conditional_parent
    end

    test "should validate conditional value within parent scale range" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      # Test value below minimum
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 0
      )
      assert_invalid question
      assert_validation_error question, :conditional_value
      
      # Test value above maximum
      question.conditional_value = 11
      assert_invalid question
      assert_validation_error question, :conditional_value
      
      # Test valid value
      question.conditional_value = 5
      assert question.valid?
    end

    # Conditional Logic Methods
    test "is_conditional? should return true when has conditional parent" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      assert conditional_question.is_conditional?
      assert_not parent_question.is_conditional?
    end

    test "has_conditional_questions? should return true when has child questions" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      assert_not parent_question.has_conditional_questions?
      
      Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      assert parent_question.has_conditional_questions?
    end

    test "is_scale_question? should return true for scale question type" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      scale_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Scale Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      text_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Text Question"
      )
      
      assert scale_question.is_scale_question?
      assert_not text_question.is_scale_question?
    end

    # Conditional Evaluation Tests
    test "evaluate_condition should correctly evaluate less_than" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      assert conditional_question.evaluate_condition(3)
      assert conditional_question.evaluate_condition(4)
      assert_not conditional_question.evaluate_condition(5)
      assert_not conditional_question.evaluate_condition(6)
    end

    test "evaluate_condition should correctly evaluate greater_than" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "greater_than",
        conditional_value: 7
      )
      
      assert_not conditional_question.evaluate_condition(6)
      assert_not conditional_question.evaluate_condition(7)
      assert conditional_question.evaluate_condition(8)
      assert conditional_question.evaluate_condition(9)
    end

    test "evaluate_condition should correctly evaluate equal_to" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "equal_to",
        conditional_value: 5
      )
      
      assert_not conditional_question.evaluate_condition(4)
      assert conditional_question.evaluate_condition(5)
      assert_not conditional_question.evaluate_condition(6)
    end

    test "evaluate_condition should correctly evaluate greater_than_or_equal" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 7
      )
      
      assert_not conditional_question.evaluate_condition(6)
      assert conditional_question.evaluate_condition(7)
      assert conditional_question.evaluate_condition(8)
    end

    test "evaluate_condition should correctly evaluate less_than_or_equal" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than_or_equal",
        conditional_value: 5
      )
      
      assert conditional_question.evaluate_condition(4)
      assert conditional_question.evaluate_condition(5)
      assert_not conditional_question.evaluate_condition(6)
    end

    test "should_show? should work with show_if_condition_met true" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true
      )
      
      assert conditional_question.should_show?(3) # 3 < 5, show because condition met
      assert_not conditional_question.should_show?(7) # 7 > 5, don't show because condition not met
    end

    test "should_show? should work with show_if_condition_met false" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: false
      )
      
      assert_not conditional_question.should_show?(3) # 3 < 5, don't show because show_if_condition_met is false
      assert conditional_question.should_show?(7) # 7 > 5, show because condition not met and show_if_condition_met is false
    end

    test "should_show? should return true for non-conditional questions" do
      regular_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Regular Question"
      )
      
      assert regular_question.should_show?(5)
      assert regular_question.should_show?(nil)
    end

    test "next_questions_for_answer should return matching conditional questions" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      low_rating_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Low Rating Question",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true
      )
      
      high_rating_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "High Rating Question",
        conditional_parent: parent_question,
        conditional_operator: "greater_than_or_equal",
        conditional_value: 8,
        show_if_condition_met: true
      )
      
      # Test low rating (3) - should show low_rating_question
      next_questions = parent_question.next_questions_for_answer(3)
      assert_includes next_questions, low_rating_question
      assert_not_includes next_questions, high_rating_question
      
      # Test medium rating (6) - should show no conditional questions
      next_questions = parent_question.next_questions_for_answer(6)
      assert_empty next_questions
      
      # Test high rating (9) - should show high_rating_question
      next_questions = parent_question.next_questions_for_answer(9)
      assert_includes next_questions, high_rating_question
      assert_not_includes next_questions, low_rating_question
    end

    # Scopes
    test "root_questions scope should return questions without conditional parent" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      root_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Root Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Conditional Question",
        conditional_parent: root_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      root_questions = @survey.questions.root_questions
      assert_includes root_questions, root_question
      assert_not_includes root_questions, conditional_question
    end

    test "conditional_questions scope should return questions with conditional parent" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      root_question = Question.create!(
        survey: @survey, 
        question_type: scale_type, 
        title: "Root Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Conditional Question",
        conditional_parent: root_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      conditional_questions = @survey.questions.conditional_questions
      assert_includes conditional_questions, conditional_question
      assert_not_includes conditional_questions, root_question
    end
  end
end