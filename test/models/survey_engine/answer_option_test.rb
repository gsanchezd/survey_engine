require "test_helper"

module SurveyEngine
  class AnswerOptionTest < ActiveSupport::TestCase
    def setup
      @survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      @participant = Participant.create!(survey: @survey, email: "test@example.com")
      @response = Response.create!(survey: @survey, participant: @participant)
      @question_type = QuestionType.create!(name: "single_choice_#{SecureRandom.hex(4)}", allows_options: true, allows_multiple_selections: false)
      @question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
      @option = Option.create!(
        question: @question,
        option_text: "Test Option",
        option_value: "test",
        order_position: 1
      )
      @answer = Answer.new(response: @response, question: @question)
      @answer.save!(validate: false) # Skip validation that requires content
    end

    # Basic validations
    test "should require answer" do
      answer_option = AnswerOption.new(option: @option)
      assert_invalid answer_option
      assert_validation_error answer_option, :answer_id
    end

    test "should require option" do
      answer_option = AnswerOption.new(answer: @answer)
      assert_invalid answer_option
      assert_validation_error answer_option, :option_id
    end

    test "should require unique answer-option combination" do
      AnswerOption.create!(answer: @answer, option: @option)
      
      duplicate = AnswerOption.new(answer: @answer, option: @option)
      assert_invalid duplicate
      assert_validation_error duplicate, :answer_id
    end

    # Associations
    test "should belong to answer" do
      association = AnswerOption.reflect_on_association(:answer)
      assert_equal :belongs_to, association.macro
    end

    test "should belong to option" do
      association = AnswerOption.reflect_on_association(:option)
      assert_equal :belongs_to, association.macro
    end

    # Delegations
    test "should delegate option properties" do
      answer_option = AnswerOption.create!(answer: @answer, option: @option)
      
      assert_equal @option.option_text, answer_option.option_text
      assert_equal @option.option_value, answer_option.option_value
      assert_equal @option.is_other?, answer_option.is_other?
      assert_equal @option.is_exclusive?, answer_option.is_exclusive?
    end

    # Cross-validation
    test "should validate option belongs to same question" do
      other_question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Other Question",
        order_position: 2
      )
      other_option = Option.create!(
        question: other_question,
        option_text: "Other Option",
        option_value: "other",
        order_position: 1
      )
      
      answer_option = AnswerOption.new(answer: @answer, option: other_option)
      assert_invalid answer_option
      assert_validation_error answer_option, :option
    end

    test "should allow option from same question" do
      answer_option = AnswerOption.new(answer: @answer, option: @option)
      assert answer_option.valid?
    end

    # Scopes
    test "should have recent scope" do
      answer_option1 = AnswerOption.create!(answer: @answer, option: @option)
      
      travel 1.hour do
        second_option = Option.create!(
          question: @question,
          option_text: "Second Option",
          option_value: "second",
          order_position: 2
        )
        answer_option2 = AnswerOption.create!(answer: @answer, option: second_option)
        
        # Recent scope should have newer first
        assert_equal answer_option2, AnswerOption.recent.first
      end
    end
  end
end