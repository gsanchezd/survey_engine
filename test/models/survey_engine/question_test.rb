require "test_helper"

module SurveyEngine
  class QuestionTest < ActiveSupport::TestCase
    def setup
      @survey_template = SurveyTemplate.create!(name: "Test Template #{SecureRandom.hex(4)}")
      @survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}", survey_template: @survey_template)
      @question_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
    end

    # Validations
    test "should require title" do
      question = Question.new(survey_template: @survey_template, question_type: @question_type)
      assert_invalid question
      assert_validation_error question, :title
    end

    test "should limit title length" do
      question = Question.new(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "a" * 501
      )
      assert_invalid question
      assert_validation_error question, :title
    end

    test "should limit description length" do
      question = Question.new(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Valid Title",
        description: "a" * 1001
      )
      assert_invalid question
      assert_validation_error question, :description
    end

    test "should require order_position" do
      question = Question.new(survey_template: @survey_template, question_type: @question_type, title: "Test")
      # Bypass the callback that sets default order_position
      question.define_singleton_method(:set_next_order_position) { nil }
      question.order_position = nil
      assert_invalid question
      assert_validation_error question, :order_position
    end


    test "should allow same order_position in different surveys" do
      other_survey_template = SurveyTemplate.create!(name: "Other Template #{SecureRandom.hex(4)}")
      other_survey = Survey.create!(title: "Other Survey #{SecureRandom.hex(4)}", survey_template: other_survey_template)
      
      Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "First Question",
        order_position: 1
      )

      question_in_other_survey = Question.new(
        survey_template: other_survey_template,
        question_type: @question_type,
        title: "Other Question",
        order_position: 1
      )

      assert question_in_other_survey.valid?
    end

    test "should require boolean values for flags" do
      question = Question.new(survey_template: @survey_template, question_type: @question_type, title: "Test")
      
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
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test",
        max_characters: -1
      )
      assert_invalid question
      assert_validation_error question, :max_characters
    end

    test "should validate non-negative min_selections" do
      question = Question.new(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test",
        min_selections: -1
      )
      assert_invalid question
      assert_validation_error question, :min_selections
    end

    test "should validate positive max_selections" do
      question = Question.new(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test",
        max_selections: 0
      )
      assert_invalid question
      assert_validation_error question, :max_selections
    end

    # Associations
    test "should belong to survey_template" do
      association = Question.reflect_on_association(:survey_template)
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
        survey_template: @survey_template,
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
      question = Question.new(survey_template: @survey_template, question_type: @question_type, title: "Test")
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test",
        conditional_parent: parent_question,
        conditional_operator: "less_than"
      )
      assert_invalid question
      assert_validation_error question, :conditional_value
    end

    test "should validate conditional parent is from same survey_template" do
      other_survey_template = SurveyTemplate.create!(name: "Other Template")
      other_survey = Survey.create!(title: "Other Survey", survey_template: other_survey_template)
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      parent_question = Question.create!(
        survey_template: other_survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: @question_type, 
        title: "Parent"
      )
      
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Grandparent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      parent_question = Question.create!(
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10,
        conditional_parent: grandparent,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      # Test value below minimum
      question = Question.new(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      assert_not parent_question.has_conditional_questions?
      
      Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Scale Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      text_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Parent", 
        scale_min: 1, 
        scale_max: 10
      )
      
      low_rating_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Low Rating Question",
        conditional_parent: parent_question,
        conditional_operator: "less_than",
        conditional_value: 5,
        show_if_condition_met: true
      )
      
      high_rating_question = Question.create!(
        survey_template: @survey_template,
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
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Root Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Conditional Question",
        conditional_parent: root_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      root_questions = @survey_template.questions.root_questions
      assert_includes root_questions, root_question
      assert_not_includes root_questions, conditional_question
    end

    test "conditional_questions scope should return questions with conditional parent" do
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      root_question = Question.create!(
        survey_template: @survey_template, 
        question_type: scale_type, 
        title: "Root Question", 
        scale_min: 1, 
        scale_max: 10
      )
      
      conditional_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Conditional Question",
        conditional_parent: root_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      conditional_questions = @survey_template.questions.conditional_questions
      assert_includes conditional_questions, conditional_question
      assert_not_includes conditional_questions, root_question
    end

    # Matrix Question Tests
    test "should have matrix parent association" do
      association = Question.reflect_on_association(:matrix_parent)
      assert_equal :belongs_to, association.macro
      assert_equal true, association.options[:optional]
      assert_equal 'Question', association.options[:class_name]
    end

    test "should have matrix sub-questions association" do
      association = Question.reflect_on_association(:matrix_sub_questions)
      assert_equal :has_many, association.macro
      assert_equal 'Question', association.options[:class_name]
      assert_equal 'matrix_parent_id', association.options[:foreign_key]
      assert_equal :destroy, association.options[:dependent]
    end

    test "should create valid matrix parent question" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_question = Question.new(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "¿Qué piensas del contenido del módulo?",
        is_matrix_question: true,
        order_position: 1
      )
      
      assert matrix_question.valid?
      assert matrix_question.is_matrix?
      assert matrix_question.matrix_scale?
    end

    test "matrix parent cannot have another parent" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Another Matrix",
        is_matrix_question: true
      )
      
      invalid_matrix = Question.new(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Invalid Matrix",
        is_matrix_question: true,
        matrix_parent: parent
      )
      
      assert_invalid invalid_matrix
      assert_validation_error invalid_matrix, :base
    end

    test "matrix questions cannot be conditional" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      scale_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rating",
        scale_min: 1,
        scale_max: 10
      )
      
      invalid_matrix = Question.new(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Invalid Matrix",
        is_matrix_question: true,
        conditional_parent: scale_question,
        conditional_operator: "less_than",
        conditional_value: 5
      )
      
      assert_invalid invalid_matrix
      assert_validation_error invalid_matrix, :base
    end

    test "matrix row should require matrix_row_text" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row = Question.new(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: nil
      )
      
      assert_invalid matrix_row
      assert_validation_error matrix_row, :matrix_row_text
    end

    test "matrix row cannot have its own options" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      # Add options to parent
      matrix_parent.options.create!(
        option_text: "1",
        option_value: "1",
        order_position: 1
      )
      
      matrix_row = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      # Try to add options to row (should fail validation)
      matrix_row.options.build(
        option_text: "Invalid",
        option_value: "invalid",
        order_position: 1
      )
      
      assert_invalid matrix_row
      assert_validation_error matrix_row, :base
    end

    test "matrix row must belong to same survey template as parent" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      other_template = SurveyTemplate.create!(name: "Other Template")
      
      matrix_parent = Question.create!(
        survey_template: other_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row = Question.new(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      assert_invalid matrix_row
      assert_validation_error matrix_row, :matrix_parent
    end

    test "effective_options should return parent options for matrix rows" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      # Add options to parent
      option1 = matrix_parent.options.create!(
        option_text: "1",
        option_value: "1",
        order_position: 1
      )
      option2 = matrix_parent.options.create!(
        option_text: "2",
        option_value: "2",
        order_position: 2
      )
      
      matrix_row = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      # Row should use parent's options
      effective_options = matrix_row.effective_options
      assert_includes effective_options, option1
      assert_includes effective_options, option2
      assert_equal 2, effective_options.count
    end

    test "is_matrix_row? should return true for matrix sub-questions" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      assert matrix_row.is_matrix_row?
      assert_not matrix_parent.is_matrix_row?
    end

    test "matrix_questions scope should return only matrix parent questions" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      regular_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Regular Question"
      )
      
      matrix_questions = @survey_template.questions.matrix_questions
      assert_includes matrix_questions, matrix_parent
      assert_not_includes matrix_questions, regular_question
    end

    test "matrix_rows scope should return only matrix sub-questions" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      matrix_rows = @survey_template.questions.matrix_rows
      assert_includes matrix_rows, matrix_row
      assert_not_includes matrix_rows, matrix_parent
    end

    test "non_matrix_questions scope should exclude matrix questions and rows" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row Title",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row Text"
      )
      
      regular_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Regular Question"
      )
      
      non_matrix = @survey_template.questions.non_matrix_questions
      assert_includes non_matrix, regular_question
      assert_not_includes non_matrix, matrix_parent
      assert_not_includes non_matrix, matrix_row
    end

    test "destroying matrix parent should destroy sub-questions" do
      matrix_scale_type = QuestionType.find_or_create_by(name: "matrix_scale") do |qt|
        qt.allows_options = true
        qt.allows_multiple_selections = false
      end
      
      matrix_parent = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Matrix Question",
        is_matrix_question: true
      )
      
      matrix_row1 = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row 1",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row 1 Text"
      )
      
      matrix_row2 = Question.create!(
        survey_template: @survey_template,
        question_type: matrix_scale_type,
        title: "Row 2",
        matrix_parent: matrix_parent,
        matrix_row_text: "Row 2 Text"
      )
      
      assert_difference('Question.count', -3) do
        matrix_parent.destroy!
      end
    end

    # Range Conditional Logic Tests
    test "should support range conditional logic for NPS Passives" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      # Create NPS question (0-10 scale)
      nps_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "How likely are you to recommend us?",
        order_position: 1,
        scale_min: 0,
        scale_max: 10
      )

      # Create question for NPS Passives (7-8 range)
      passives_question = Question.create!(
        survey_template: @survey_template,
        question_type: text_type,
        title: "What could we improve?",
        order_position: 2,
        conditional_parent: nps_question,
        conditional_logic_type: 'range',
        conditional_operator: 'greater_than_or_equal',
        conditional_value: 7,
        conditional_operator_2: 'less_than_or_equal',
        conditional_value_2: 8
      )

      assert passives_question.valid?
      assert passives_question.is_conditional?
      
      # Test range evaluation
      assert_not passives_question.evaluate_condition(6)  # Detractor
      assert passives_question.evaluate_condition(7)      # Passive
      assert passives_question.evaluate_condition(8)      # Passive  
      assert_not passives_question.evaluate_condition(9)  # Promoter
    end

    test "should support AND conditional logic" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rate our service",
        order_position: 1,
        scale_min: 1,
        scale_max: 10
      )

      # Create question that shows if score >= 5 AND score <= 7
      and_question = Question.create!(
        survey_template: @survey_template,
        question_type: text_type,
        title: "How can we improve?",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_logic_type: 'and',
        conditional_operator: 'greater_than_or_equal',
        conditional_value: 5,
        conditional_operator_2: 'less_than_or_equal',
        conditional_value_2: 7
      )

      assert and_question.valid?
      
      # Test AND logic
      assert_not and_question.evaluate_condition(4)  # Fails first condition
      assert and_question.evaluate_condition(5)      # Passes both
      assert and_question.evaluate_condition(6)      # Passes both
      assert and_question.evaluate_condition(7)      # Passes both
      assert_not and_question.evaluate_condition(8)  # Fails second condition
    end

    test "should support OR conditional logic" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rate our service",
        order_position: 1,
        scale_min: 1,
        scale_max: 10
      )

      # Create question that shows if score <= 3 OR score >= 9
      or_question = Question.create!(
        survey_template: @survey_template,
        question_type: text_type,
        title: "Tell us more about your experience",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_logic_type: 'or',
        conditional_operator: 'less_than_or_equal',
        conditional_value: 3,
        conditional_operator_2: 'greater_than_or_equal',
        conditional_value_2: 9
      )

      assert or_question.valid?
      
      # Test OR logic
      assert or_question.evaluate_condition(1)       # Passes first condition
      assert or_question.evaluate_condition(3)       # Passes first condition
      assert_not or_question.evaluate_condition(5)   # Fails both conditions
      assert_not or_question.evaluate_condition(7)   # Fails both conditions
      assert or_question.evaluate_condition(9)       # Passes second condition
      assert or_question.evaluate_condition(10)      # Passes second condition
    end

    test "should validate complex conditional logic requires second condition" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rate our service",
        order_position: 1,
        scale_min: 1,
        scale_max: 10
      )

      # Missing second condition for range logic
      question = Question.new(
        survey_template: @survey_template,
        question_type: text_type,
        title: "Follow-up question",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_logic_type: 'range',
        conditional_operator: 'greater_than_or_equal',
        conditional_value: 7
        # Missing conditional_operator_2 and conditional_value_2
      )

      assert_not question.valid?
      assert_includes question.errors[:conditional_operator_2], 'is required for complex conditional logic'
      assert_includes question.errors[:conditional_value_2], 'is required for complex conditional logic'
    end

    test "should validate range logic values are in correct order" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rate our service",
        order_position: 1,
        scale_min: 1,
        scale_max: 10
      )

      # Invalid range: first value > second value
      question = Question.new(
        survey_template: @survey_template,
        question_type: text_type,
        title: "Follow-up question",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_logic_type: 'range',
        conditional_operator: 'greater_than_or_equal',
        conditional_value: 8,
        conditional_operator_2: 'less_than_or_equal',
        conditional_value_2: 7  # Invalid: 8 > 7
      )

      assert_not question.valid?
      assert_includes question.errors[:conditional_value_2], 'must be greater than or equal to first conditional value for range logic'
    end

    test "should validate conditional values are within parent scale range for complex logic" do
      # Create question types
      scale_type = QuestionType.find_or_create_by(name: "scale") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end
      
      text_type = QuestionType.find_or_create_by(name: "text") do |qt|
        qt.allows_options = false
        qt.allows_multiple_selections = false
      end

      parent_question = Question.create!(
        survey_template: @survey_template,
        question_type: scale_type,
        title: "Rate our service",
        order_position: 1,
        scale_min: 1,
        scale_max: 10
      )

      # Second conditional value outside parent scale range
      question = Question.new(
        survey_template: @survey_template,
        question_type: text_type,
        title: "Follow-up question",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_logic_type: 'range',
        conditional_operator: 'greater_than_or_equal',
        conditional_value: 7,
        conditional_operator_2: 'less_than_or_equal',
        conditional_value_2: 15  # Invalid: outside 1-10 range
      )

      assert_not question.valid?
      assert_includes question.errors[:conditional_value_2], 'must be within parent question scale range'
    end
  end
end