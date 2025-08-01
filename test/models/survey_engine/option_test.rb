require "test_helper"

module SurveyEngine
  class OptionTest < ActiveSupport::TestCase
    def setup
      @survey_template = SurveyTemplate.create!(name: "Test Template #{SecureRandom.hex(4)}")
      @survey = Survey.create!(
        title: "Test Survey #{SecureRandom.hex(4)}",
        survey_template: @survey_template
      )
      @question_type = QuestionType.create!(name: "single_choice_#{SecureRandom.hex(4)}", allows_options: true, allows_multiple_selections: false)
      @question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
    end

    # Validations
    test "should require option_text" do
      option = Option.new(question: @question)
      assert_invalid option
      assert_validation_error option, :option_text
    end

    test "should limit option_text length" do
      option = Option.new(
        question: @question,
        option_text: "a" * 256,
        option_value: "test"
      )
      assert_invalid option
      assert_validation_error option, :option_text
    end

    test "should require option_value" do
      option = Option.new(question: @question, option_text: "Test", order_position: 1)
      # Bypass the callback that sets default option_value
      option.define_singleton_method(:set_default_option_value) { nil }
      option.option_value = nil
      assert_invalid option
      assert_validation_error option, :option_value
    end

    test "should limit option_value length" do
      option = Option.new(
        question: @question,
        option_text: "Test",
        option_value: "a" * 101
      )
      assert_invalid option
      assert_validation_error option, :option_value
    end

    test "should require order_position" do
      option = Option.new(question: @question, option_text: "Test", option_value: "test")
      # Bypass the callback by setting order_position after initialization
      option.define_singleton_method(:set_next_order_position) { nil }
      option.order_position = nil
      assert_invalid option
      assert_validation_error option, :order_position
    end

    test "should require unique order_position within question" do
      Option.create!(
        question: @question,
        option_text: "First Option",
        option_value: "first",
        order_position: 1
      )

      duplicate = Option.new(
        question: @question,
        option_text: "Second Option",
        option_value: "second",
        order_position: 1
      )

      assert_invalid duplicate
      assert_validation_error duplicate, :order_position
    end

    test "should allow same order_position in different questions" do
      other_question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Other Question",
        order_position: 2
      )

      Option.create!(
        question: @question,
        option_text: "First Option",
        option_value: "first",
        order_position: 1
      )

      option_in_other_question = Option.new(
        question: other_question,
        option_text: "Other Option",
        option_value: "other",
        order_position: 1
      )

      assert option_in_other_question.valid?
    end

    test "should require boolean values for flags" do
      option = Option.new(question: @question, option_text: "Test", option_value: "test")

      option.is_other = nil
      assert_invalid option
      assert_validation_error option, :is_other

      option.is_other = false
      option.is_exclusive = nil
      assert_invalid option
      assert_validation_error option, :is_exclusive

      option.is_exclusive = false
      option.is_active = nil
      assert_invalid option
      assert_validation_error option, :is_active
    end

    test "should validate only one other option per question" do
      Option.create!(
        question: @question,
        option_text: "Other",
        option_value: "other",
        order_position: 1,
        is_other: true
      )

      duplicate_other = Option.new(
        question: @question,
        option_text: "Another Other",
        option_value: "another_other",
        order_position: 2,
        is_other: true
      )

      assert_not duplicate_other.valid?
      assert_includes duplicate_other.errors[:is_other], 'can only have one "Other" option per question'
    end

    test "should not allow both is_other and is_exclusive" do
      option = Option.new(
        question: @question,
        option_text: "Test",
        option_value: "test",
        order_position: 1,
        is_other: true,
        is_exclusive: true
      )

      assert_not option.valid?
      assert_includes option.errors[:is_exclusive], 'cannot be both exclusive and "Other" at the same time'
    end

    # Associations
    test "should belong to question" do
      association = Option.reflect_on_association(:question)
      assert_equal :belongs_to, association.macro
    end

    # test "should have many answer_options" do
    #   association = Option.reflect_on_association(:answer_options)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # Default values
    test "should have default values" do
      option = Option.new(question: @question, option_text: "Test", option_value: "test")
      assert_equal false, option.is_other
      assert_equal false, option.is_exclusive
      assert_equal true, option.is_active
    end

    test "should set default option_value if not provided" do
      option = Option.new(question: @question, option_text: "Test Option", order_position: 1)
      option.valid? # Trigger callbacks
      # This tests the set_default_option_value callback
      assert_not_nil option.option_value
    end
  end
end