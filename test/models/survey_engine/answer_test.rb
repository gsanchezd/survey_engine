require "test_helper"

module SurveyEngine
  class AnswerTest < ActiveSupport::TestCase
    def setup
      @survey_template = SurveyTemplate.create!(name: "Test Template #{SecureRandom.hex(4)}", is_active: true)
      @survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}", survey_template: @survey_template)
      @participant = Participant.create!(survey: @survey, email: "test@example.com")
      @response = Response.create!(survey: @survey, participant: @participant)
      @question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      @question = Question.create!(
        survey_template: @survey_template,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
    end

    # Basic validations
    test "should require response" do
      answer = Answer.new(question: @question, text_answer: "Test")
      assert_invalid answer
      assert_validation_error answer, :response_id
    end

    test "should require question" do
      answer = Answer.new(response: @response, text_answer: "Test")
      assert_invalid answer
      assert_validation_error answer, :question_id
    end

    test "should require unique response-question combination" do
      Answer.create!(response: @response, question: @question, text_answer: "First answer")
      
      duplicate = Answer.new(response: @response, question: @question, text_answer: "Second answer")
      assert_invalid duplicate
      assert_validation_error duplicate, :response_id
    end

    # Associations
    test "should belong to response" do
      association = Answer.reflect_on_association(:response)
      assert_equal :belongs_to, association.macro
    end

    test "should belong to question" do
      association = Answer.reflect_on_association(:question)
      assert_equal :belongs_to, association.macro
    end

    test "should have many answer_options" do
      association = Answer.reflect_on_association(:answer_options)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # Content validation
    test "should require some form of content" do
      answer = Answer.new(response: @response, question: @question)
      assert_invalid answer
      assert_validation_error answer, :base
    end

    test "should accept text answer" do
      answer = Answer.new(response: @response, question: @question, text_answer: "Test answer")
      assert answer.valid?
    end

    test "should accept numeric answer" do
      answer = Answer.new(response: @response, question: @question, numeric_answer: 42)
      assert answer.valid?
    end

    test "should accept boolean answer" do
      answer = Answer.new(response: @response, question: @question, boolean_answer: true)
      assert answer.valid?
    end

    # Instance methods
    test "has_content? should detect content" do
      answer = Answer.create!(response: @response, question: @question, text_answer: "Test")
      assert answer.has_content?
      
      empty_answer = Answer.new(response: @response, question: @question)
      assert_not empty_answer.has_content?
    end

    test "display_value should show appropriate value" do
      text_answer = Answer.create!(response: @response, question: @question, text_answer: "Hello")
      assert_equal "Hello", text_answer.display_value
      
      # Create new question/response for numeric test
      new_participant = Participant.create!(survey: @survey, email: "numeric@example.com") 
      new_response = Response.create!(survey: @survey, participant: new_participant)
      numeric_answer = Answer.create!(response: new_response, question: @question, numeric_answer: 42)
      assert_equal "42", numeric_answer.display_value
    end

    test "should set answered_at on creation" do
      freeze_time = Time.current
      travel_to freeze_time do
        answer = Answer.create!(response: @response, question: @question, text_answer: "Test")
        assert_in_delta freeze_time.to_f, answer.answered_at.to_f, 1
      end
    end

    # Survey consistency validation
    test "should validate response and question belong to same survey" do
      other_template = SurveyTemplate.create!(name: "Other Template #{SecureRandom.hex(4)}", is_active: true)
      other_survey = Survey.create!(title: "Other Survey #{SecureRandom.hex(4)}", survey_template: other_template)
      other_question = Question.create!(
        survey_template: other_template,
        question_type: @question_type,
        title: "Other Question",
        order_position: 1
      )
      
      answer = Answer.new(response: @response, question: other_question, text_answer: "Test")
      assert_invalid answer
      assert_validation_error answer, :base
    end
  end
end