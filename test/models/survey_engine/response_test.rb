require "test_helper"

module SurveyEngine
  class ResponseTest < ActiveSupport::TestCase
    def setup
      @survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      @participant = Participant.create!(survey: @survey, email: "test@example.com")
      @question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      @question = Question.create!(
        survey: @survey,
        question_type: @question_type,
        title: "Test Question",
        order_position: 1
      )
    end

    # Validations
    test "should require survey" do
      response = Response.new(participant: @participant)
      assert_not response.valid?
      assert_includes response.errors[:survey_id], "can't be blank"
    end

    test "should require participant" do
      response = Response.new(survey: @survey)
      assert_not response.valid?
      assert_includes response.errors[:participant_id], "can't be blank"
    end

    test "should validate participant belongs to survey" do
      other_survey = Survey.create!(title: "Other Survey #{SecureRandom.hex(4)}")
      other_participant = Participant.create!(survey: other_survey, email: "other@example.com")
      
      response = Response.new(survey: @survey, participant: other_participant)
      assert_not response.valid?
      assert_includes response.errors[:participant], "must belong to the same survey"
    end

    test "should allow participant from same survey" do
      response = Response.new(survey: @survey, participant: @participant)
      assert response.valid?
    end

    # Associations
    test "should belong to survey" do
      association = Response.reflect_on_association(:survey)
      assert_equal :belongs_to, association.macro
    end

    test "should belong to participant" do
      association = Response.reflect_on_association(:participant)
      assert_equal :belongs_to, association.macro
    end

    # test "should have many answers" do
    #   association = Response.reflect_on_association(:answers)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # Scopes
    test "should have completed scope" do
      incomplete_response = Response.create!(survey: @survey, participant: @participant)
      completed_response = Response.create!(
        survey: @survey, 
        participant: Participant.create!(survey: @survey, email: "completed@example.com"),
        completed_at: Time.current
      )

      assert_includes Response.completed, completed_response
      assert_not_includes Response.completed, incomplete_response
    end

    test "should have ordering scopes" do
      response1 = Response.create!(survey: @survey, participant: @participant)
      
      travel 1.hour do
        response2 = Response.create!(
          survey: @survey, 
          participant: Participant.create!(survey: @survey, email: "second@example.com")
        )
        
        # Recent scope should have newer first
        assert_equal [response2, response1], Response.recent.to_a
      end
    end

    # Instance methods
    test "should check completion status" do
      response = Response.create!(survey: @survey, participant: @participant)
      
      assert_not response.completed?
      
      response.complete!
      assert response.completed?
      assert_not_nil response.completed_at
    end

    test "complete! should set completed_at" do
      response = Response.create!(survey: @survey, participant: @participant)
      
      freeze_time = Time.current
      travel_to freeze_time do
        response.complete!
      end
      
      assert_in_delta freeze_time.to_f, response.completed_at.to_f, 1
    end

    test "completion_time should calculate duration" do
      response = Response.create!(survey: @survey, participant: @participant)
      
      travel 1.hour do
        response.complete!
      end
      
      assert_in_delta 1.hour, response.completion_time, 1.second
    end

    test "completion_time should return nil for incomplete responses" do
      response = Response.create!(survey: @survey, participant: @participant)
      assert_nil response.completion_time
    end

    # test "should count answers" do
    #   response = Response.create!(survey: @survey, participant: @participant)
    #   assert_equal 0, response.answers_count
    # end

    # test "completion_percentage should calculate percentage of answered questions" do
    #   # Create second question
    #   second_question = Question.create!(
    #     survey: @survey,
    #     question_type: @question_type,
    #     title: "Second Question", 
    #     order_position: 2
    #   )
    #   
    #   response = Response.create!(survey: @survey, participant: @participant)
    #   
    #   # 0% completion initially
    #   assert_equal 0.0, response.completion_percentage
    #   
    #   # Note: We'll test with actual answers once Answer model is created
    # end

    # test "completion_percentage should handle surveys with no questions" do
    #   empty_survey = Survey.create!(title: "Empty Survey #{SecureRandom.hex(4)}")
    #   empty_participant = Participant.create!(survey: empty_survey, email: "empty@example.com")
    #   response = Response.create!(survey: empty_survey, participant: empty_participant)
    #   
    #   assert_equal 0, response.completion_percentage
    # end

    # test "should find unanswered questions" do
    #   second_question = Question.create!(
    #     survey: @survey,
    #     question_type: @question_type,
    #     title: "Second Question",
    #     order_position: 2
    #   )
    #   
    #   response = Response.create!(survey: @survey, participant: @participant)
    #   
    #   unanswered = response.unanswered_questions
    #   assert_includes unanswered, @question
    #   assert_includes unanswered, second_question
    #   assert_equal 2, unanswered.count
    # end

    # test "answer_for_question should return nil when no answer exists" do
    #   response = Response.create!(survey: @survey, participant: @participant)
    #   assert_nil response.answer_for_question(@question)
    # end

    # Class methods
    test "completion_rate_by_day should group by completion date" do
      today = Date.current
      
      travel_to today do
        response1 = Response.create!(survey: @survey, participant: @participant)
        response1.complete!
      end
      
      travel_to today + 1.day do
        participant2 = Participant.create!(survey: @survey, email: "day2@example.com")
        response2 = Response.create!(survey: @survey, participant: participant2)
        response2.complete!
      end
      
      rates = Response.completion_rate_by_day
      assert_equal 1, rates[today.to_s]
      assert_equal 1, rates[(today + 1.day).to_s]
    end
  end
end