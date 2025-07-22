require "test_helper"

module SurveyEngine
  class SurveyTest < ActiveSupport::TestCase
    # Validations
    test "should require title" do
      survey = Survey.new
      assert_not survey.valid?
      assert_includes survey.errors[:title], "can't be blank"
    end

    test "should limit title length" do
      survey = Survey.new(title: "a" * 256)
      assert_not survey.valid?
      assert_includes survey.errors[:title], "is too long (maximum is 255 characters)"
    end

    test "should limit description length" do
      survey = Survey.new(title: "Valid Title", description: "a" * 2001)
      assert_not survey.valid?
      assert_includes survey.errors[:description], "is too long (maximum is 2000 characters)"
    end

    test "should require status" do
      survey = Survey.new(title: "Test")
      survey.status = nil
      assert_not survey.valid?
      assert_includes survey.errors[:status], "can't be blank"
    end

    test "should require valid status" do
      survey = Survey.new(title: "Test")
      assert_raises(ArgumentError) do
        survey.status = "invalid_status"
      end
    end

    test "should accept valid status values" do
      %w[draft published paused archived].each do |status|
        survey = Survey.new(title: "Test", status: status)
        assert survey.valid?, "Should accept status: #{status}"
      end
    end

    test "should require is_active boolean" do
      survey = Survey.new(title: "Test")
      survey.is_active = nil
      assert_not survey.valid?
      assert_includes survey.errors[:is_active], "is not included in the list"
    end

    test "should require global boolean" do
      survey = Survey.new(title: "Test")
      survey.global = nil
      assert_not survey.valid?
      assert_includes survey.errors[:global], "is not included in the list"
    end

    test "should validate published_at before expires_at" do
      survey = Survey.new(
        title: "Test",
        published_at: 1.day.from_now,
        expires_at: 1.hour.from_now
      )
      assert_not survey.valid?
      assert_includes survey.errors[:expires_at], "must be after publication date"
    end

    test "should accept valid date order" do
      survey = Survey.new(
        title: "Test",
        published_at: 1.hour.from_now,
        expires_at: 1.day.from_now
      )
      assert survey.valid?
    end

    # Associations
    test "should have many questions" do
      association = Survey.reflect_on_association(:questions)
      assert_equal :has_many, association.macro
      assert_equal :destroy, association.options[:dependent]
    end

    # test "should have many participants" do
    #   association = Survey.reflect_on_association(:participants)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # test "should have many responses" do
    #   association = Survey.reflect_on_association(:responses)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    # test "should have many settings" do
    #   association = Survey.reflect_on_association(:settings)
    #   assert_equal :has_many, association.macro
    #   assert_equal :destroy, association.options[:dependent]
    # end

    test "should destroy dependent questions" do
      survey = Survey.create!(title: "Test Survey #{SecureRandom.hex(4)}")
      question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      question = survey.questions.create!(question_type: question_type, title: "Test Question", order_position: 1)
      
      assert_difference('Question.count', -1) do
        survey.destroy!
      end
    end

    # Default values
    test "should have default values" do
      survey = Survey.new(title: "Test")
      assert_equal false, survey.is_active
      assert_equal false, survey.global
      assert_equal "draft", survey.status
    end
  end
end