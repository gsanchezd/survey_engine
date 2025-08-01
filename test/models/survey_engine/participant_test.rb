require "test_helper"

module SurveyEngine
  class ParticipantTest < ActiveSupport::TestCase
    def setup
      @survey_template = SurveyTemplate.create!(name: "Test Template #{SecureRandom.hex(4)}")
      @survey = Survey.create!(
        title: "Test Survey #{SecureRandom.hex(4)}",
        survey_template: @survey_template
      )
    end

    # Validations
    test "should require email" do
      participant = Participant.new(survey: @survey)
      assert_invalid participant
      assert_validation_error participant, :email
    end

    test "should validate email format" do
      participant = Participant.new(survey: @survey, email: "invalid-email")
      assert_invalid participant
      assert_validation_error participant, :email
    end

    test "should require status" do
      participant = Participant.new(survey: @survey, email: "test@example.com")
      participant.status = nil
      assert_invalid participant
      assert_validation_error participant, :status
    end

    test "should validate status values through enum" do
      participant = Participant.new(survey: @survey, email: "test@example.com")
      
      # Valid statuses should work
      participant.status = "invited"
      assert participant.status == "invited"
      
      participant.status = "completed"
      assert participant.status == "completed"
      
      # Invalid status should raise ArgumentError (handled by enum)
      assert_raises(ArgumentError) do
        participant.status = "invalid"
      end
    end

    test "should require unique email per survey" do
      Participant.create!(survey: @survey, email: "test@example.com")
      
      duplicate = Participant.new(survey: @survey, email: "test@example.com")
      assert_invalid duplicate
      assert_validation_error duplicate, :email
    end

    test "should allow same email for different surveys" do
      other_template = SurveyTemplate.create!(name: "Other Template #{SecureRandom.hex(4)}")
      other_survey = Survey.create!(
        title: "Other Survey #{SecureRandom.hex(4)}",
        survey_template: other_template
      )
      
      Participant.create!(survey: @survey, email: "test@example.com")
      
      participant_in_other_survey = Participant.new(survey: other_survey, email: "test@example.com")
      assert participant_in_other_survey.valid?
    end

    # Associations
    test "should belong to survey" do
      association = Participant.reflect_on_association(:survey)
      assert_equal :belongs_to, association.macro
    end

    test "should have one response" do
      association = Participant.reflect_on_association(:response)
      assert_equal :has_one, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # Enums and status
    test "should have default status of invited" do
      participant = Participant.new(survey: @survey, email: "test@example.com")
      assert_equal "invited", participant.status
    end

    test "should support status enum" do
      participant = Participant.create!(survey: @survey, email: "test@example.com")
      
      assert participant.invited?
      assert_not participant.completed?
      
      participant.completed!
      assert participant.completed?
      assert_not participant.invited?
    end

    # Scopes
    test "should have scopes for status" do
      invited_participant = Participant.create!(survey: @survey, email: "invited@example.com")
      completed_participant = Participant.create!(survey: @survey, email: "completed@example.com", status: "completed")
      
      assert_includes Participant.invited, invited_participant
      assert_not_includes Participant.invited, completed_participant
      
      assert_includes Participant.completed, completed_participant
      assert_not_includes Participant.completed, invited_participant
      
      assert_includes Participant.pending, invited_participant
      assert_not_includes Participant.pending, completed_participant
    end

    # Instance methods
    test "should check completion status" do
      participant = Participant.create!(survey: @survey, email: "test@example.com")
      
      assert participant.pending?
      assert_not participant.completed?
      
      participant.complete!
      assert participant.completed?
      assert_not participant.pending?
    end

    test "complete! should update status and completed_at" do
      participant = Participant.create!(survey: @survey, email: "test@example.com")
      
      freeze_time = Time.current
      travel_to freeze_time do
        participant.complete!
      end
      
      assert_equal "completed", participant.status
      # Allow for small time differences due to precision
      assert_in_delta freeze_time.to_f, participant.completed_at.to_f, 1
    end

    test "completion_time should calculate time difference" do
      participant = Participant.create!(survey: @survey, email: "test@example.com")
      
      # Simulate completion 1 hour later
      travel 1.hour do
        participant.complete!
      end
      
      assert_in_delta 1.hour, participant.completion_time, 1.second
    end

    test "completion_time should return nil for incomplete participants" do
      participant = Participant.create!(survey: @survey, email: "test@example.com")
      assert_nil participant.completion_time
    end

    # Class methods
    test "completion_rate_for_survey should calculate percentage" do
      # Create 3 invited, 2 completed
      3.times do |i|
        Participant.create!(survey: @survey, email: "invited#{i}@example.com")
      end
      
      2.times do |i|
        Participant.create!(survey: @survey, email: "completed#{i}@example.com", status: "completed")
      end
      
      rate = Participant.completion_rate_for_survey(@survey)
      assert_equal 40.0, rate # 2 out of 5 = 40%
    end

    test "completion_rate_for_survey should return 0 for no participants" do
      empty_template = SurveyTemplate.create!(name: "Empty Template #{SecureRandom.hex(4)}")
      empty_survey = Survey.create!(
        title: "Empty Survey #{SecureRandom.hex(4)}",
        survey_template: empty_template
      )
      rate = Participant.completion_rate_for_survey(empty_survey)
      assert_equal 0, rate
    end
  end
end