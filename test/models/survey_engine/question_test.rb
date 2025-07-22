require "test_helper"

module SurveyEngine
  class QuestionTest < ActiveSupport::TestCase
    def setup
      @survey = Survey.create!(title: "Test Survey")
      @question_type = QuestionType.create!(name: "text", allows_options: false, allows_multiple_selections: false)
    end

    # Validations
    test "should require title" do
      question = Question.new(survey: @survey, question_type: @question_type)
      assert_not question.valid?
      assert_includes question.errors[:title], "no puede estar en blanco"
    end

    test "should limit title length" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "a" * 501
      )
      assert_not question.valid?
      assert_includes question.errors[:title], "es demasiado largo"
    end

    test "should limit description length" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Valid Title",
        description: "a" * 1001
      )
      assert_not question.valid?
      assert_includes question.errors[:description], "es demasiado largo"
    end

    test "should require order_position" do
      question = Question.new(survey: @survey, question_type: @question_type, title: "Test")
      question.order_position = nil
      assert_not question.valid?
      assert_includes question.errors[:order_position], "no puede estar en blanco"
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

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:order_position], "ya está en uso"
    end

    test "should allow same order_position in different surveys" do
      other_survey = Survey.create!(title: "Other Survey")
      
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
      assert_not question.valid?
      assert_includes question.errors[:is_required], "no está incluido en la lista"

      question.is_required = true
      question.allow_other = nil
      assert_not question.valid?
      assert_includes question.errors[:allow_other], "no está incluido en la lista"

      question.allow_other = false
      question.randomize_options = nil
      assert_not question.valid?
      assert_includes question.errors[:randomize_options], "no está incluido en la lista"
    end

    test "should validate positive max_characters" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        max_characters: -1
      )
      assert_not question.valid?
      assert_includes question.errors[:max_characters], "debe ser mayor que 0"
    end

    test "should validate non-negative min_selections" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        min_selections: -1
      )
      assert_not question.valid?
      assert_includes question.errors[:min_selections], "debe ser mayor o igual a 0"
    end

    test "should validate positive max_selections" do
      question = Question.new(
        survey: @survey,
        question_type: @question_type,
        title: "Test",
        max_selections: 0
      )
      assert_not question.valid?
      assert_includes question.errors[:max_selections], "debe ser mayor que 0"
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

    test "should have many answers" do
      association = Question.reflect_on_association(:answers)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

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
  end
end