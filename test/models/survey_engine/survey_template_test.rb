require "test_helper"

module SurveyEngine
  class SurveyTemplateTest < ActiveSupport::TestCase
    def setup
      @template = SurveyTemplate.new(name: "Test Template")
    end

    test "should be valid with valid attributes" do
      assert @template.valid?
    end

    test "should require name" do
      @template.name = nil
      assert_invalid @template
      assert_validation_error @template, :name
    end

    test "should have many questions" do
      assert_respond_to @template, :questions
    end

    test "should have many surveys" do
      assert_respond_to @template, :surveys
    end

    test "should have many options through questions" do
      assert_respond_to @template, :options
    end

    test "active scope should return active templates" do
      active_template = SurveyTemplate.create!(name: "Active Template", is_active: true)
      inactive_template = SurveyTemplate.create!(name: "Inactive Template", is_active: false)
      
      active_templates = SurveyTemplate.active
      assert_includes active_templates, active_template
      assert_not_includes active_templates, inactive_template
    end

    test "ordered scope should sort by name" do
      template_b = SurveyTemplate.create!(name: "ZZZ B Template")
      template_a = SurveyTemplate.create!(name: "ZZZ A Template") 
      template_c = SurveyTemplate.create!(name: "ZZZ C Template")
      
      # Filter to only our test templates
      ordered_templates = SurveyTemplate.where("name LIKE 'ZZZ%'").ordered
      assert_equal [template_a, template_b, template_c], ordered_templates.to_a
    end

    test "questions_count should return number of questions" do
      @template.save!
      assert_equal 0, @template.questions_count
      
      question_type = QuestionType.create!(name: "text_#{SecureRandom.hex(4)}", allows_options: false, allows_multiple_selections: false)
      @template.questions.create!(
        question_type: question_type, 
        title: "Test Question", 
        order_position: 1,
        is_required: false,
        allow_other: false,
        randomize_options: false
      )
      
      assert_equal 1, @template.questions_count
    end

    test "surveys_count should return number of surveys" do
      @template.save!
      assert_equal 0, @template.surveys_count
      
      @template.surveys.create!(title: "Test Survey")
      
      assert_equal 1, @template.surveys_count
    end

    test "can_be_deleted? should return true when no surveys exist" do
      @template.save!
      assert @template.can_be_deleted?
    end

    test "can_be_deleted? should return false when surveys exist" do
      @template.save!
      @template.surveys.create!(title: "Test Survey")
      
      assert_not @template.can_be_deleted?
    end

    test "should restrict deletion when surveys exist" do
      @template.save!
      @template.surveys.create!(title: "Test Survey")
      
      assert_raises(ActiveRecord::DeleteRestrictionError) do
        @template.destroy!
      end
    end

    test "should allow deletion when no surveys exist" do  
      @template.save!
      
      assert_nothing_raised do
        @template.destroy!
      end
    end
  end
end