require "test_helper"

module SurveyEngine
  class OptionConditionalTest < ActiveSupport::TestCase
    def setup
      @template = SurveyTemplate.create!(name: "Option Conditional Test")
      @single_choice_type = QuestionType.find_by(name: 'single_choice')
      @text_type = QuestionType.find_by(name: 'text')
    end

    test "option conditional question shows when trigger option is selected" do
      # Create parent question with Yes/No options
      parent_question = Question.create!(
        survey_template: @template,
        question_type: @single_choice_type,
        title: "Do you have children?",
        order_position: 1
      )

      yes_option = Option.create!(
        question: parent_question,
        option_text: "Yes",
        option_value: "yes",
        order_position: 1
      )

      no_option = Option.create!(
        question: parent_question,
        option_text: "No", 
        option_value: "no",
        order_position: 2
      )

      # Create conditional question that shows when "Yes" is selected
      # Skip validation during creation since we'll add the options after
      conditional_question = Question.new(
        survey_template: @template,
        question_type: @text_type,
        title: "How many children do you have?",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_type: "option",
        show_if_condition_met: true
      )
      conditional_question.save!(validate: false)

      # Link the "Yes" option to trigger the conditional question
      QuestionConditionalOption.create!(
        question: conditional_question,
        option: yes_option
      )

      # Now validate that everything is correct
      assert conditional_question.valid?, "Conditional question should be valid after adding options"

      # Create a survey and participant
      survey = Survey.create!(
        survey_template: @template,
        title: "Test Survey",
        uuid: SecureRandom.uuid
      )

      participant = Participant.create!(
        survey: survey,
        email: "test@example.com"
      )

      response = Response.create!(
        survey: survey,
        participant: participant
      )

      # Test: Answer "Yes" - conditional question should show
      yes_answer = Answer.new(
        response: response,
        question: parent_question
      )
      yes_answer.answer_options.build(option: yes_option)
      yes_answer.save!

      assert conditional_question.should_show?(yes_answer), "Conditional question should show when 'Yes' is selected"

      # Test: Answer "No" - conditional question should NOT show
      # Create a different response for the "No" test
      participant_2 = Participant.create!(survey: survey, email: "test2@example.com")
      response_2 = Response.create!(survey: survey, participant: participant_2)
      
      no_answer = Answer.new(
        response: response_2,
        question: parent_question
      )
      no_answer.answer_options.build(option: no_option)
      no_answer.save!

      assert_not conditional_question.should_show?(no_answer), "Conditional question should NOT show when 'No' is selected"
    end

    test "option conditional question validation" do
      parent_question = Question.create!(
        survey_template: @template,
        question_type: @single_choice_type,
        title: "Parent Question",
        order_position: 1
      )

      # Test: Conditional question must specify at least one option
      conditional_question = Question.build(
        survey_template: @template,
        question_type: @text_type,
        title: "Conditional Question",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_type: "option"
      )

      assert_not conditional_question.valid?
      assert_includes conditional_question.errors.full_messages, "must specify at least one option to trigger the conditional question"
    end

    test "multiple trigger options work correctly" do
      # Create parent question with multiple options
      parent_question = Question.create!(
        survey_template: @template,
        question_type: @single_choice_type,
        title: "What's your favorite color?",
        order_position: 1
      )

      red_option = Option.create!(question: parent_question, option_text: "Red", option_value: "red", order_position: 1)
      blue_option = Option.create!(question: parent_question, option_text: "Blue", option_value: "blue", order_position: 2)  
      green_option = Option.create!(question: parent_question, option_text: "Green", option_value: "green", order_position: 3)

      # Create conditional question that shows for Red OR Blue
      # Skip validation during creation since we'll add the options after
      conditional_question = Question.new(
        survey_template: @template,
        question_type: @text_type,
        title: "Why do you like that color?",
        order_position: 2,
        conditional_parent: parent_question,
        conditional_type: "option",
        show_if_condition_met: true
      )
      conditional_question.save!(validate: false)

      # Link both Red and Blue options to trigger the conditional
      QuestionConditionalOption.create!(question: conditional_question, option: red_option)
      QuestionConditionalOption.create!(question: conditional_question, option: blue_option)

      # Validate everything is correct
      assert conditional_question.valid?, "Conditional question should be valid after adding options"

      # Create response setup
      survey = Survey.create!(survey_template: @template, title: "Test Survey", uuid: SecureRandom.uuid)
      participant = Participant.create!(survey: survey, email: "test@example.com")
      response = Response.create!(survey: survey, participant: participant)

      # Test Red selection - should show
      red_answer = Answer.new(response: response, question: parent_question)
      red_answer.answer_options.build(option: red_option)
      red_answer.save!
      assert conditional_question.should_show?(red_answer), "Should show for Red"

      # Test Blue selection - should show
      participant_2 = Participant.create!(survey: survey, email: "test2@example.com")
      response_2 = Response.create!(survey: survey, participant: participant_2)
      blue_answer = Answer.new(response: response_2, question: parent_question)
      blue_answer.answer_options.build(option: blue_option)
      blue_answer.save!
      assert conditional_question.should_show?(blue_answer), "Should show for Blue"

      # Test Green selection - should NOT show
      participant_3 = Participant.create!(survey: survey, email: "test3@example.com")
      response_3 = Response.create!(survey: survey, participant: participant_3)
      green_answer = Answer.new(response: response_3, question: parent_question)
      green_answer.answer_options.build(option: green_option)
      green_answer.save!
      assert_not conditional_question.should_show?(green_answer), "Should NOT show for Green"
    end
  end
end