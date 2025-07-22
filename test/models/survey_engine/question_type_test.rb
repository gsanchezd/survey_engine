require "test_helper"

module SurveyEngine
  class QuestionTypeTest < ActiveSupport::TestCase
    # Validations
    test "should require name" do
      question_type = QuestionType.new
      assert_not question_type.valid?
      assert_includes question_type.errors[:name], "can't be blank"
    end

    test "should require unique name" do
      QuestionType.create!(name: "unique_test_type", allows_options: false, allows_multiple_selections: false)
      duplicate = QuestionType.new(name: "unique_test_type", allows_options: false, allows_multiple_selections: false)
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:name], "has already been taken"
    end

    test "should require allows_options" do
      question_type = QuestionType.new(name: "test_options", allows_options: nil)
      assert_not question_type.valid?
      assert_includes question_type.errors[:allows_options], "is not included in the list"
    end

    test "should require allows_multiple_selections" do
      question_type = QuestionType.new(name: "test_multiple", allows_multiple_selections: nil)
      assert_not question_type.valid?
      assert_includes question_type.errors[:allows_multiple_selections], "is not included in the list"
    end

    test "should accept valid boolean values" do
      question_type = QuestionType.new(
        name: "valid_type",
        allows_options: true,
        allows_multiple_selections: false
      )
      assert question_type.valid?
    end

    # Associations
    test "should have many questions" do
      question_type = QuestionType.reflect_on_association(:questions)
      assert_equal :has_many, question_type.macro
    end

    test "should restrict deletion when questions exist" do
      qt = QuestionType.create!(name: "restricted_type", allows_options: false, allows_multiple_selections: false)
      survey = Survey.create!(title: "Test Survey For Restriction")
      survey.questions.create!(question_type: qt, title: "Test Question", order_position: 1)
      
      assert_raises(ActiveRecord::DeleteRestrictionError) do
        qt.destroy!
      end
    end

    test "should allow deletion when no questions exist" do
      qt = QuestionType.create!(name: "unused_type", allows_options: false, allows_multiple_selections: false)
      assert_nothing_raised do
        qt.destroy!
      end
    end
  end
end