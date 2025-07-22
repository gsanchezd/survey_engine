require "test_helper"

module SurveyEngine
  class OptionTest < ActiveSupport::TestCase
    def setup
      @survey = Survey.create!(title: "Test Survey")
      @question_type = QuestionType.create!(name: "single_choice", allows_options: true, allows_multiple_selections: false)
      @question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
    end

    # Validations
    test "should require option_text" do
      option = Option.new(question: @question)
      assert_not option.valid?
      assert_includes option.errors[:option_text], "no puede estar en blanco"
    end

    test "should limit option_text length" do
      option = Option.new(
        question: @question,
        option_text: "a" * 256,
        option_value: "test"
      )
      assert_not option.valid?
      assert_includes option.errors[:option_text], "es demasiado largo"
    end

    test "should require option_value" do
      option = Option.new(question: @question, option_text: "Test")
      assert_not option.valid?
      assert_includes option.errors[:option_value], "no puede estar en blanco"
    end

    test "should limit option_value length" do
      option = Option.new(
        question: @question,
        option_text: "Test",
        option_value: "a" * 101
      )
      assert_not option.valid?
      assert_includes option.errors[:option_value], "es demasiado largo"
    end

    test "should require order_position" do
      option = Option.new(question: @question, option_text: "Test", option_value: "test")
      option.order_position = nil
      assert_not option.valid?
      assert_includes option.errors[:order_position], "no puede estar en blanco"
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

      assert_not duplicate.valid?
      assert_includes duplicate.errors[:order_position], "ya está en uso"
    end

    test "should allow same order_position in different questions" do
      other_question = Question.create!(
        survey: @survey,
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
      assert_not option.valid?
      assert_includes option.errors[:is_other], "no está incluido en la lista"

      option.is_other = false
      option.is_exclusive = nil
      assert_not option.valid?
      assert_includes option.errors[:is_exclusive], "no está incluido en la lista"

      option.is_exclusive = false
      option.is_active = nil
      assert_not option.valid?
      assert_includes option.errors[:is_active], "no está incluido en la lista"
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
      assert_includes duplicate_other.errors[:is_other], 'solo puede haber una opción "Otro" por pregunta'
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
      assert_includes option.errors[:is_exclusive], 'no puede ser exclusiva y "Otro" al mismo tiempo'
    end

    # Associations
    test "should belong to question" do
      association = Option.reflect_on_association(:question)
      assert_equal :belongs_to, association.macro
    end

    test "should have many answer_options" do
      association = Option.reflect_on_association(:answer_options)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

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