require "test_helper"

module SurveyEngine
  class SurveyTest < ActiveSupport::TestCase
    def setup
      @template = SurveyTemplate.create!(name: "Test Template")
    end

    # Validations
    test "should require title" do
      survey = Survey.new(survey_template: @template)
      assert_invalid survey
      assert_validation_error survey, :title
    end

    test "should limit title length" do
      survey = Survey.new(title: "a" * 256, survey_template: @template)
      assert_invalid survey
      assert_validation_error survey, :title
    end

    test "should require survey_template" do
      survey = Survey.new(title: "Valid Title")
      assert_invalid survey
      assert_validation_error survey, :survey_template
    end

    test "should be valid with valid attributes" do
      survey = Survey.new(title: "Test", survey_template: @template)
      assert survey.valid?
    end

    test "should require is_active boolean" do
      survey = Survey.new(title: "Test", survey_template: @template)
      survey.is_active = nil
      assert_invalid survey
      assert_validation_error survey, :is_active
    end

    test "should require global boolean" do
      survey = Survey.new(title: "Test", survey_template: @template)
      survey.global = nil
      assert_invalid survey
      assert_validation_error survey, :global
    end

    test "should belong to survey_template" do
      association = Survey.reflect_on_association(:survey_template)
      assert_equal :belongs_to, association.macro
    end

    # Associations  
    test "should have many questions through template" do
      association = Survey.reflect_on_association(:questions)
      assert_equal :has_many, association.macro
      assert_equal :questions, association.source_reflection.name
    end

    test "should have many participants" do
      association = Survey.reflect_on_association(:participants)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    test "should have many responses" do
      association = Survey.reflect_on_association(:responses)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # Scopes
    test "should have active scope" do
      active_survey = Survey.create!(title: "Active Survey", survey_template: @template, is_active: true)
      inactive_survey = Survey.create!(title: "Inactive Survey", survey_template: @template, is_active: false)
      
      active_surveys = Survey.active
      assert_includes active_surveys, active_survey
      assert_not_includes active_surveys, inactive_survey
    end

    test "should have global scope" do
      global_survey = Survey.create!(title: "Global Survey", survey_template: @template, global: true)
      local_survey = Survey.create!(title: "Local Survey", survey_template: @template, global: false)
      
      global_surveys = Survey.global_surveys
      assert_includes global_surveys, global_survey
      assert_not_includes global_surveys, local_survey
    end

    # Instance methods
    test "should check if active" do
      active_survey = Survey.create!(title: "Active Survey", survey_template: @template, is_active: true)
      inactive_survey = Survey.create!(title: "Inactive Survey", survey_template: @template, is_active: false)
      
      assert active_survey.active?
      assert_not inactive_survey.active?
    end

    test "should generate UUID on creation" do
      survey = Survey.create!(title: "Test Survey", survey_template: @template)
      assert_not_nil survey.uuid
      assert survey.uuid.length > 0
    end

    test "should use UUID for URL parameter" do
      survey = Survey.create!(title: "Test Survey", survey_template: @template)
      assert_equal survey.uuid, survey.to_param
    end

    test "should count questions through template" do
      survey = Survey.create!(title: "Test Survey", survey_template: @template)
      assert_equal 0, survey.questions_count
      
      question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      @template.questions.create!(
        question_type: question_type, 
        title: "Test Question", 
        order_position: 1,
        is_required: false,
        allow_other: false,
        randomize_options: false
      )
      
      # Reload to get fresh count
      survey.reload
      assert_equal 1, survey.questions_count
    end

    test "should count participants" do
      survey = Survey.create!(title: "Test Survey", survey_template: @template)
      assert_equal 0, survey.participants_count
      
      survey.participants.create!(email: "test@example.com")
      assert_equal 1, survey.participants_count
    end

    test "should count responses" do
      survey = Survey.create!(title: "Test Survey", survey_template: @template)
      participant = survey.participants.create!(email: "test@example.com")
      
      assert_equal 0, survey.responses_count
      
      survey.responses.create!(participant: participant)
      assert_equal 1, survey.responses_count
    end

    test "should determine if can receive responses" do
      active_survey = Survey.create!(title: "Active Survey", survey_template: @template, is_active: true)
      inactive_survey = Survey.create!(title: "Inactive Survey", survey_template: @template, is_active: false)
      
      assert active_survey.can_receive_responses?
      assert_not inactive_survey.can_receive_responses?
    end

    # Polymorphic association tests
    test "should support polymorphic surveyable association" do
      # This would normally use an actual model, but for testing we'll just check the association structure
      association = Survey.reflect_on_association(:surveyable)
      assert_equal :belongs_to, association.macro
      assert association.options[:polymorphic]
      assert association.options[:optional]
    end
  end
end